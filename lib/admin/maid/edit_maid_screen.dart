import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:image/image.dart' as img;

class EditMaidScreen extends StatefulWidget {
  final DocumentSnapshot maidData;

  const EditMaidScreen({super.key, required this.maidData});

  @override
  _EditMaidScreenState createState() => _EditMaidScreenState();
}

class _EditMaidScreenState extends State<EditMaidScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _maidDobController = TextEditingController();
  final TextEditingController _maidAgeController = TextEditingController();
  String? _selectedGender;
  File? _image;

  bool _isLoading = false;

  final Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    var data = widget.maidData.data() as Map<String, dynamic>;

    _nameController.text = data['name'] ?? '';
    _contactNumberController.text = data['contactNumber'] ?? '';
    _maidDobController.text = data['dob'] ?? '';
    _maidAgeController.text = data['age'] ?? '';
    _selectedGender = data['gender'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: gold,
              backgroundImage: _image != null ? FileImage(_image!) : null,
              child: _image == null
                  ? _buildProfileImage(widget.maidData['profileImageURL'])
                  : null,
            ),
          ),
          const SizedBox(height: 20),
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
          DropdownButtonFormField<String>(
            value: _selectedGender,
            onChanged: (String? value) {
              setState(() {
                _selectedGender = value;
              });
            },
            decoration: _inputDecoration('Gender'),
            borderRadius: BorderRadius.circular(20),
            dropdownColor: const Color(0xFFFFB41A),
            items: ['Male', 'Female', 'Other']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(height: 16.0),
          GestureDetector(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate:
                    DateFormat('yyyy-MM-dd').parse(_maidDobController.text),
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

              if (picked != null &&
                  picked != DateTime.parse(_maidDobController.text)) {
                setState(() {
                  _maidDobController.text =
                      DateFormat('yyyy-MM-dd').format(picked);
                  _maidAgeController.text = calculateAge(picked);
                });
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: _maidDobController,
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
            controller: _maidAgeController,
            decoration: _inputDecoration('Age'),
            readOnly: true,
          ),
          const SizedBox(height: 40),
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
                : Text(
                    'Save Changes',
                    style: TextStyle(color: gold),
                  ),
          ),
        ],
      ),
    );
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

  void _pickImage() async {
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

  Widget _buildProfileImage(String? profileImageURL) {
    return profileImageURL != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: CachedNetworkImage(
              imageUrl: profileImageURL,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          )
        : const Icon(
            Icons.person,
            size: 50,
            color: Colors.black,
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

  Future<void> _saveChanges() async {
    var data = widget.maidData.data() as Map<String, dynamic>;

    String maidId = widget.maidData.id;

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
          .child("maid_profile")
          .child(fileName);

      await storageReference.putFile(_image!);

      String downloadURL = await storageReference.getDownloadURL();

      await FirebaseFirestore.instance.collection('maids').doc(maidId).update({
        'profileImageURL': downloadURL,
      });
    }

    await FirebaseFirestore.instance.collection('maids').doc(maidId).update({
      'name': _nameController.text,
      'contactNumber': _contactNumberController.text,
      'dob': _maidDobController.text,
      'age': _maidAgeController.text,
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

  @override
  void dispose() {
    _nameController.dispose();
    _contactNumberController.dispose();
    _maidDobController.dispose();
    _maidAgeController.dispose();
    super.dispose();
  }
}
