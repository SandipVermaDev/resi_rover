import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;

import 'edit_security_screen.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  _SecurityPageState createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _securityDobController = TextEditingController();
  final TextEditingController _securityAgeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _image;
  DateTime? _selectedDate;
  String? _selectedGender;

  bool isPasswordVisible = false;
  bool _isLoading = false;

  final Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _resetAddSecurityFields();
      }
    });
  }

  void _resetAddSecurityFields() {
    _emailController.text = '';
    _nameController.text = '';
    _contactNumberController.text = '';
    _securityDobController.text = '';
    _securityAgeController.text = '';
    _passwordController.text = '';
    _image = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Page', style: TextStyle(color: gold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: gold,
          tabs: const [
            Tab(
              text: 'View All',
              icon: Icon(Icons.people_outline),
            ),
            Tab(
              text: 'Add Security',
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
          _buildAddSecurityTab(),
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
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('userType', isEqualTo: 'security')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD7B504)),
                  strokeWidth: 3.0,
                ),
              );
            }

            var securityDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: securityDocs.length,
              itemBuilder: (context, index) {
                var securityData =
                    securityDocs[index].data() as Map<String, dynamic>;
                var profileImageURL = securityData['profileImageURL'];
                var name = securityData['name'];
                var email = securityData['email'];
                var contactNumber = securityData['phone'];

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
                            Text('Name :$name',
                                style: TextStyle(
                                    color: gold, fontWeight: FontWeight.bold)),
                            Text('Email: $email',
                                style: TextStyle(color: gold)),
                            Text('Ph No: $contactNumber',
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
                              _editSecurity(securityDocs[index]);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: gold,
                            onPressed: () {
                              _deleteSecurity(
                                userId: securityDocs[index].id,
                                profileImageURL:
                                    securityData['profileImageURL'],
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

  void _editSecurity(DocumentSnapshot securityData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: gold,
          title: const Text('Edit Security',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          content: EditSecurityScreen(
            securityData: securityData,
          ),
        );
      },
    );
  }

  void _deleteSecurity(
      {required String userId, required String profileImageURL}) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text('Confirm Deletion',
              style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete this security?',
              style: TextStyle(color: gold)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled
              },
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'userType': 'disabled'});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security deleted successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting security: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildAddSecurityTab() {
    List<String> genderOptions = ['Male', 'Female', 'Other'];

    return SingleChildScrollView(
      child: Container(
        color: Colors.grey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.black)),
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
                      _securityDobController.text =
                          DateFormat('yyyy-MM-dd').format(_selectedDate!);
                      _securityAgeController.text = calculateAge(picked);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _securityDobController,
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
                controller: _securityAgeController,
                decoration: const InputDecoration(
                    labelText: 'Age',
                    labelStyle: TextStyle(color: Colors.black)),
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
              TextField(
                controller: _passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.black),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                        });

                        String email = _emailController.text.trim();
                        String name = _nameController.text.trim();
                        String contactNumber =
                            _contactNumberController.text.trim();
                        String password = _passwordController.text;

                        try {
                          UserCredential userCredential = await FirebaseAuth
                              .instance
                              .createUserWithEmailAndPassword(
                            email: email,
                            password: password,
                          );

                          if (userCredential.user != null) {
                            await FirebaseAuth.instance.signOut();
                            await FirebaseAuth.instance
                                .signInWithEmailAndPassword(
                              email: 'iamadmin@gmail.com',
                              password: 'admin@123',
                            );

                            if (_image != null) {
                              String fileName =
                                  "${DateTime.now().millisecondsSinceEpoch}.jpg";
                              firebase_storage.Reference storageReference =
                                  firebase_storage.FirebaseStorage.instance
                                      .ref()
                                      .child("security_profile")
                                      .child(fileName);

                              await storageReference.putFile(_image!);

                              String downloadURL =
                                  await storageReference.getDownloadURL();

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(email)
                                  .set({
                                'email': email,
                                'name': name,
                                'phone': contactNumber,
                                'userType': 'security',
                                'dob': _securityDobController.text,
                                'age': _securityAgeController.text,
                                'gender': _selectedGender,
                                'profileImageURL': downloadURL,
                              });

                              _resetAddSecurityFields();

                              _tabController.animateTo(0);
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Security added successfully!'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Error adding security. Please try again.'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'email-already-in-use') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'The email address is already in use. Please choose a different one.'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }

                        setState(() {
                          _isLoading = false;
                        });
                      },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                child: _isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(gold),
                        strokeWidth: 3.0,
                      )
                    : Text('Add Security', style: TextStyle(color: gold)),
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

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _contactNumberController.dispose();
    _securityDobController.dispose();
    _securityAgeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
