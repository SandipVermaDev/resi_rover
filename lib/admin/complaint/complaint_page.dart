import 'package:flutter/material.dart';
import 'package:resi_rover/admin/complaint/admin_pending_complaints.dart';
import 'package:resi_rover/admin/complaint/admin_open_complaints.dart';
import 'package:resi_rover/admin/complaint/admin_on_hold_complaints.dart';
import 'package:resi_rover/admin/complaint/admin_closed_complaints.dart';

class AdminComplaintPage extends StatefulWidget {
  const AdminComplaintPage({super.key});

  @override
  _AdminComplaintPageState createState() => _AdminComplaintPageState();
}

class _AdminComplaintPageState extends State<AdminComplaintPage>
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
    );
  }
}
