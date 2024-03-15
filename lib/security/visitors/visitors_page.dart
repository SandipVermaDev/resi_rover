import 'package:flutter/material.dart';
import 'package:resi_rover/security/visitors/add_visitors.dart';

class VisitorsPage extends StatefulWidget {
  const VisitorsPage({super.key});

  @override
  State<VisitorsPage> createState() => _VisitorsPageState();
}

class _VisitorsPageState extends State<VisitorsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(text: 'In Society',icon: Icon(Icons.input_sharp)),
            Tab(text: 'Today',icon: Icon(Icons.today)),
            Tab(text: 'History',icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Visitors in society
          _buildTabContent('Visitors in Society'),
          // Visitors who visited today
          _buildTabContent('Visitors Today'),
          // All visitors history
          _buildTabContent('All Visitors History'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddVisitorPage()),
          );
        },
        backgroundColor: gold,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildTabContent(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, color: Colors.amber),
      ),
    );
  }
}
