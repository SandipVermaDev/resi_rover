import 'package:flutter/material.dart';

import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ChooseScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // You can change the color to your desired background color
          color: Colors.black,
        ),
        child: Center(
          child: Image.asset('assets/splash.gif'),
        ),
      ),
    );
  }
}
