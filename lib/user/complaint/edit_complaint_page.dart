import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditComplaintPage extends StatefulWidget {
  final String complaintId;
  final String currentTitle;
  final String currentDetails;

  const EditComplaintPage({
    required this.complaintId,
    required this.currentTitle,
    required this.currentDetails,
    super.key,
  });

  @override
  _EditComplaintPageState createState() => _EditComplaintPageState();
}

class _EditComplaintPageState extends State<EditComplaintPage> {
  late TextEditingController _titleController;
  late TextEditingController _detailsController;
  Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _detailsController = TextEditingController(text: widget.currentDetails);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black54,
      title: Text('Edit Complaint', style: TextStyle(color: gold)),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
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
                _updateComplaint();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Update', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _updateComplaint() async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaintId)
          .update({
        'title': _titleController.text.trim(),
        'details': _detailsController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint updated successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (error) {
      print("Error updating complaint: $error");
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }
}
