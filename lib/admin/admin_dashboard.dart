import 'package:flutter/material.dart';
import 'package:resi_rover/admin/complaint/complaint_page.dart';
import 'package:resi_rover/admin/maid/maid_page.dart';
import 'package:resi_rover/admin/notice&events/notice_event_page.dart';
import 'package:resi_rover/admin/resi_info/residential_info.dart';
import 'package:resi_rover/admin/security/security_page.dart';
import 'package:resi_rover/admin/users/users_page.dart';
import 'package:resi_rover/admin/voting/voting_page.dart';
import 'package:resi_rover/auth/firebase_auth.dart';
import 'package:resi_rover/common/chat/chat_page.dart';
import 'package:resi_rover/admin/visitors/visitors_page.dart';
import 'package:resi_rover/main.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _selectedSection = '';

  Color gold = const Color(0xFFD7B504);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Color(0xFFD7B504)),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: gold),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ResidentialInfoPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.grey.shade400,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.black87,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Menu',
                      style: TextStyle(
                        color: Color(0xFFD7B504),
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildDrawerItem('Users', Icons.people),
              const SizedBox(height: 16),
              _buildDrawerItem('Chat', Icons.chat),
              const SizedBox(height: 16),
              _buildDrawerItem('Notice & Events', Icons.event),
              const SizedBox(height: 16),
              _buildDrawerItem('Complaint', Icons.warning),
              const SizedBox(height: 16),
              _buildDrawerItem('Voting', Icons.how_to_vote),
              const SizedBox(height: 16),
              _buildDrawerItem('Security', Icons.security),
              const SizedBox(height: 16),
              _buildDrawerItem('Maid', Icons.cleaning_services_rounded),
              const SizedBox(height: 16),
              _buildDrawerItem('Visitors', Icons.emoji_people),
              const SizedBox(height: 16),
              _buildDrawerItem('Logout', Icons.exit_to_app),
            ],
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey.shade400,
        child: _buildGridView(),
      ),
    );
  }

  Widget _buildDrawerItem(String section, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _selectSection(section);
          },
          child: ListTile(
            title: Row(
              children: [
                Icon(
                  icon,
                  color: gold,
                ),
                const SizedBox(width: 16),
                Text(
                  section,
                  style: const TextStyle(color: Color(0xFFD7B504)),
                ),
              ],
            ),
            selected: _selectedSection == section,
            onTap: () {
              _selectSection(section);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _selectSection(String section) async {
    setState(() {
      _selectedSection = section;
    });

    switch (_selectedSection) {
      case 'Users':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const UsersPage()));
        break;
      case 'Chat':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ChatPage()));
        break;
      case 'Notice & Events':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NoticeEventsPage()));
        break;
      case 'Complaint':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminComplaintPage()));
        break;
      case 'Voting':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const VotingPage()));
        break;
      case 'Security':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SecurityPage()));
        break;
      case 'Maid':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MaidPage()));
        break;
      case 'Visitors':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const VisitorsPage()));
        break;
      case 'Logout':
        try {
          await AuthClass().auth.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChooseScreen()),
          );
        } catch (e) {
          print("Error logging out: $e");
        }

        break;
    }
  }

  Widget _buildGridView() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: [
        _buildGridItem('Users', Icons.people, Colors.blue),
        _buildGridItem('Chat', Icons.chat, Colors.green),
        _buildGridItem('Notice & Events', Icons.event, Colors.orange),
        _buildGridItem('Complaint', Icons.warning, Colors.red),
        _buildGridItem('Voting', Icons.how_to_vote, Colors.purple),
        _buildGridItem('Security', Icons.security, Colors.teal),
        _buildGridItem('Maid', Icons.cleaning_services, Colors.indigo),
        _buildGridItem('Visitors', Icons.emoji_people, Colors.brown),
      ],
    );
  }

  Widget _buildGridItem(String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        _selectSection(title);
      },
      child: Card(
        elevation: 4.0,
        color: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50.0, color: color),
            const SizedBox(height: 10.0),
            Text(
              title,
              style: const TextStyle(fontSize: 20.0, color: Color(0xFFD7B504)),
            ),
          ],
        ),
      ),
    );
  }
}
