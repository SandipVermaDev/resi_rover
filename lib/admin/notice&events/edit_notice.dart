import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditNoticeDialog extends StatefulWidget {
  final String noticeId;

  const EditNoticeDialog({super.key, required this.noticeId});

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
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    _fetchNoticeDetails();
  }

  void _fetchNoticeDetails() async {
    try {
      var noticeSnapshot =
      await FirebaseFirestore.instance.collection('notices').doc(widget.noticeId).get();

      if (noticeSnapshot.exists) {
        var noticeData = noticeSnapshot.data() as Map<String, dynamic>;
        var title = noticeData['title'];
        var description = noticeData['description'];

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
      backgroundColor: Colors.grey.shade400,
      title: const Text('Edit Notice', style: TextStyle(color: Colors.black)),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextFormField(
              controller: titleController,
              decoration: _inputDecoration('Title'),
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: descriptionController,
              maxLines: 5,
              decoration: _inputDecoration('Description'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey)),
        ),
        TextButton(
          onPressed: () {
            _saveChanges();
            Navigator.pop(context);
          },
          child: Text('Save', style: TextStyle(color: gold,fontWeight: FontWeight.bold)),
        ),
      ],
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
          const SnackBar(
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
