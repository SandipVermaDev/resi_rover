import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'edit_maid_screen.dart';

class MaidPage extends StatefulWidget {
  const MaidPage({super.key});

  @override
  _MaidPageState createState() => _MaidPageState();
}

class _MaidPageState extends State<MaidPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _maidDobController = TextEditingController();
  final TextEditingController _maidAgeController = TextEditingController();
  File? _image;
  DateTime? _selectedDate;
  String? _selectedGender;

  bool _isLoading = false;

  final Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _resetAddMaidFields();
      }
    });
  }

  void _resetAddMaidFields() {
    _nameController.text = '';
    _contactNumberController.text = '';
    _maidDobController.text = '';
    _maidAgeController.text = '';
    _image = null;
    _selectedGender = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maid Page', style: TextStyle(color: gold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: gold,
          tabs: const [
            Tab(
              text: 'View All',
              icon: Icon(Icons.people_outline),
            ),
            Tab(
              text: 'Add Maid',
              icon: Icon(Icons.person_add_alt),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildViewAllTab(),
          _buildAddMaidTab(),
        ],
      ),
    );
  }

  Widget _buildViewAllTab() {
    return Container(
      color: Colors.grey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('maids').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            var maidDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: maidDocs.length,
              itemBuilder: (context, index) {
                var maidData = maidDocs[index].data() as Map<String, dynamic>;
                var profileImageURL = maidData['profileImageURL'];
                var name = maidData['name'];
                var contactNumber = maidData['contactNumber'];
                var dob = maidData['dob'];
                var age = maidData['age'];
                var gender = maidData['gender'];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: profileImageURL != null
                            ? NetworkImage(profileImageURL)
                            : null,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name: $name',
                                style: TextStyle(
                                    color: gold, fontWeight: FontWeight.bold)),
                            Text('Phone : $contactNumber',
                                style: TextStyle(color: gold)),
                            Text('Date of Birth: $dob',
                                style: TextStyle(color: gold)),
                            Text('Age: $age', style: TextStyle(color: gold)),
                            Text('Gender: $gender',
                                style: TextStyle(color: gold)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: gold,
                            onPressed: () {
                              _editMaid(maidDocs[index]);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: gold,
                            onPressed: () {
                              _deleteMaid(
                                maidId: maidDocs[index].id,
                                profileImageURL: maidData['profileImageURL'],
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _editMaid(DocumentSnapshot maidData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: gold,
          title: const Text('Edit Maid',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: EditMaidScreen(
            maidData: maidData,
          ),
        );
      },
    );
  }

  void _deleteMaid(
      {required String maidId, required String profileImageURL}) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text('Confirm Deletion',
              style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to delete this maid?',
            style: TextStyle(color: gold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed
              },
              child: Text('Yes',
                  style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled
              },
              child: Text('No',
                  style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        if (profileImageURL.isNotEmpty) {
          await firebase_storage.FirebaseStorage.instance
              .refFromURL(profileImageURL)
              .delete();
        }

        await FirebaseFirestore.instance
            .collection('maids')
            .doc(maidId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maid deleted successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting maid: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildAddMaidTab() {
    List<String> genderOptions = ['Male', 'Female', 'Other'];

    return Container(
      color: Colors.grey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 16.0),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.black)),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _contactNumberController,
                decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    labelStyle: TextStyle(color: Colors.black)),
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
                decoration: const InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(color: Colors.black)),
                dropdownColor: gold,
                items:
                    genderOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value,
                        style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
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

                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                      _maidDobController.text =
                          DateFormat('yyyy-MM-dd').format(_selectedDate!);
                      _maidAgeController.text = calculateAge(picked);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _maidDobController,
                    decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        labelStyle: TextStyle(color: Colors.black)),
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
                decoration: const InputDecoration(
                    labelText: 'Age',
                    labelStyle: TextStyle(color: Colors.black)),
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

                        String name = _nameController.text.trim();
                        String contactNumber =
                            _contactNumberController.text.trim();

                        try {
                          if (_image != null) {
                            String fileName =
                                "${DateTime.now().millisecondsSinceEpoch}.jpg";
                            firebase_storage.Reference storageReference =
                                firebase_storage.FirebaseStorage.instance
                                    .ref()
                                    .child("maid_profile")
                                    .child(fileName);

                            await storageReference.putFile(_image!);

                            String downloadURL =
                                await storageReference.getDownloadURL();

                            String documentId = '$name-$contactNumber';

                            bool isDuplicate =
                                await checkDuplicateMaid(contactNumber);

                            if (!isDuplicate) {
                              await FirebaseFirestore.instance
                                  .collection('maids')
                                  .doc(documentId)
                                  .set({
                                'name': name,
                                'contactNumber': contactNumber,
                                'dob': _maidDobController.text,
                                'age': _maidAgeController.text,
                                'gender': _selectedGender,
                                'profileImageURL': downloadURL,
                              });
                              _resetAddMaidFields();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Maid added successfully!'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Duplicate maid. Please enter a different contact number.'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error adding maid: $e'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                        setState(() {
                          _isLoading = false;
                        });

                        _tabController.animateTo(0);
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(gold),
                        strokeWidth: 3.0,
                      )
                    : Text('Add Maid', style: TextStyle(color: gold)),
              ),
            ],
          ),
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
      // Compress the image
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

  Future<bool> checkDuplicateMaid(String contactNumber) async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('maids')
        .where('contactNumber', isEqualTo: contactNumber)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _contactNumberController.dispose();
    _maidDobController.dispose();
    _maidAgeController.dispose();
    super.dispose();
  }
}
