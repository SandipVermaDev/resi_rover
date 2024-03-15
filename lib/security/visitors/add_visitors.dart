import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class AddVisitorPage extends StatefulWidget {
  const AddVisitorPage({super.key});

  @override
  _AddVisitorPageState createState() => _AddVisitorPageState();
}

class _AddVisitorPageState extends State<AddVisitorPage> {
  Color gold = const Color(0xFFD7B504);
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController wingController = TextEditingController();
  TextEditingController flatController = TextEditingController();
  TextEditingController purposeController = TextEditingController();
  File? _image;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Visitor',
          style: TextStyle(color: gold),
        ),
        iconTheme: IconThemeData(color: gold),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: gold,
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.black,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: nameController,
              decoration: _inputDecoration('Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              decoration: _inputDecoration('Phone'),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                if (value.length != 10) {
                  return 'Phone number must be 10 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: wingController,
                    decoration: _inputDecoration('Wing'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: flatController,
                    decoration: _inputDecoration('Flat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: purposeController,
              decoration: _inputDecoration('Purpose'),
            ),
            const SizedBox(height: 100),
            _isUploading
                ? CircularProgressIndicator(
                    color: gold,
                  )
                : ElevatedButton.icon(
                    onPressed: () async {
                      setState(() {
                        _isUploading = true;
                      });
                      await _addVisitor();
                      setState(() {
                        _isUploading = false;
                      });
                    },
                    icon: const Icon(Icons.input),
                    label: const Text('Check In'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 40),
                      foregroundColor: Colors.black,
                      backgroundColor: gold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
          ],
        ),
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

  Future<void> _addVisitor() async {
    try {
      String imageUrl = await _uploadImageToStorage();

      await FirebaseFirestore.instance.collection('visitors').add({
        'profileImageURL': imageUrl,
        'name': nameController.text,
        'phone': phoneController.text,
        'wing': wingController.text,
        'flat': flatController.text,
        'purpose': purposeController.text,
        'status': 'check in',
        'checkInTime': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visitor Checked In')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      print('Error adding visitor: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to check in visitor')),
      );
    }
  }

  Future<String> _uploadImageToStorage() async {
    try {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('visitor_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(_image!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (error) {
      print('Error uploading image: $error');
      throw error;
    }
  }
}
