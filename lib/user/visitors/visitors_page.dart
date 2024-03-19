import 'package:flutter/material.dart';
import 'package:resi_rover/user/visitors/visitors_history.dart';
import 'package:resi_rover/user/visitors/visitors_today.dart';

class VisitorsPage extends StatefulWidget {
  const VisitorsPage({super.key});

  @override
  _VisitorsPageState createState() => _VisitorsPageState();
}

class _VisitorsPageState extends State<VisitorsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Visitors',
          style: TextStyle(color: gold),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
        bottom: TabBar(
          controller: _tabController,
          labelColor: gold,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today)),
            Tab(text: 'History', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          VisitorsTodayTab(),
          VisitorsHistoryTab(),
        ],
      ),
    );
  }
}
