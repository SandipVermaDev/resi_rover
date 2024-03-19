import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;

import 'user_homepage.dart';

class UserForm extends StatefulWidget {
  const UserForm({super.key});

  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController wingController = TextEditingController();
  TextEditingController flatController = TextEditingController();
  DateTime? selectedDate;
  TextEditingController dobController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  File? _image;

  Color gold = const Color(0xFFD7B504);

  bool _isSubmitting = false;

  InputDecoration textFieldDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: gold),
      filled: true,
      fillColor: Colors.black,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: gold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Text(
              'Submit the form to continue.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: gold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'We will not share your information with anyone.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: gold,
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.black,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: textFieldDecoration('Name'),
              style: TextStyle(color: gold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneNumberController,
              decoration: textFieldDecoration('Phone Number'),
              style: TextStyle(color: gold),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: wingController,
                    decoration: textFieldDecoration('Wing'),
                    style: TextStyle(color: gold),
                  ),
                ),
                const SizedBox(width: 10), // Adjust the spacing as needed
                Expanded(
                  child: TextField(
                    controller: flatController,
                    decoration: textFieldDecoration('Flat'),
                    style: TextStyle(color: gold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                _selectDate(context);
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: dobController,
                  decoration: textFieldDecoration('Date of Birth'),
                  style: TextStyle(color: gold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value:
                  genderController.text.isEmpty ? null : genderController.text,
              items: [
                DropdownMenuItem<String>(
                  value: 'Male',
                  child: Text('Male', style: TextStyle(color: gold)),
                ),
                DropdownMenuItem<String>(
                  value: 'Female',
                  child: Text('Female', style: TextStyle(color: gold)),
                ),
                DropdownMenuItem<String>(
                  value: 'Other',
                  child: Text('Other', style: TextStyle(color: gold)),
                ),
              ],
              dropdownColor: Colors.black87,
              onChanged: (String? newValue) {
                setState(() {
                  genderController.text = newValue ?? '';
                });
              },
              decoration: textFieldDecoration('Gender'),
              style: TextStyle(color: gold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ageController,
              decoration: textFieldDecoration('Age'),
              style: TextStyle(color: gold),
              readOnly: true,
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                if (_validateForm()) {
                  calculateAge();
                  sendUserDataToDB();
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: _isSubmitting ? Colors.grey : gold,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      color: _isSubmitting ? Colors.black : Colors.black,
                    ),
                  ),
                  if (_isSubmitting)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(gold),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 150,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
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

  bool _validateForm() {
    if (nameController.text.isEmpty) {
      showValidationSnackBar('Please enter your name');
      return false;
    }

    if (phoneNumberController.text.isEmpty ||
        phoneNumberController.text.length != 10) {
      showValidationSnackBar('Please enter a valid 10-digit phone number');
      return false;
    }

    if (dobController.text.isEmpty) {
      showValidationSnackBar('Please select your date of birth');
      return false;
    }

    if (flatController.text.isEmpty) {
      showValidationSnackBar('Please enter flat');
      return false;
    }

    if (wingController.text.isEmpty) {
      showValidationSnackBar('Please enter wing');
      return false;
    }

    if (genderController.text.isEmpty) {
      showValidationSnackBar('Please select your gender');
      return false;
    }

    return true;
  }

  void showValidationSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> sendUserDataToDB() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      var currentUser = auth.currentUser;

      CollectionReference collectionRef =
          FirebaseFirestore.instance.collection("users");

      if (_image != null) {
        String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
        firebase_storage.Reference storageReference = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child("profile_images")
            .child(fileName);

        await storageReference.putFile(_image!);

        String downloadURL = await storageReference.getDownloadURL();

        await collectionRef.doc(currentUser!.email).set({
          "name": nameController.text,
          "phone": phoneNumberController.text,
          "wing": wingController.text,
          "flat": flatController.text,
          "dob": dobController.text,
          "gender": genderController.text,
          "age": ageController.text,
          "profileImageURL": downloadURL,
          "userType": "user",
          "email": currentUser.email,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserHomePage()),
        );
      } else {
        showValidationSnackBar('Please select a profile image');
      }

      setState(() {
        _isSubmitting = false;
      });
    } catch (error) {}
  }
}
