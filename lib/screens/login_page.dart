import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:resi_rover/admin/admin_dashboard.dart';
import 'package:resi_rover/security/security_homepage.dart';
import 'package:resi_rover/user/user_homepage.dart';
import '../auth/firebase_auth.dart';
import 'forgot_password_screen.dart';
import '../user/userform.dart';

class LoginAndRegisterScreen extends StatefulWidget {
  const LoginAndRegisterScreen({super.key});

  @override
  State<LoginAndRegisterScreen> createState() => _LoginAndRegisterScreenState();
}

class _LoginAndRegisterScreenState extends State<LoginAndRegisterScreen> {
  Color gold = const Color(0xFFD7B504);

  bool loginScreenVisible = true;
  bool showLoading = false;
  String email = '';
  String password = '';
  bool isPasswordVisible = false;
  String userType = 'user';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          loginScreenVisible ? 'Login' : 'Signup',
          style: TextStyle(color: gold),
        ),
        backgroundColor: Colors.black, // Updated app bar color
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black
                    .withOpacity(0.7), // Adjust the opacity here (0.0 to 1.0)
                BlendMode.srcATop,
              ),
              child: Image.asset(
                'assets/login.png', // Replace with your image asset path
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(
            height: double.infinity,
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50, vertical: 200),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    inputField('Email', Icons.email, 'Enter email...', false),
                    inputField(
                        'Password', Icons.lock, 'Enter password...', true),
                    const SizedBox(
                      height: 10,
                    ),
                    !loginScreenVisible
                        ? const SizedBox(
                            height: 16,
                          )
                        : forgotPassword(),
                    loginRegisterButton(),
                    toggleIconButton(),
                    const SizedBox(
                      height: 20,
                    )
                  ],
                ),
              ),
            ),
          ),
          // Centered CircularProgressIndicator when showLoading is true
          if (showLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(gold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget inputField(
      String label, IconData icon, String hintText, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20, left: 20, right: 20),
      child: TextField(
        onChanged: (value) {
          setState(() {
            if (label == 'Email') {
              email = value;
            }
            if (label == 'Password') {
              password = value;
            }
          });
        },
        obscureText: isPassword && !isPasswordVisible,
        cursorColor: gold, // Updated cursor color
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: gold),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black87),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black87, fontSize: 16),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: gold, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: gold,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget forgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ForgotPasswordScreen(),
            ),
          );
        },
        child: const Text(
          'Forgot password?   ',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget loginRegisterButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 31, bottom: 31, left: 30, right: 30),
      child: MaterialButton(
        onPressed: email.isEmpty || password.isEmpty || showLoading
            ? null
            : () async {
                if (!mounted) return;

                setState(() {
                  showLoading = true;
                });

                try {
                  if (loginScreenVisible) {
                    await AuthClass().signIn(email, password);

                    String? userType = await getUserTypeFromFirestore(email);

                    if (userType == 'admin') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminDashboard()));
                    } else if (userType == 'user') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const UserHomePage()));
                    } else if (userType == 'security') {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SecurityHomePage()));
                    }
                  } else {
                    await AuthClass().register(email, password);

                    Navigator.pushReplacement(context,
                        MaterialPageRoute(builder: (_) => const UserForm()));
                  }
                } on FirebaseAuthException catch (e) {
                  print("Error: ${e.message}");
                  if (e.code == 'email-already-in-use') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User already exists')),
                    );
                  } else if (e.code == 'wrong-password' ||
                      e.code == 'user-not-found') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Invalid email or password')),
                    );
                  } else if (e.code == 'invalid-email') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('The email address is badly formatted')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Authentication failed: ${e.message}')),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      showLoading = false;
                    });
                  }
                }
              },
        padding: const EdgeInsets.symmetric(vertical: 13),
        minWidth: double.infinity,
        color: Colors.black,
        disabledColor: Colors.black45,
        textColor: gold,
        child: Text(
          loginScreenVisible ? 'Login' : 'Register',
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Future<String?> getUserTypeFromFirestore(String email) async {
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

  Widget toggleIconButton() {
    return InkWell(
      onTap: () {
        setState(() {
          loginScreenVisible = !loginScreenVisible;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        height: 50,
        width: 100,
        decoration: BoxDecoration(
            color: Colors.black54, borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            loginScreenVisible
                ? toggleButtonText()
                : Expanded(
                    child: Center(
                      child: Text(
                        'Login',
                        style: TextStyle(color: gold, fontSize: 11),
                      ),
                    ),
                  ),
            !loginScreenVisible
                ? toggleButtonText()
                : Expanded(
                    child: Center(
                      child: Text(
                        'Signup',
                        style: TextStyle(color: gold, fontSize: 11),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget toggleButtonText() {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: gold),
        child: Text(
          loginScreenVisible ? 'Login' : 'Signup',
          style: const TextStyle(color: Colors.black, fontSize: 11),
        ),
      ),
    );
  }
}
