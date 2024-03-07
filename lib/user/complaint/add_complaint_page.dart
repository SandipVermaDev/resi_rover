import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddComplaintPage extends StatefulWidget {
  const AddComplaintPage({super.key});

  @override
  State<AddComplaintPage> createState() => _AddComplaintPageState();
}

class _AddComplaintPageState extends State<AddComplaintPage> {
  Color gold = const Color(0xFFD7B504);
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Complaint', style: TextStyle(color: gold)),
        backgroundColor: Colors.black, // Customize as needed
        iconTheme: IconThemeData(color: gold),
      ),
      body: Container(
        color: Colors.grey,
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Complaint Title',
                  filled: true,
                  fillColor: Colors.black87,
                  labelStyle: TextStyle(color: gold),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(color: Colors.white, width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: gold, width: 2.0),
                  ),
                ),
                style: TextStyle(color: gold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _detailsController,
                decoration: InputDecoration(
                  labelText: 'Complaint Details',
                  filled: true,
                  fillColor: Colors.black87,
                  labelStyle: TextStyle(color: gold),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(color: Colors.white, width: 2.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: gold, width: 2.0),
                  ),
                ),
                style: TextStyle(color: gold),
                maxLines: 5,
              ),
              const SizedBox(height: 100),
              ElevatedButton(
                onPressed: () {
                  _submitComplaint();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text('Submit', style: TextStyle(color: gold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitComplaint() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(currentUser.email).get();

        if (userSnapshot.exists) {
          String userName = userSnapshot['name'];
          String title = _titleController.text.trim();
          String details = _detailsController.text.trim();

          if (title.isNotEmpty && details.isNotEmpty) {
            await FirebaseFirestore.instance.collection('complaints').add({
              'title': title,
              'details': details,
              'timestamp': FieldValue.serverTimestamp(),
              'userEmail': currentUser.email,
              'userName': userName,
              'status': 'Pending',
              'likes': [],
            });

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Complaint submitted successfully!'),
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            print("Title and details cannot be empty.");
          }
        }
      }
    } catch (error) {
      print("Error submitting complaint: $error");
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }
}