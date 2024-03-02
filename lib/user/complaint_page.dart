import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintPage extends StatefulWidget {
  @override
  _ComplaintPageState createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController _complaintController = TextEditingController();
  final CollectionReference _complaintsCollection =
  FirebaseFirestore.instance.collection('complaints');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complaints'),
      ),
      body: Column(
        children: [
          _buildComplaintInput(),
          Expanded(child: _buildComplaintList()),
        ],
      ),
    );
  }

  Widget _buildComplaintInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _complaintController,
              decoration: InputDecoration(
                hintText: 'Enter your complaint...',
              ),
            ),
          ),
          SizedBox(width: 8.0),
          ElevatedButton(
            onPressed: () {
              _addComplaint();
            },
            child: Text('Add Complaint'),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _complaintsCollection.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        var complaints = snapshot.data!.docs;

        return ListView.builder(
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            var complaint = complaints[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(complaint['content']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () {
                      _updateComplaint(complaint, complaints[index].id);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _deleteComplaint(complaints[index].id);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addComplaint() async {
    String complaintText = _complaintController.text.trim();
    if (complaintText.isNotEmpty) {
      await _complaintsCollection.add({
        'content': complaintText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _complaintController.clear();
    }
  }

  void _updateComplaint(Map<String, dynamic> complaint, String complaintId) async {
    String? updatedContent = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Complaint'),
          content: TextField(
            controller: TextEditingController(text: complaint['content']),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_complaintController.text.trim());
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );

    if (updatedContent != null && updatedContent.isNotEmpty) {
      await _complaintsCollection.doc(complaintId).update({
        'content': updatedContent,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _deleteComplaint(String complaintId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this complaint?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await _complaintsCollection.doc(complaintId).delete();
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: ComplaintPage(),
  ));
}
