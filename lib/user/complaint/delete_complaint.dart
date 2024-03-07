import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeleteConfirmationDialog extends StatefulWidget {
  final String complaintId;

  const DeleteConfirmationDialog({super.key, required this.complaintId});

  @override
  State<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  Color gold = const Color(0xFFD7B504);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: gold,
      title: const Text('Delete Confirmation',style: TextStyle(color: Colors.black)),
      content: const Text('Are you sure you want to delete this complaint?',style: TextStyle(color: Colors.black)),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel',style: TextStyle(color: Colors.black)),
        ),
        TextButton(
          onPressed: () {
            _deleteComplaint(widget.complaintId);
            Navigator.pop(context);
          },
          child: const Text('Delete',style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  Future<void> _deleteComplaint(String complaintId) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .delete();
      print('Complaint deleted successfully.');
    } catch (error) {
      print('Error deleting complaint: $error');
    }
  }
}
