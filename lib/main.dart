import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:resi_rover/screens/login_page.dart';
import 'package:resi_rover/screens/splash_screen.dart';
import 'package:resi_rover/security/security_homepage.dart';
import 'package:resi_rover/user/user_homepage.dart';

import 'admin/admin_dashboard.dart';
import 'auth/firebase_auth.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ResiRover',
      home: WillPopScope(
          onWillPop: () async {
            return true;
          },
          child: const SplashScreen()),
    );
  }
}

class ChooseScreen extends StatelessWidget {
  const ChooseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthClass().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          String? email = AuthClass().getCurrentUserEmail();

          if (email != null) {
            return FutureBuilder<String?>(
              future: getUserTypeFromFirestore(context, email),
              builder: (context, userTypeSnapshot) {
                if (userTypeSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFD7B504)),
                      strokeWidth: 3.0,
                    ),
                  );
                } else if (userTypeSnapshot.hasError) {
                  return const Text('Error retrieving user type');
                } else {
                  String? userType = userTypeSnapshot.data;

                  if (userType == 'admin') {
                    return const AdminDashboard();
                  } else if (userType == 'user') {
                    return const UserHomePage();
                  } else if (userType == 'security') {
                    return const SecurityHomePage();
                  } else {
                    return const Text('Unknown user type');
                  }
                }
              },
            );
          } else {
            return const Text('Error: User email is null');
          }
        } else {
          return const LoginAndRegisterScreen();
        }
      },
    );
  }

  Future<String?> getUserTypeFromFirestore(
      BuildContext context, String email) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['userType'];
      } else {
        return null;
      }
    } catch (e) {
      print("Error retrieving user type from Firestore: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error retrieving user type from Firestore: $e"),
          duration: const Duration(seconds: 3),
        ),
      );

      return null;
    }
  }
}
