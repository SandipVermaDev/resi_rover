import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resi_rover/common/comment_page.dart';
import 'package:resi_rover/common/delete_complaint.dart';
import 'package:resi_rover/common/liked_users.dart';

class OpenComplaints extends StatefulWidget {
  const OpenComplaints({super.key});

  @override
  State<OpenComplaints> createState() => _OpenComplaintsState();
}

class _OpenComplaintsState extends State<OpenComplaints> {
  Color gold = const Color(0xFFD7B504);

  DateTime? extractTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .where('status', isEqualTo: 'Open')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(gold),
                  strokeWidth: 3.0,
                ));
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending complaints.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var complaint = snapshot.data!.docs[index];
              DateTime? uploadTime = extractTimestamp(complaint['timestamp']);

              return Card(
                margin: const EdgeInsets.all(20.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                elevation: 5.0,
                color: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              complaint['userName'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5,right: 5),
                              child: DropdownButton<String>(
                                value: complaint['status'],
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    _handleStatusChange(complaint.id, newValue);
                                  }
                                },
                                items: <String>['Pending', 'Open', 'On Hold', 'Closed']
                                    .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                iconEnabledColor: Colors.white,
                                dropdownColor: gold,
                                underline: Container(),
                                elevation: 5,
                              ),
                            ),
                          ),
                          PopupMenuButton(
                            color: gold,
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _handlePopupMenuSelection(
                                  value,
                                  complaint.id,
                                  complaint['title'],
                                  complaint['details'],
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        complaint['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                          color: gold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        complaint['details'],
                        style: TextStyle(fontSize: 15.0, color: gold),
                      ),
                      const SizedBox(height: 10.0),
                      Text(
                        'Uploaded on: ${_formatDateTime(uploadTime)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          const Spacer(),
                          GestureDetector(
                            onLongPress: () {
                              _handleLikeAction(
                                  complaint.id,
                                  complaint.data() as Map<String, dynamic>,
                                  isLongPress: true);
                            },
                            child: IconButton(
                              icon: const Icon(Icons.thumb_up),
                              onPressed: () {
                                _handleLikeAction(
                                    complaint.id,
                                    complaint.data() as Map<String, dynamic>);
                              },
                              color: _isLiked(complaint.id,
                                  complaint.data() as Map<String, dynamic>)
                                  ? gold
                                  : Colors.grey,
                            ),
                          ),
                          Text(
                            '${complaint['likes'].length}',
                            style: TextStyle(color: gold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.comment),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CommentPage(complaintId: complaint.id),
                                ),
                              );
                            },
                            color: gold,
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('complaints')
                                .doc(complaint.id)
                                .collection('comments')
                                .snapshots(),
                            builder: (context, commentsSnapshot) {
                              if (commentsSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox.shrink();
                              }

                              if (commentsSnapshot.hasError) {
                                return Text(
                                    'Error: ${commentsSnapshot.error}');
                              }

                              int commentsCount =
                                  commentsSnapshot.data!.docs.length;

                              return Text(
                                '$commentsCount',
                                style: TextStyle(color: gold),
                              );
                            },
                          ),
                          const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleStatusChange(String complaintId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(complaintId)
          .update({'status': newStatus});

      // Add any additional logic you may need after updating the status

    } catch (error) {
      print("Error updating complaint status: $error");
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return 'N/A';
    }

    String period = dateTime.hour >= 12 ? 'PM' : 'AM';
    int hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} $hour:${dateTime.minute} $period';
  }

  void _handlePopupMenuSelection(String value, String complaintId,
      String currentTitle, String currentDetails) {
    if (value == 'delete') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return DeleteConfirmationDialog(complaintId: complaintId);
        },
      );
    }
  }

  bool _isLiked(String complaintId, Map<String, dynamic> complaint) {
    String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    return currentUserEmail != null &&
        complaint['likes'].contains(currentUserEmail);
  }

  void _handleLikeAction(String complaintId, Map<String, dynamic> complaint,
      {bool isLongPress = false}) async {
    try {
      String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;

      if (currentUserEmail != null) {
        DocumentReference complaintRef = FirebaseFirestore.instance
            .collection('complaints')
            .doc(complaintId);
        DocumentSnapshot complaintSnapshot = await complaintRef.get();

        if (complaintSnapshot.exists) {
          List<String> likes =
          List<String>.from(complaintSnapshot['likes']);

          if (_isLiked(complaintId, complaint)) {
            // User has already liked, so unlike
            likes.remove(currentUserEmail);
          } else {
            // User hasn't liked, so like
            likes.add(currentUserEmail);
          }

          await complaintRef.update({'likes': likes});

          if (isLongPress) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LikedByPage(likes: likes),
              ),
            );
          }
        }
      }
    } catch (error) {
      print("Error handling like action: $error");
    }
  }
}
