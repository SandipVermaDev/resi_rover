import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSecurityScreen extends StatefulWidget {
  final DocumentSnapshot securityData;

  const EditSecurityScreen({super.key, required this.securityData});

  @override
  _EditSecurityScreenState createState() => _EditSecurityScreenState();
}

class _EditSecurityScreenState extends State<EditSecurityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _securityDobController = TextEditingController();
  final TextEditingController _securityAgeController = TextEditingController();
  String? _selectedGender;
  File? _image;

  bool _isLoading = false;

  final Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();

    var data = widget.securityData.data() as Map<String, dynamic>;

    _nameController.text = data['name'] ?? '';
    _contactNumberController.text = data['phone'] ?? '';
    _securityDobController.text = data['dob'] ?? '';
    _securityAgeController.text = data['age'] ?? '';
    _selectedGender = data['gender'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: gold,
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? _buildProfileImage(widget.securityData['profileImageURL'])
                    : null,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Name'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _contactNumberController,
              decoration: _inputDecoration('Contact Number'),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
            ),
            const SizedBox(height: 16.0),
            GestureDetector(
              onTap: () async {
                DateTime? picked = await showDatePicker(
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

                if (picked != null) {
                  setState(() {
                    _securityDobController.text =
                        "${picked.year}-${picked.month}-${picked.day}";
                    // Update the call to calculateAge
                    _securityAgeController.text = calculateAge(picked);
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _securityDobController,
                  decoration: _inputDecoration('Date of Birth'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the date of birth';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _securityAgeController,
              decoration: _inputDecoration('Age'),
              readOnly: true,
            ),
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedGender,
              onChanged: (String? value) {
                setState(() {
                  _selectedGender = value;
                });
              },
              decoration: _inputDecoration('Gender'),
              dropdownColor: gold,
              borderRadius: BorderRadius.circular(20),
              items: ['Male', 'Female', 'Other']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child:
                      Text(value, style: const TextStyle(color: Colors.black)),
                );
              }).toList(),
            ),
            const SizedBox(height: 50.0),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      // Save changes to Firebase
                      await _saveChanges();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Changes saved successfully!'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      setState(() {
                        _isLoading = false;
                      });
                      Navigator.of(context).pop(); // Close the dialog
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text('Save Changes', style: TextStyle(color: gold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? profileImageURL) {
    return profileImageURL != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.network(
              profileImageURL,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          )
        : const Icon(
            Icons.person,
            size: 50,
            color: Colors.black,
          );
  }

  Future<void> _saveChanges() async {
    var data = widget.securityData.data() as Map<String, dynamic>;

    String userId = widget.securityData.id;

    if (_image != null) {
      if (data['profileImageURL'] != null) {
        firebase_storage.Reference oldImageReference = firebase_storage
            .FirebaseStorage.instance
            .refFromURL(data['profileImageURL']);
        await oldImageReference.delete();
      }

      // Upload new image to Firebase Storage
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      firebase_storage.Reference storageReference = firebase_storage
          .FirebaseStorage.instance
          .ref()
          .child("security_profile")
          .child(fileName);

      await storageReference.putFile(_image!);

      String downloadURL = await storageReference.getDownloadURL();

      // Update image URL in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profileImageURL': downloadURL,
      });
    }

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'name': _nameController.text,
      'phone': _contactNumberController.text,
      'dob': _securityDobController.text,
      'age': _securityAgeController.text,
      'gender': _selectedGender,
    });
  }

  String calculateAge(DateTime dob) {
    final today = DateTime.now();
    int age = today.year -
        dob.year -
        ((today.month > dob.month ||
                (today.month == dob.month && today.day >= dob.day))
            ? 0
            : 1);
    return age.toString();
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

  InputDecoration _inputDecoration(String labelText) {
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

  @override
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    _securityDobController.dispose();
    _securityAgeController.dispose();
    super.dispose();
  }
}
