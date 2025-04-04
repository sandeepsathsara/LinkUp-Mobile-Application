import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'explore_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  _AboutAppScreenState createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  int _currentIndex = 0;
  String? _profileImageUrl;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    String? cachedUrl = prefs.getString('cachedProfileImageUrl');

    // Use cached URL first
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      setState(() {
        _profileImageUrl = cachedUrl;
        _imageLoaded = true;
      });
    }

    // Then try to get latest from Firestore (but don’t block UI)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final newUrl = doc.data()?['profileImageUrl'];
        if (newUrl != null && newUrl != cachedUrl) {
          await prefs.setString('cachedProfileImageUrl', newUrl);
          if (mounted) {
            setState(() {
              _profileImageUrl = newUrl;
              _imageLoaded = true;
            });
          }
        }
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        break;
      case 1:
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ExplorePage()));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
        break;
      case 4:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'LinkUp',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              child: ClipOval(
                child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: _profileImageUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const CircularProgressIndicator(strokeWidth: 2),
                  errorWidget: (_, __, ___) => Image.asset('assets/profile.jpg', fit: BoxFit.cover),
                )
                    : Image.asset('assets/profile.jpg', width: 40, height: 40, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'assets/about.png',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            _buildCardSection(
              "Our Vision",
              "Our vision is to be the leading platform for discovering tech events in Sri Lanka. We aim to connect tech enthusiasts, professionals, and organizations, making it easy to stay informed, network, and grow in the industry.",
            ),
            _buildCardSection(
              "Our Mission",
              "Our mission is to provide a simple and reliable way for users to find and track tech events. Through real-time updates, location-based recommendations, and an easy-to-use app, we help people connect, learn, and advance their careers.",
            ),
            _buildCardSection(
              "Our Values",
              "We value innovation, using technology to make event discovery easy. Our community brings people together to learn and grow. We uphold integrity, ensuring trust and security. With a focus on excellence, we provide a seamless experience for finding and attending tech events.",
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        elevation: 5,
        type: BottomNavigationBarType.fixed,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildCardSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
