import 'package:flutter/material.dart';

class SecurityHomePage extends StatefulWidget {
  const SecurityHomePage({super.key});

  @override
  State<SecurityHomePage> createState() => _SecurityHomePageState();
}

class _SecurityHomePageState extends State<SecurityHomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Text('Security HomePage'),
    );
  }
}
