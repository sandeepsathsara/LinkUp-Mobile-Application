import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkup/user/explore_screen.dart';
import 'package:linkup/user/home_screen.dart';
import 'package:linkup/user/profile_screen.dart';
import 'package:linkup/user/event_detail_screen.dart'; // Import Event Detail Screen

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final int _currentIndex = 3; // Active tab (Notifications)

  void _onTabTapped(int index) {
    if (index == _currentIndex) return; // Prevent duplicate navigation

    Widget destination;
    switch (index) {
      case 0:
        destination = const HomeScreen();
        break;
      case 1:
        destination = const ExplorePage();
        break;
      case 2:
        destination = const ExplorePage();
        break;
      case 4:
        destination = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  void _navigateToEventDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EventDetailScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: const CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage('assets/profile.jpg'),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView(
          children: [
            _buildNotificationCard(
              Icons.computer,
              "International Conference on Computer Systems Engineering and Technology",
            ),
            _buildNotificationCard(
              Icons.lightbulb,
              "AI and Machine Learning Summit 2025",
            ),
            _buildNotificationCard(
              Icons.security,
              "Cyber Security & Ethical Hacking Workshop",
            ),
            _buildNotificationCard(
              Icons.cloud,
              "Big Data and Cloud Computing Expo",
            ),
            _buildNotificationCard(
              Icons.device_hub,
              "IoT and Smart Devices Conference",
            ),
            _buildNotificationCard(
              Icons.currency_bitcoin,
              "Blockchain & Cryptocurrency Forum",
            ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(IconData icon, String eventTitle) {
    return GestureDetector(
      onTap: _navigateToEventDetail, // Navigate to Event Detail Screen on tap
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.blueAccent),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/notifi.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                eventTitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
