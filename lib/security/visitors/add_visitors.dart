import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:resi_rover/security/visitors/visitors_page.dart';

class AddVisitorPage extends StatefulWidget {
  const AddVisitorPage({super.key});

  @override
  _AddVisitorPageState createState() => _AddVisitorPageState();
}

class _AddVisitorPageState extends State<AddVisitorPage> {
  Color gold = const Color(0xFFD7B504);
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController purposeController = TextEditingController();
  File? _image;
  bool _isUploading = false;

  String? selectedWing;
  String? selectedFlat;

  List<String> wings = [];
  Map<String, List<String>> flatsPerWing = {};

  @override
  void initState() {
    super.initState();
    _fetchWingsAndFlats();
  }

  Future<void> _fetchWingsAndFlats() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('residencies').get();
      for (var doc in snapshot.docs) {
        var data = doc.data();

        Map<String, List<dynamic>> wingsAndFlats =
        Map<String, List<dynamic>>.from(data['wingsAndFlats']);

        wingsAndFlats.forEach((wing, flats) {
          wings.add(wing);
          for (var flat in flats) {
            flatsPerWing.putIfAbsent(wing, () => []).add(flat);
          }
        });
      }
      setState(() {});
    } catch (e) {
      print("Error fetching wings and flats: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade400,
      appBar: AppBar(
        title: Text(
          'Add Visitor',
          style: TextStyle(color: gold),
        ),
        iconTheme: IconThemeData(color: gold),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
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
              const SizedBox(height: 50),
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
                    child: DropdownButtonFormField<String>(
                      dropdownColor: gold,
                      borderRadius: BorderRadius.circular(20),
                      value: selectedWing,
                      items: wings.map((wing) {
                        return DropdownMenuItem<String>(
                          value: wing,
                          child: Text(wing, style: const TextStyle(color: Colors.black)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedWing = value;
                        });
                      },
                      decoration: _inputDecoration('Wing'),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 10), // Adjust the spacing as needed
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      dropdownColor: gold,
                      borderRadius: BorderRadius.circular(20),
                      value: selectedFlat,
                      items: flatsPerWing[selectedWing ?? '']?.map((flat) {
                        return DropdownMenuItem<String>(
                          value: flat,
                          child: Text(flat, style: const TextStyle(color: Colors.black)),
                        );
                      }).toList() ?? [],
                      onChanged: (value) {
                        setState(() {
                          selectedFlat = value;
                        });
                      },
                      decoration: _inputDecoration('Flat'),
                      style: const TextStyle(color: Colors.black),
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

      User? user = FirebaseAuth.instance.currentUser;
      String userEmail = user!.email!;

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (userSnapshot.exists) {
        String userName = userSnapshot['name'];

        // Add visitor document
        DocumentReference visitorRef = await FirebaseFirestore.instance.collection('visitors').add({
          'profileImageURL': imageUrl,
          'name': nameController.text,
          'phone': phoneController.text,
          "wing": selectedWing,
          "flat": selectedFlat,
          'purpose': purposeController.text,
          'status': 'check in',
        });

        // Add check_in sub-collection
        await visitorRef.collection('check_in').add({
          'checkInTime': Timestamp.now(),
          'securityEmail': userEmail,
          'securityName': userName,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visitor Checked In')),
        );

        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VisitorsPage()),
        );
        //Navigator.of(context).pop();
      }
    } catch (error) {
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
      rethrow;
    }
  }
}
