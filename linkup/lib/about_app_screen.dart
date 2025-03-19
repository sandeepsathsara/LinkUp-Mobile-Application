import 'package:flutter/material.dart';
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
  int _currentIndex = 0; // Track the selected index

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Navigation logic
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ExplorePage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA), // Light background color
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Main Image Banner
            Image.asset(
              'assets/about.png',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),
            // Sections
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
      // Updated Bottom Navigation Bar
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
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // Helper function to create card sections
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
                  color: Colors.blue, // Change text color to blue
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
