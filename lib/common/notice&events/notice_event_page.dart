import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NoticeEventPage extends StatefulWidget {
  const NoticeEventPage({super.key});

  @override
  _NoticeEventPageState createState() => _NoticeEventPageState();
}

class _NoticeEventPageState extends State<NoticeEventPage> with SingleTickerProviderStateMixin {
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
          color: Colors.grey.shade400,
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
                      Text(
                        'Title: $title',
                        style: TextStyle(color: gold,fontWeight: FontWeight.bold),
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
          color: Colors.grey.shade400,
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
                      Text(
                        'Title: $title',
                        style: TextStyle(color: gold, fontWeight: FontWeight.bold),
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

}
