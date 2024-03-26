import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class AddResidencyPage extends StatefulWidget {
  const AddResidencyPage({super.key});

  @override
  _AddResidencyPageState createState() => _AddResidencyPageState();
}

class _AddResidencyPageState extends State<AddResidencyPage> {
  final Color gold = const Color(0xFFD7B504);
  List<TextEditingController> wingControllers = [TextEditingController()];
  List<List<TextEditingController>> flatControllers = [
    [TextEditingController()]
  ];
  TextEditingController residencyNameController = TextEditingController();

  List<File> images = [];

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade400,
      appBar: AppBar(
        title: Text('Add Residency', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: residencyNameController,
              decoration: textFieldDecoration('Residency Name'),
              style: TextStyle(color: gold),
            ),
            const SizedBox(height: 20),
            const Text('Wing & Flat :-',
                style: TextStyle(color: Colors.black, fontSize: 18)),
            const SizedBox(height: 16.0),
            Column(
              children: [
                for (int i = 0; i < wingControllers.length; i++)
                  _buildWingAndFlatField(
                      i + 1, wingControllers[i], flatControllers[i]),
                const SizedBox(height: 16.0),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _addWingAndFlat,
                  mini: true,
                  backgroundColor: Colors.black,
                  heroTag: 'addWingAndFlatButton',
                  child: Icon(Icons.add, color: gold),
                ),
                if (wingControllers.length > 1)
                  FloatingActionButton(
                    onPressed: () =>
                        _removeWing(wingControllers.last, flatControllers),
                    mini: true,
                    backgroundColor: Colors.red,
                    heroTag: 'removeWingButton',
                    child: const Icon(Icons.remove, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 16.0),
            const SizedBox(height: 20),
            const Text('Images:',
                style: TextStyle(color: Colors.black, fontSize: 18)),
            if (images.isNotEmpty) ...[
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.file(
                            images[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: Icon(Icons.delete, color: gold),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              onPressed: _selectImages,
              label: Text(
                'Add Images',
                style: TextStyle(color: gold),
              ),
              icon: Icon(Icons.add_photo_alternate, color: gold),
              backgroundColor: Colors.black,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      floatingActionButton: _isSubmitting
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(gold),
            )
          : FloatingActionButton.extended(
              onPressed: _saveResidencyDetails,
              label: Text(
                'Save',
                style: TextStyle(color: gold),
              ),
              icon: Icon(Icons.save, color: gold),
              backgroundColor: Colors.black,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildWingAndFlatField(
      int wingNumber,
      TextEditingController wingController,
      List<TextEditingController> flatControllers) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: wingController,
            decoration: textFieldDecoration('Wing $wingNumber'),
            style: TextStyle(color: gold),
          ),
        ),
        const SizedBox(width: 10.0),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              for (int j = 0; j < flatControllers.length; j++)
                Column(
                  children: [
                    TextFormField(
                      controller: flatControllers[j],
                      decoration:
                          textFieldDecoration('Flat $wingNumber-${j + 1}'),
                      style: TextStyle(color: gold),
                    ),
                    const SizedBox(height: 8)
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _addFlat(flatControllers),
                    icon: const Icon(Icons.add, color: Colors.black),
                  ),
                  if (flatControllers.length > 1)
                    IconButton(
                      onPressed: () => _removeFlat(
                          flatControllers, flatControllers.length - 1),
                      icon: const Icon(Icons.remove, color: Colors.red),
                    ),
                ],
              ),
              const SizedBox(height: 10)
            ],
          ),
        ),
      ],
    );
  }

  void _addWingAndFlat() {
    setState(() {
      wingControllers.add(TextEditingController());
      flatControllers.add([TextEditingController()]);
    });
  }

  void _addFlat(List<TextEditingController> flatControllers) {
    setState(() {
      flatControllers.add(TextEditingController());
    });
  }

  void _removeWing(
    TextEditingController wingController,
    List<List<TextEditingController>> flatControllers,
  ) {
    setState(() {
      int index = wingControllers.indexOf(wingController);
      wingControllers.removeAt(index);
      flatControllers.removeAt(index);
    });
  }

  void _removeFlat(List<TextEditingController> flatControllers, int index) {
    setState(() {
      flatControllers.removeAt(index);
    });
  }

  void _removeImage(int index) {
    setState(() {
      images.removeAt(index);
    });
  }

  Future<void> _selectImages() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      for (var pickedFile in pickedFiles) {
        final compressedImage = await _compressImage(File(pickedFile.path));
        setState(() {
          images.add(compressedImage);
        });
      }
    } catch (e) {
      print('Error selecting images: $e');
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

  InputDecoration textFieldDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: gold),
      filled: true,
      fillColor: Colors.black87,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: gold, width: 2),
      ),
    );
  }

  Future<void> _saveResidencyDetails() async {
    // Validate residency name
    if (residencyNameController.text.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Access Firestore instance
      CollectionReference residencyCollection =
          FirebaseFirestore.instance.collection('residencies');

      /// Create a map to store flats for each wing
      Map<String, List<String>> wingsAndFlats = {};
      for (int i = 0; i < wingControllers.length; i++) {
        String wingNumber = wingControllers[i].text;
        List<String> flatNumbers =
            flatControllers[i].map((controller) => controller.text).toList();
        wingsAndFlats[wingNumber] = flatNumbers;
      }

      // Create a new document with a generated ID
      await residencyCollection.doc(residencyNameController.text).set({
        'residencyName': residencyNameController.text,
        'wingsAndFlats': wingsAndFlats,
      });

      // Upload images to Firebase Storage and store download URLs in Firestore
      List<String> imageUrls = await _uploadImages();

      // Update the document with image URLs
      await residencyCollection.doc(residencyNameController.text).update({
        'images': imageUrls,
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Residency details saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving residency details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Error saving residency details. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    try {
      for (File imageFile in images) {
        String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final firebase_storage.Reference ref = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child('resi_images')
            .child(fileName);
        final firebase_storage.UploadTask uploadTask = ref.putFile(imageFile);
        await uploadTask;
        final String downloadURL = await ref.getDownloadURL();
        imageUrls.add(downloadURL);
      }
    } catch (e) {
      print('Error uploading images: $e');
    }
    return imageUrls;
  }
}
