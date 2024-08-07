import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;

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
  DateTime? selectedDate;
  TextEditingController dobController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  String? _profileImageURL;

  Color gold = const Color(0xFFD7B504);
  bool _updatingProfile = false;

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
      backgroundColor: Colors.grey.shade400,
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
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
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? _buildProfileImage(_profileImageURL)
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
              items: const [
                DropdownMenuItem<String>(
                  value: 'Male',
                  child: Text('Male', style: TextStyle(color: Colors.black)),
                ),
                DropdownMenuItem<String>(
                  value: 'Female',
                  child: Text('Female', style: TextStyle(color: Colors.black)),
                ),
                DropdownMenuItem<String>(
                  value: 'Other',
                  child: Text('Other', style: TextStyle(color: Colors.black)),
                ),
              ],
              dropdownColor: gold,
              borderRadius: BorderRadius.circular(20),
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
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: _updatingProfile
          ? const CircularProgressIndicator() // Show progress indicator when updating
          : FloatingActionButton.extended(
              onPressed: _updateUserProfile,
              backgroundColor: gold,
              icon: const Icon(Icons.update),
              label: const Text('Update'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildProfileImage(String? profileImageURL) {
    return profileImageURL != null
        ? CircleAvatar(
            radius: 78,
            backgroundColor: gold,
            backgroundImage: CachedNetworkImageProvider(profileImageURL),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
            ),
          )
        : CircleAvatar(
            radius: 79,
            backgroundColor: gold,
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.black,
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
                title: const Text('Take a Photo',
                    style: TextStyle(color: Colors.black)),
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
      final compressedImage = await _compressImage(File(pickedImage.path));

      setState(() {
        _image = compressedImage;
      });
    }
  }

  Future<File> _compressImage(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    img.Image image = img.decodeImage(Uint8List.fromList(imageBytes))!;

    File compressedImageFile =
        File(imageFile.path.replaceAll('.jpg', '_compressed.jpg'));
    await compressedImageFile.writeAsBytes(img.encodeJpg(image, quality: 40));

    return compressedImageFile;
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
    setState(() {
      _updatingProfile = true;
    });

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
        "dob": dobController.text,
        "gender": genderController.text,
        "age": ageController.text,
      });

      setState(() {
        _updatingProfile = false;
      });
      Navigator.of(context).pop();
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
