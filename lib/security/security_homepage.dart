import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:resi_rover/auth/firebase_auth.dart';
import 'package:resi_rover/common/slider/carousel_slider.dart';
import 'package:resi_rover/main.dart';
import 'package:resi_rover/security/profile/profile_page.dart';
import 'package:resi_rover/security/users/users_page.dart';
import 'package:resi_rover/security/visitors/visitors_page.dart';
import 'package:resi_rover/common/maid/maid_page.dart';
import 'package:resi_rover/common/notice&events/notice_event_page.dart';
import 'package:resi_rover/common/security/security_page.dart';

class SecurityHomePage extends StatefulWidget {
  const SecurityHomePage({super.key});

  @override
  State<SecurityHomePage> createState() => _SecurityHomePageState();
}

class _SecurityHomePageState extends State<SecurityHomePage> {
  String _selectedSection = '';
  late User? _currentUser;
  String _userProfileImageUrl = '';

  Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _getSecurityProfileImage();
  }

  Future<void> _getSecurityProfileImage() async {
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
        title: Text('Security Home Page', style: TextStyle(color: gold)),
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
                              backgroundImage:
                              CachedNetworkImageProvider(_userProfileImageUrl),
                            )
                          : const Icon(
                              Icons.account_circle,
                              size: 100,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentUser?.email ?? 'Security Email',
                      style:
                          TextStyle(color: gold, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildDrawerItem('Visitors', Icons.emoji_people),
              const SizedBox(height: 16),
              _buildDrawerItem('Notice & Events', Icons.event),
              const SizedBox(height: 16),
              _buildDrawerItem('Maid', Icons.cleaning_services_rounded),
              const SizedBox(height: 16),
              _buildDrawerItem('Users', Icons.person),
              const SizedBox(height: 16),
              _buildDrawerItem('Security', Icons.security),
              const SizedBox(height: 16),
              _buildDrawerItem('Profile', Icons.person),
              const SizedBox(height: 16),
              _buildDrawerItem('Logout', Icons.logout),
            ],
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey.shade400,
        child:  Column(
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
      case 'Visitors':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const VisitorsPage()));
        break;
      case 'Notice & Events':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NoticeEventPage()));
        break;
      case 'Maid':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MaidPage()));
        break;
      case 'Users':
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const UsersPage()));
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
        _buildGridItem('Visitors', Icons.emoji_people, Colors.brown),
        _buildGridItem('Notice & Events', Icons.event, Colors.orange),
        _buildGridItem('Maid', Icons.cleaning_services, Colors.indigo),
        _buildGridItem('Users', Icons.people_outlined, Colors.blue),
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
