import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Color gold = const Color(0xFFD7B504);

class VisitorsInSocietyTab extends StatefulWidget {
  const VisitorsInSocietyTab({super.key});

  @override
  _VisitorsInSocietyTabState createState() => _VisitorsInSocietyTabState();
}

class _VisitorsInSocietyTabState extends State<VisitorsInSocietyTab> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('visitors')
            .where('status', isEqualTo: 'check in')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var visitorDocs = snapshot.data!.docs;

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _fetchLatestCheckInDataStream(visitorDocs),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                var visitorDataList = snapshot.data!;

                // Sort visitors based on check-in time
                visitorDataList.sort((a, b) => (b['checkInData']['checkInTime']
                        as Timestamp)
                    .compareTo(a['checkInData']['checkInTime'] as Timestamp));

                return ListView.builder(
                  itemCount: visitorDataList.length,
                  itemBuilder: (context, index) {
                    var visitorData = visitorDataList[index];
                    var visitorId = visitorData['visitorId'];
                    var visitorName = visitorData['name'];
                    var visitorPhone = visitorData['phone'];
                    var visitorProfileImageURL = visitorData['profileImageURL'];
                    var checkInData = visitorData['checkInData'];
                    var checkInTime = checkInData['checkInTime'];
                    var securityName = checkInData['securityName'];

                    return GestureDetector(
                      onTap: () async {
                        _showVisitorDetailsPopup(
                            context, visitorData, checkInData, visitorId);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 16.0),
                        color: Colors.black,
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundImage: visitorProfileImageURL != null
                                ? NetworkImage(visitorProfileImageURL)
                                : null,
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      _confirmCheckOut(
                                          context, visitorId, checkInData);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: gold,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                    ),
                                    child: const Text('Check Out',
                                        style: TextStyle(
                                            fontSize: 15, color: Colors.black)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded),
                                    color: Colors.red,
                                    onPressed: () {
                                      _confirmDelete(context, visitorId);
                                    },
                                  ),
                                ],
                              ),
                              Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Name: $visitorName',
                                    style: TextStyle(color: gold, fontSize: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Phone: $visitorPhone',
                                  style: TextStyle(color: gold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(
                                  'Check In Time: ${_formatTimestamp(checkInTime)}',
                                  style: TextStyle(color: gold, fontSize: 15)),
                              Text(
                                'Check In By: $securityName',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp != null) {
      var dateTime = timestamp.toDate();
      var formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
      return formattedTime;
    } else {
      return 'Unknown';
    }
  }

  Stream<List<Map<String, dynamic>>> _fetchLatestCheckInDataStream(
      List<DocumentSnapshot> visitorDocs) {
    return Stream.fromFuture(Future.wait(visitorDocs.map((doc) async {
      var visitorId = doc.id;
      var visitorData = doc.data() as Map<String, dynamic>;
      var checkInSnapshot = await FirebaseFirestore.instance
          .collection('visitors')
          .doc(visitorId)
          .collection('check_in')
          .orderBy('checkInTime', descending: true)
          .limit(1)
          .get();

      if (checkInSnapshot.docs.isNotEmpty) {
        var checkInData = checkInSnapshot.docs.first.data();
        return {
          'visitorId': visitorId,
          'name': visitorData['name'],
          'phone': visitorData['phone'],
          'profileImageURL': visitorData['profileImageURL'],
          'wing': visitorData['wing'],
          'flat': visitorData['flat'],
          'purpose': visitorData['purpose'],
          'checkInData': checkInData,
        };
      } else {
        return {};
      }
    })));
  }

  Future<void> _showVisitorDetailsPopup(
      BuildContext context,
      Map<String, dynamic> visitorData,
      Map<String, dynamic> checkInData,
      String visitorId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: AlertDialog(
            backgroundColor: Colors.black87,
            title: Text('Visitor Details', style: TextStyle(color: gold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 25),
                  if (visitorData['profileImageURL'] != null)
                    Image.network(visitorData['profileImageURL'], height: 200),
                  const SizedBox(height: 25),
                  Text('Name: ${visitorData['name']}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: gold)),
                  const SizedBox(height: 10),
                  Text('Phone: ${visitorData['phone']}',
                      style: TextStyle(color: gold)),
                  const SizedBox(height: 10),
                  Text('Wing: ${visitorData['wing']}',
                      style: TextStyle(color: gold)),
                  const SizedBox(height: 10),
                  Text('Flat: ${visitorData['flat']}',
                      style: TextStyle(color: gold)),
                  const SizedBox(height: 10),
                  Text('Purpose: ${visitorData['purpose']}',
                      style: TextStyle(color: gold)),
                  const SizedBox(height: 20),
                  Text('Check In Details:',
                      style:
                          TextStyle(color: gold, fontWeight: FontWeight.bold)),
                  if (checkInData.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '     Time: ${_formatTimestamp(checkInData['checkInTime'] as Timestamp?)}',
                            style: TextStyle(color: gold)),
                        Text(
                            '     Security Name: ${checkInData['securityName']}',
                            style: TextStyle(color: gold)),
                        Text(
                            '     Security Email: ${checkInData['securityEmail']}',
                            style: TextStyle(color: gold)),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () {
                  _confirmCheckOut(context, visitorId, checkInData);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: const Text('Check Out',
                    style: TextStyle(fontSize: 15, color: Colors.black)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmCheckOut(BuildContext context, String visitorId,
      Map<String, dynamic> checkInData) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text('Confirm Check Out', style: TextStyle(color: gold)),
          content: Text('Are you sure you want to check out?',
              style: TextStyle(color: gold)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                _handleCheckOut(visitorId, checkInData);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text('Confirm',
                  style: TextStyle(fontSize: 15, color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCheckOut(
      String visitorId, Map<String, dynamic> checkInData) async {
    try {
      // Get current user's email
      User? user = FirebaseAuth.instance.currentUser;
      String userEmail = user!.email!;

      // Fetch security name from users collection
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .get();

      if (userSnapshot.exists) {
        String userName = userSnapshot['name'];

        // Update visitor status to check out
        await FirebaseFirestore.instance
            .collection('visitors')
            .doc(visitorId)
            .update({'status': 'check out'});

        // Add check-out details to sub-collection
        await FirebaseFirestore.instance
            .collection('visitors')
            .doc(visitorId)
            .collection('check_out')
            .add({
          'checkOutTime': Timestamp.now(),
          'securityEmail': userEmail,
          'securityName': userName,
        });
      }
    } catch (error) {
      print('Error during check-out: $error');
    }
  }

  Future<void> _confirmDelete(BuildContext context, String visitorId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text('Confirm Delete', style: TextStyle(color: gold)),
          content: Text('Are you sure you want to delete this visitor?',
              style: TextStyle(color: gold)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                _handleDelete(visitorId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.red, // Use a different color for the delete button
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text('Delete',
                  style: TextStyle(fontSize: 15, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDelete(String visitorId) async {
    try {
      // Fetch visitor profile image URL from Firestore
      DocumentSnapshot visitorSnapshot = await FirebaseFirestore.instance
          .collection('visitors')
          .doc(visitorId)
          .get();
      String? profileImageURL = visitorSnapshot.get('profileImageURL');

      // Delete visitor profile image from Firebase Storage if exists
      if (profileImageURL != null && profileImageURL.isNotEmpty) {
        await firebase_storage.FirebaseStorage.instance
            .refFromURL(profileImageURL)
            .delete();
      }


      // Create a batch to perform multiple operations
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Delete subcollections
      await _deleteSubcollections(visitorId, batch);

      // Delete the main document
      batch.delete(FirebaseFirestore.instance.collection('visitors').doc(visitorId));

      // Commit the batched writes
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visitor deleted successfully.'),
          duration: Duration(seconds: 2), // Adjust duration as needed
        ),
      );
    } catch (error) {
      print('Error during delete: $error');
    }
  }

  Future<void> _deleteSubcollections(String documentId, WriteBatch batch) async {
    // Define the names of subcollections
    List<String> subcollectionNames = ['check_in', 'check_out'];

    // Iterate through each subcollection and delete its documents
    for (String subcollectionName in subcollectionNames) {
      QuerySnapshot subcollectionSnapshot = await FirebaseFirestore.instance
          .collection('visitors')
          .doc(documentId)
          .collection(subcollectionName)
          .get();

      for (DocumentSnapshot document in subcollectionSnapshot.docs) {
        batch.delete(document.reference);
      }
    }
  }

}