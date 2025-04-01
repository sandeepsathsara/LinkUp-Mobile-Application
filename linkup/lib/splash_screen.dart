import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkup/welcome.dart';
import 'package:linkup/home_screen.dart';
import 'package:linkup/organizer/event.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), _checkLoginStatus);
  }

  Future<void> _checkLoginStatus() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        // Try checking in "organizers" collection first
        final orgSnap = await _firestore.collection("organizers").doc(user.uid).get();
        if (orgSnap.exists && orgSnap.data()?['role'] == 'organizer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OrganizerEventList()),
          );
          return;
        }

        // If not organizer, check in "users" (optional if you store user roles there)
        final userSnap = await _firestore.collection("users").doc(user.uid).get();
        if (userSnap.exists && userSnap.data()?['role'] == 'user') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          return;
        }

        // Default fallback to HomeScreen if no role found
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } catch (e) {
        debugPrint("Role check error: $e");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeToLinkUp()),
        );
      }
    } else {
      // Not logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeToLinkUp()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: const Center(
        child: Text(
          'LinkUp',
          style: TextStyle(
            fontSize: 40,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'YourCustomFont',
          ),
        ),
      ),
    );
  }
}
