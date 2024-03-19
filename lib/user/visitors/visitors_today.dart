import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

Color gold = const Color(0xFFD7B504);

class VisitorsTodayTab extends StatefulWidget {
  const VisitorsTodayTab({super.key});

  @override
  _VisitorsTodayTabState createState() => _VisitorsTodayTabState();
}

class _VisitorsTodayTabState extends State<VisitorsTodayTab> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('visitors').snapshots(),
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
            stream: _fetchTodayVisitorsData(visitorDocs),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else {
                var visitorDataList = snapshot.data!;

                // Sort visitors based on check-in time
                visitorDataList.sort((a, b) {
                  var aCheckInTime =
                      a['checkInData']['checkInTime'] as Timestamp?;
                  var bCheckInTime =
                      b['checkInData']['checkInTime'] as Timestamp?;
                  var aCheckOutTime =
                      a['checkOutData']['checkOutTime'] as Timestamp?;
                  var bCheckOutTime =
                      b['checkOutData']['checkOutTime'] as Timestamp?;

                  if (aCheckInTime != null && bCheckInTime != null) {
                    return bCheckInTime.compareTo(aCheckInTime);
                  } else if (aCheckOutTime != null && bCheckOutTime != null) {
                    return bCheckOutTime.compareTo(aCheckOutTime);
                  } else if (aCheckInTime != null && bCheckOutTime != null) {
                    return bCheckOutTime.compareTo(aCheckInTime);
                  } else if (aCheckOutTime != null && bCheckInTime != null) {
                    return bCheckInTime.compareTo(aCheckOutTime);
                  } else {
                    // Handle null values here
                    return 0;
                  }
                });

                return ListView.builder(
                  itemCount: visitorDataList.length,
                  itemBuilder: (context, index) {
                    var visitorData = visitorDataList[index];
                    var visitorName = visitorData['name'];
                    var visitorPhone = visitorData['phone'];
                    var visitorProfileImageURL = visitorData['profileImageURL'];

                    var checkInData = visitorData['checkInData'];
                    var checkOutData = visitorData['checkOutData'];
                    var checkInTime = checkInData['checkInTime'];
                    var securityCheckIn = checkInData['securityName'];
                    var checkOutTime = checkOutData['checkOutTime'];
                    var securityCheckOut = checkOutData['securityName'];
                    var status = visitorData['status'];

                    return GestureDetector(
                      onTap: () async {
                        await _showVisitorDetailsPopup(
                          context,
                          visitorData,
                          checkInData,
                          checkOutData,
                        );
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: status == 'check in'
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    child: Text(
                                      status == 'check in'
                                          ? 'Checked In'
                                          : 'Checked Out',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                              const SizedBox(height: 8),
                              Text(
                                  'Check In Time: ${_formatTimestamp(checkInTime)}',
                                  style: TextStyle(color: gold, fontSize: 15)),
                              Text('Check In By: $securityCheckIn',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15)),
                              const SizedBox(height: 4),
                              if (status == 'check out') ...[
                                const SizedBox(height: 4),
                                Text(
                                    'Check Out Time: ${_formatTimestamp(checkOutTime)}',
                                    style:
                                        TextStyle(color: gold, fontSize: 15)),
                                Text('Check Out By: $securityCheckOut',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15)),
                              ],
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

  Stream<List<Map<String, dynamic>>> _fetchTodayVisitorsData(
    List<DocumentSnapshot> visitorDocs,
  ) {
    return Stream.fromFuture(Future.wait(visitorDocs.map((doc) async {
      var visitorId = doc.id;
      var visitorData = doc.data() as Map<String, dynamic>;

      // Retrieve current user's wing and flat information
      var currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        var userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.email)
          .get();

      var currentUserWing = userSnapshot['wing'];
      var currentUserFlat = userSnapshot['flat'];

      // Fetch latest check-in data
      var checkInSnapshot = await FirebaseFirestore.instance
          .collection('visitors')
          .doc(visitorId)
          .collection('check_in')
          .where('checkInTime', isGreaterThanOrEqualTo: _todayStartTimestamp())
          .where('checkInTime', isLessThanOrEqualTo: _todayEndTimestamp())
          .orderBy('checkInTime', descending: true)
          .limit(1)
          .get();

      // Fetch latest check-out data
      var checkOutSnapshot = await FirebaseFirestore.instance
          .collection('visitors')
          .doc(visitorId)
          .collection('check_out')
          .where('checkOutTime', isGreaterThanOrEqualTo: _todayStartTimestamp())
          .where('checkOutTime', isLessThanOrEqualTo: _todayEndTimestamp())
          .orderBy('checkOutTime', descending: true)
          .limit(1)
          .get();

      // Initialize variables for check-in and check-out data
      Map<String, dynamic> checkInData = {};
      Map<String, dynamic> checkOutData = {};

      // Check if check-in data exists and is today
      if (checkInSnapshot.docs.isNotEmpty) {
        var checkInTime =
            checkInSnapshot.docs.first['checkInTime'] as Timestamp?;
        if (_isToday(checkInTime)) {
          checkInData = checkInSnapshot.docs.first.data();
        }
      }

      // Check if check-out data exists and is today
      if (checkOutSnapshot.docs.isNotEmpty) {
        var checkOutTime =
            checkOutSnapshot.docs.first['checkOutTime'] as Timestamp?;
        if (_isToday(checkOutTime)) {
          /*var checkInSnapshot = await FirebaseFirestore.instance
              .collection('visitors')
              .doc(visitorId)
              .collection('check_in')
              .orderBy('checkInTime', descending: true)
              .limit(1)
              .get();*/

          checkInData = checkInSnapshot.docs.first.data();
          checkOutData = checkOutSnapshot.docs.first.data();
        }
      }

      // Check if visitor has either check-in or check-out data for today
      if (checkInData.isNotEmpty || checkOutData.isNotEmpty) {
        if (visitorData['wing'] == currentUserWing &&
            visitorData['flat'] == currentUserFlat) {
          return {
            'visitorId': visitorId,
            'name': visitorData['name'],
            'phone': visitorData['phone'],
            'profileImageURL': visitorData['profileImageURL'],
            'wing': visitorData['wing'],
            'flat': visitorData['flat'],
            'purpose': visitorData['purpose'],
            'checkInData': checkInData,
            'checkOutData': checkOutData,
            'status': visitorData['status'],
          };
        }
      }
      }
      return null;
    }))).map((dataList) => dataList.whereType<Map<String, dynamic>>().toList());
  }

  bool _isToday(Timestamp? timestamp) {
    if (timestamp != null) {
      var now = DateTime.now();
      var todayStart = DateTime(now.year, now.month, now.day);
      var todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      var dateTime = timestamp.toDate();
      return dateTime.isAfter(todayStart) && dateTime.isBefore(todayEnd);
    }
    return false;
  }

  Timestamp _todayStartTimestamp() {
    var now = DateTime.now();
    return Timestamp.fromDate(
        DateTime(now.year, now.month, now.day, 0, 0, 0, 0));
  }

  Timestamp _todayEndTimestamp() {
    var now = DateTime.now();
    return Timestamp.fromDate(
        DateTime(now.year, now.month, now.day, 23, 59, 59, 999));
  }

  Future<void> _showVisitorDetailsPopup(
    BuildContext context,
    Map<String, dynamic> visitorData,
    Map<String, dynamic> checkInData,
    Map<String, dynamic> checkOutData,
  ) async {
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
                  if (checkInData.isNotEmpty) // Changed the condition here
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
                  if (checkOutData.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text('Check Out Details:',
                            style: TextStyle(
                                color: gold, fontWeight: FontWeight.bold)),
                        Text(
                            '     Time: ${_formatTimestamp(checkOutData['checkOutTime'] as Timestamp?)}',
                            style: TextStyle(color: gold)),
                        Text(
                            '     Security Name: ${checkOutData['securityName']}',
                            style: TextStyle(color: gold)),
                        Text(
                            '     Security Email: ${checkOutData['securityEmail']}',
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
            ],
          ),
        );
      },
    );
  }
}
