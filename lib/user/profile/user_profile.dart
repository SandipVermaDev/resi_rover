import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:resi_rover/user/profile/edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late User? _currentUser;
  late Map<String, dynamic> _userData = {};
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
        setState(() {
          _userData = userSnapshot.data() as Map<String, dynamic>;
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
        title: Text('Profile', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfilePage()),
              );
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            CircleAvatar(
              radius: 80,
              backgroundImage: NetworkImage(_userData['profileImageURL'] ?? ''),
            ),
            const SizedBox(height: 40),
            _buildDetailRow('Name', _userData['name'] ?? ''),
            _buildDetailRow('Wing', _userData['wing'] ?? ''),
            _buildDetailRow('Flat', _userData['flat'] ?? ''),
            _buildDetailRow('Email', _currentUser?.email ?? ''),
            _buildDetailRow('Phone', _userData['phone'] ?? ''),
            _buildDetailRow('DOB', _userData['dob'] ?? ''),
            _buildDetailRow('Age', _userData['age'] ?? ''),
            _buildDetailRow('Gender', _userData['gender'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
