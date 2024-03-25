import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddNoticePage extends StatefulWidget {
  const AddNoticePage({super.key});

  @override
  _AddNoticePageState createState() => _AddNoticePageState();
}

class _AddNoticePageState extends State<AddNoticePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final Color gold = const Color(0xFFD7B504);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Notice', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: Container(
        color: Colors.grey.shade400,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Title'),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: _inputDecoration('Description'),
              ),
              const SizedBox(height: 100),
              ElevatedButton(
                onPressed: () async {
                  String title = _titleController.text.trim();
                  String description = _descriptionController.text.trim();

                  String documentName = '${title}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

                  await FirebaseFirestore.instance.collection('notices').doc(documentName).set({
                    'title': title,
                    'description': description,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notice added successfully!'),
                      duration: Duration(seconds: 3),
                    ),
                  );

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Text('Save Notice',style: TextStyle(fontSize: 18,color: gold),),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}