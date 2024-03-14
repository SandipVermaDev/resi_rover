import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentPage extends StatefulWidget {
  final String complaintId;

  const CommentPage({super.key, required this.complaintId});

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _commentController = TextEditingController();
  Color gold = const Color(0xFFD7B504);
  User? currentUser;

  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: Container(
        color: Colors.grey,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: commentStream(widget.complaintId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No comments.'));
                  }

                  _comments = snapshot.data!;

                  return ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      var comment = _comments[index];
                      DateTime commentTime = comment['timestamp'].toDate();
                      String userName = comment['user'];
                      String commentText = comment['text'];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    userName,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                if (comment['email'] == currentUser?.email)
                                  GestureDetector(
                                    onTap: () {
                                      _showDeleteConfirmation(comment['id']);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(Icons.delete_rounded,
                                          color: Colors.red),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              commentText,
                              style: TextStyle(
                                  color: gold, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              _formatDateTime(commentTime),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: TextStyle(color: gold),
                      decoration: InputDecoration(
                        hintText: 'Type your Comment...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        filled: true,
                        fillColor: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _handleCommentSubmission();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: Icon(Icons.send, color: gold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> commentStream(String complaintId) {
    return FirebaseFirestore.instance
        .collection('complaints')
        .doc(complaintId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map<List<Map<String, dynamic>>>((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  Future<List<Map<String, dynamic>>> fetchComments(String complaintId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('complaints')
          .doc(complaintId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (error) {
      print("Error fetching comments: $error");
      return [];
    }
  }

  Future<void> addComment(String complaintId, String commentText) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String userEmail = currentUser.email ?? "";

        DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userEmail)
                .get();

        if (userSnapshot.exists) {
          String userName ="Anonymous";
          DateTime timestamp = DateTime.now();

          String userType = userSnapshot['userType'] ?? "";
          if (userType.toLowerCase() == 'admin') {
            userName = 'Admin';
          } else{
            userName = userSnapshot['name'];
          }

          await FirebaseFirestore.instance
              .collection('complaints')
              .doc(complaintId)
              .collection('comments')
              .add({
            'email': userEmail,
            'user': userName,
            'text': commentText,
            'timestamp': timestamp,
          });

          setState(() {
            _comments.add({
              'email': userEmail,
              'user': userName,
              'text': commentText,
              'timestamp': timestamp,
            });
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment added successfully!'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (error) {
      print("Error adding comment: $error");
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  void _handleCommentSubmission() {
    String commentText = _commentController.text.trim();
    if (commentText.isNotEmpty) {
      addComment(widget.complaintId, commentText);
      // Move clear method inside setState to ensure it is executed after the state is updated
      setState(() {
        _commentController.clear();
      });
    }
  }

  void _showDeleteConfirmation(String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text('Delete Comment', style: TextStyle(color: gold)),
          content: Text('Are you sure you want to delete this comment?',
              style: TextStyle(color: gold)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                _handleDeleteComment(commentId);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteComment(String commentId) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String userEmail = currentUser.email ?? "";

        // Check if the user owns the comment before allowing deletion
        QuerySnapshot<Map<String, dynamic>> commentSnapshot =
            await FirebaseFirestore.instance
                .collection('complaints')
                .doc(widget.complaintId)
                .collection('comments')
                .where('email', isEqualTo: userEmail)
                .where(FieldPath.documentId, isEqualTo: commentId)
                .get();

        if (commentSnapshot.docs.isNotEmpty) {
          // User owns the comment, proceed with deletion
          await FirebaseFirestore.instance
              .collection('complaints')
              .doc(widget.complaintId)
              .collection('comments')
              .doc(commentId)
              .delete();

          setState(() {
            _comments.removeWhere((comment) => comment['id'] == commentId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment deleted successfully!'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // User does not own the comment, show an error or do nothing
          print('You do not have permission to delete this comment.');
        }
      }
    } catch (error) {
      print("Error deleting comment: $error");
    }
  }
}
