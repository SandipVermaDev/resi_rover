import 'package:flutter/material.dart';
import 'package:resi_rover/user/complaint/add_complaint_page.dart';
import 'package:resi_rover/user/complaint/closed_complaints.dart';
import 'package:resi_rover/user/complaint/on_hold_complaints.dart';
import 'package:resi_rover/user/complaint/open_complaints.dart';
import 'package:resi_rover/user/complaint/pending_complaints.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  _ComplaintPageState createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complaints', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
        bottom: TabBar(
          labelColor: gold,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.access_time)),
            Tab(text: 'Open', icon: Icon(Icons.open_in_new)),
            Tab(text: 'On Hold', icon: Icon(Icons.pause)),
            Tab(text: 'Closed', icon: Icon(Icons.check)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PendingComplaints(),
          OpenComplaints(),
          OnHoldComplaints(),
          ClosedComplaints(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddComplaintPage()),
          );
        },
        backgroundColor: gold,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
