import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:resi_rover/common/chat/chat_page.dart';
import 'package:resi_rover/common/slider/carousel_slider.dart';
import 'package:resi_rover/user/complaint/complaint_page.dart';
import 'package:resi_rover/user/profile/user_profile.dart';
import 'package:resi_rover/user/voting/voting_page.dart';
import 'package:resi_rover/common/notice&events/notice_event_page.dart';
import 'package:resi_rover/common/maid/maid_page.dart';
import 'package:resi_rover/user/visitors/visitors_page.dart';
import 'package:resi_rover/common/security/security_page.dart';
import 'package:resi_rover/auth/firebase_auth.dart';
import 'package:resi_rover/main.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  String _selectedSection = '';
  late User? _currentUser;
  String _userProfileImageUrl = '';

  Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _getUserProfileImage();
  }

  Future<void> _getUserProfileImage() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.email)
          .snapshots()
          .listen((DocumentSnapshot userSnapshot) async {
        if (userSnapshot.exists) {
          if (userSnapshot['userType'] == 'disabled') {
            await _showAccountDeletedDialog();
            await AuthClass().auth.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ChooseScreen()),
            );
          } else {
            setState(() {
              _userProfileImageUrl = userSnapshot['profileImageURL'] ?? '';
            });
          }
        }
      });
    }
  }

  Future<void> _showAccountDeletedDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: gold,
            title: const Text('Account Deleted',style: TextStyle(color: Colors.black)),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Your account has been deleted by the admin.',style: TextStyle(color: Colors.black)),
                  Text('Please contact the admin for further assistance.',style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK',style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Home Page', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFD7B504)),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.grey.shade400,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.black87,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        _selectSection('Profile');
                      },
                      child: _userProfileImageUrl.isNotEmpty
                          ? CircleAvatar(
                        radius: 50,
                        backgroundImage: CachedNetworkImageProvider(_userProfileImageUrl),
                      )
                          : const Icon(
                        Icons.account_circle,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentUser?.email ?? 'User Email',
                      style: TextStyle(color: gold,fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildDrawerItem('Chat', Icons.chat),
              const SizedBox(height: 16),
              _buildDrawerItem('Complaint', Icons.warning),
              const SizedBox(height: 16),
              _buildDrawerItem('Voting', Icons.how_to_vote),
              const SizedBox(height: 16),
              _buildDrawerItem('Notice & Events', Icons.event),
              const SizedBox(height: 16),
              _buildDrawerItem('Maid', Icons.cleaning_services_rounded),
              const SizedBox(height: 16),
              _buildDrawerItem('Visitors', Icons.emoji_people),
              const SizedBox(height: 16),
              _buildDrawerItem('Security', Icons.security),
              const SizedBox(height: 16),
              _buildDrawerItem('Logout', Icons.logout),
            ],
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey.shade400,
        child: Column(
          children: [
            const ResidencyCarousel(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildGridView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String section, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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

    // Navigate to the corresponding page
    switch (_selectedSection) {
      case 'Chat':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ChatPage()));
        break;
      case 'Complaint':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ComplaintPage()));
        break;
      case 'Voting':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const VotingPage()));
        break;
      case 'Notice & Events':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NoticeEventPage()));
        break;
      case 'Maid':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MaidPage()));
        break;
      case 'Visitors':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const VisitorsPage()));
        break;
      case 'Security':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const SecurityPage()));
        break;
      case 'Profile':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const ProfilePage()));
        break;
      case 'Logout':
        try {
          await AuthClass().auth.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ChooseScreen()),
          ); // Navigate to the login screen
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
        _buildGridItem('Chat', Icons.chat, Colors.green),
        _buildGridItem('Complaint', Icons.warning, Colors.red),
        _buildGridItem('Voting', Icons.how_to_vote, Colors.purple),
        _buildGridItem('Notice & Events', Icons.event, Colors.orange),
        _buildGridItem('Maid', Icons.cleaning_services, Colors.indigo),
        _buildGridItem('Visitors', Icons.emoji_people, Colors.brown),
        _buildGridItem('Security', Icons.security, Colors.teal),
        _buildGridItem('Profile', Icons.person, Colors.blue),
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
