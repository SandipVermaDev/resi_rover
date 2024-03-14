import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:resi_rover/user/profile/user_profile.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late User? _currentUser;
  File? _image;

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController wingController = TextEditingController();
  TextEditingController flatController = TextEditingController();
  DateTime? selectedDate;
  TextEditingController dobController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  String? _profileImageURL;

  Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      try {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.email)
            .get();
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _profileImageURL = userData['profileImageURL'];
          nameController.text = userData['name'] ?? '';
          phoneNumberController.text = userData['phone'] ?? '';
          wingController.text = userData['wing'] ?? '';
          flatController.text = userData['flat'] ?? '';
          dobController.text = userData['dob'] ?? '';
          genderController.text = userData['gender'] ?? '';
          ageController.text = userData['age'] ?? '';
        });
      } catch (error) {
        print('Error fetching user data: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
        actions: [
          IconButton(
            onPressed: _updateUserProfile,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: gold,
                backgroundImage: NetworkImage(_profileImageURL ?? ''),
                child: _image == null && _profileImageURL == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.black,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 50),
            TextField(
              controller: nameController,
              decoration: textFieldDecoration('Name'),
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneNumberController,
              decoration: textFieldDecoration('Phone Number'),
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: wingController,
                    decoration: textFieldDecoration('Wing'),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: flatController,
                    decoration: textFieldDecoration('Flat'),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                _selectDate(context);
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: dobController,
                  decoration: textFieldDecoration('Date of Birth'),
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value:
                  genderController.text.isEmpty ? null : genderController.text,
              items: [
                const DropdownMenuItem<String>(
                  value: 'Male',
                  child: Text('Male', style: TextStyle(color: Colors.black)),
                ),
                const DropdownMenuItem<String>(
                  value: 'Female',
                  child: Text('Female', style: TextStyle(color: Colors.black)),
                ),
                const DropdownMenuItem<String>(
                  value: 'Other',
                  child: Text('Other', style: TextStyle(color: Colors.black)),
                ),
              ],
              dropdownColor: gold,
              onChanged: (String? newValue) {
                setState(() {
                  genderController.text = newValue ?? '';
                });
              },
              decoration: textFieldDecoration('Gender'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ageController,
              decoration: textFieldDecoration('Age'),
              style: const TextStyle(color: Colors.black),
              readOnly: true,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  InputDecoration textFieldDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.black),
      filled: true,
      fillColor: Colors.black26,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: const BorderSide(color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: gold),
      ),
    );
  }

  Future<void> _pickImage() async {
    await showModalBottomSheet(
      backgroundColor: gold,
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 150,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery',
                    style: TextStyle(color: Colors.black)),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title:
                    const Text('Take a Photo', style: TextStyle(color: Colors.black)),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: Colors.black,
            colorScheme: ColorScheme.dark(
              primary: gold,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: gold,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        dobController.text = DateFormat('yyyy-MM-dd').format(selectedDate!);
        calculateAge();
      });
    }
  }

  void calculateAge() {
    if (selectedDate != null) {
      DateTime currentDate = DateTime.now();
      int age = currentDate.year - selectedDate!.year;

      if (currentDate.month < selectedDate!.month ||
          (currentDate.month == selectedDate!.month &&
              currentDate.day < selectedDate!.day)) {
        age--;
      }

      ageController.text = age.toString();
    }
  }

  Future<void> _updateUserProfile() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    var currentUser = auth.currentUser;

    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection("users");

    try {
      // Delete old image from Firebase Storage if it exists
      if (_image != null) {
        // Get the old image URL from Firestore
        String? oldImageUrl = _profileImageURL;

        // If there is an old image, delete it from Firebase Storage
        if (oldImageUrl != null) {
          firebase_storage.Reference oldImageReference =
              firebase_storage.FirebaseStorage.instance.refFromURL(oldImageUrl);
          await oldImageReference.delete();
        }
      }

      // Upload new image to Firebase Storage if _image is not null
      String? imageUrl;
      if (_image != null) {
        // Generate a unique file name for the new image
        String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";

        // Get reference to the Firebase Storage bucket
        final firebase_storage.Reference storageRef = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child(fileName);


        // Upload image to Firebase Storage
        final firebase_storage.UploadTask uploadTask =
            storageRef.putFile(_image!);

        // Get download URL of the uploaded image
        final firebase_storage.TaskSnapshot downloadSnapshot = await uploadTask;
        imageUrl = await downloadSnapshot.ref.getDownloadURL();
      }

      await collectionRef.doc(currentUser!.email).update({
        "profileImageURL": imageUrl ?? _profileImageURL,
        "name": nameController.text,
        "phone": phoneNumberController.text,
        "wing": wingController.text,
        "flat": flatController.text,
        "dob": dobController.text,
        "gender": genderController.text,
        "age": ageController.text,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    } catch (error) {
      print('Error updating profile: $error');
      showSnackBar('Failed to update profile');
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}
