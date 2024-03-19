import 'package:flutter/material.dart';

import '../auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  Color gold = const Color(0xFFD7B504);

  String email = '';
  bool showLoading = false;

  // Regular expression for email validation
  RegExp emailRegex = RegExp(
    r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to black
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(21),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      color: Colors.white, // Set text color to white
                      fontWeight: FontWeight.w500,
                      fontSize: 21,
                    ),
                  ),
                  const SizedBox(
                    height: 11,
                  ),
                  const Text(
                    'Enter the email so we can send reset password option to it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(
                    height: 41,
                  ),
                  emailField(),
                  const SizedBox(
                    height: 11,
                  ),
                  sendVerificationEmailButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget emailField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          email = value;
        });
      },
      cursorColor: gold, // Set cursor color to gold
      style: const TextStyle(color: Colors.white), // Set text color to white
      decoration: InputDecoration(
        labelText: 'Enter email...',
        labelStyle: TextStyle(color: gold),
        filled: true,
        fillColor: Colors.black26,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(color: gold),
        ),
      ),
    );
  }

  Widget sendVerificationEmailButton(context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MaterialButton(
          onPressed: email.isEmpty || !emailRegex.hasMatch(email)
              ? null
              : () async {
                  setState(() {
                    showLoading = true;
                  });
                  AuthClass().sendVerificationEmail(email).then((value) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('Email sent'),
                      backgroundColor:
                          gold, // Set snackbar background color to gold
                    ));
                    setState(() {
                      showLoading = false;
                    });
                  });
                },
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          color: gold,
          disabledColor: Colors.grey,
          textColor: Colors.black, // Set text color to black
          child: showLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black, // Set loading indicator color to black
                  ),
                )
              : const Text('Send Verification Email'),
        ),
      ),
    );
  }
}
