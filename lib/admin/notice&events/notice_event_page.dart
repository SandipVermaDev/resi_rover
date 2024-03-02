import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:resi_rover/admin/notice&events/add_event.dart';
import 'package:resi_rover/admin/notice&events/add_notice.dart';
import 'package:resi_rover/admin/notice&events/edit_event.dart';
import 'package:resi_rover/admin/notice&events/edit_notice.dart';

class NoticeEventsPage extends StatefulWidget {
  const NoticeEventsPage({super.key});

  @override
  _NoticeEventsPageState createState() => _NoticeEventsPageState();
}

class _NoticeEventsPageState extends State<NoticeEventsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notice & Events', style: TextStyle(color: gold)),
        iconTheme: IconThemeData(color: gold),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: gold,
          tabs: const [
            Tab(
              text: 'Notices',
              icon: Icon(Icons.notification_important),
            ),
            Tab(
              text: 'Events',
              icon: Icon(Icons.event),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNoticeTab(),
          _buildEventsTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildNoticeTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notices').orderBy('timestamp', descending: true).snapshots(),
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

        var noticeDocs = snapshot.data!.docs;

        return Container(
          color: Colors.grey,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView.builder(
              itemCount: noticeDocs.length,
              itemBuilder: (context, index) {
                var noticeData = noticeDocs[index].data() as Map<String, dynamic>;
                var title = noticeData['title'];
                var description = noticeData['description'];
                var timestamp = noticeData['timestamp'];

                var formattedDate = timestamp != null ? DateFormat('yyyy-MM-dd').format(timestamp.toDate()) : '';
                var formattedTime = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : '';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Title: $title',
                            style: TextStyle(color: gold,fontWeight: FontWeight.bold),
                          ),
                          PopupMenuButton(
                            color: gold,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (context) => EditNoticeDialog(noticeId: noticeDocs[index].id),
                                    );
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deleteNotice(noticeDocs[index].id);
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.delete),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        'Description: $description',
                        style: TextStyle(color: gold),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          'Uploaded On:\nDate: $formattedDate\nTime: $formattedTime',
                          style: TextStyle(color: gold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('events').orderBy('timestamp', descending: true).snapshots(),
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

        var eventDocs = snapshot.data!.docs;

        return Container(
          color: Colors.grey,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView.builder(
              itemCount: eventDocs.length,
              itemBuilder: (context, index) {
                var eventData = eventDocs[index].data() as Map<String, dynamic>;
                var title = eventData['title'];
                var description = eventData['description'];
                var eventDate = eventData['date'];
                var eventTime = eventData['time'];

                var uploadTimestamp = eventData['timestamp'];
                var formattedUploadDate = '';
                var formattedUploadTime = '';

                if (uploadTimestamp != null) {
                  var uploadDateTime = uploadTimestamp.toDate();
                  formattedUploadDate = DateFormat('yyyy-MM-dd').format(uploadDateTime);
                  formattedUploadTime = DateFormat('hh:mm a').format(uploadDateTime);
                }

                var formattedEventDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(eventDate));
                var formattedEventTime = DateFormat('hh:mm a').format(DateTime.parse('2022-01-01 $eventTime'));


                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Title: $title',
                            style: TextStyle(color: gold, fontWeight: FontWeight.bold),
                          ),
                          PopupMenuButton(
                            color: gold,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    showDialog(
                                      context: context,
                                      builder: (context) => EditEventDialog(eventId: eventDocs[index].id), // Show EditEventDialog for events
                                    );
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                              ),
                              PopupMenuItem(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _deleteEvent(eventDocs[index].id);
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.delete),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        'Description: $description',
                        style: TextStyle(color: gold),
                      ),
                      Text(
                        'Event Date: $formattedEventDate',
                        style: TextStyle(color: gold, fontSize: 12),
                      ),
                      Text(
                        'Event Time: $formattedEventTime',
                        style: TextStyle(color: gold, fontSize: 12),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Uploaded On\nDate: $formattedUploadDate \nTime: $formattedUploadTime',
                              style: TextStyle(color: gold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }


  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        if (_tabController.index == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNoticePage()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventPage()),
          );
        }
      },
      backgroundColor: gold,
      child: const Icon(Icons.add),
    );
  }

  void _deleteNotice(String noticeId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title:Text('Confirm Deletion',style: TextStyle(color: gold)),
          content:Text('Are you sure you want to delete this notice?',style: TextStyle(color: gold)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel',style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _performDeleteNotice(noticeId); // Proceed with deletion
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _performDeleteNotice(String noticeId) async {
    try {
      await FirebaseFirestore.instance.collection('notices').doc(noticeId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notice deleted successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting notice: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _deleteEvent(String eventId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text('Confirm Deletion',style: TextStyle(color: gold)),
          content: Text('Are you sure you want to delete this event?',style: TextStyle(color: gold)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel',style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                _performDeleteEvent(eventId); // Proceed with deletion
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _performDeleteEvent(String eventId) async {
    try {
      await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event deleted successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting event: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

}
