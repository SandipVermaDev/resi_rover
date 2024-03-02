import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditNoticeDialog extends StatefulWidget {
  final String noticeId;

  const EditNoticeDialog({required this.noticeId});

  @override
  _EditNoticeDialogState createState() => _EditNoticeDialogState();
}

class _EditNoticeDialogState extends State<EditNoticeDialog> {
  final Color gold = const Color(0xFFD7B504);
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    titleController = TextEditingController();
    descriptionController = TextEditingController();

    // Fetch notice details when the dialog is created
    _fetchNoticeDetails();
  }

  // Function to fetch notice details from Firebase
  void _fetchNoticeDetails() async {
    try {
      var noticeSnapshot =
      await FirebaseFirestore.instance.collection('notices').doc(widget.noticeId).get();

      if (noticeSnapshot.exists) {
        var noticeData = noticeSnapshot.data() as Map<String, dynamic>;
        var title = noticeData['title'];
        var description = noticeData['description'];

        // Set the fetched values to the controllers
        titleController.text = title ?? '';
        descriptionController.text = description ?? '';
      }
    } catch (e) {
      print('Error fetching notice details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black54,
      title: Text('Edit Notice', style: TextStyle(color: gold)),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: titleController,
              style: TextStyle(color: gold),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: gold,fontSize: 20),
              ),
            ),
            TextFormField(
              controller: descriptionController,
              maxLines: 5,
              style: TextStyle(color: gold),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: gold,fontSize: 20),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog
          },
          child: Text('Cancel', style: TextStyle(color: gold)),
        ),
        TextButton(
          onPressed: () {
            // Implement logic to save changes for notices
            _saveChanges();
            Navigator.pop(context); // Close the dialog after saving changes
          },
          child: Text('Save', style: TextStyle(color: gold)),
        ),
      ],
    );
  }

  // Function to save changes to the notice
  void _saveChanges() async {
    if (!mounted) {
      return;
    }
    try {

      await FirebaseFirestore.instance.collection('notices').doc(widget.noticeId).update({
        'title': titleController.text,
        'description': descriptionController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notice updated successfully!'),
          duration: Duration(seconds: 3),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notice updated successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating notice: $e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
