import 'package:flutter/material.dart';
import 'dart:async';

import 'package:linkup/welcome.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeToLinkUp()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: Center(
        child: Text(
          'LinkUp',
          style: TextStyle(
            fontSize: 40,
            color: Colors.white,
            fontFamily: 'YourCustomFont', // Add custom font if needed
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
