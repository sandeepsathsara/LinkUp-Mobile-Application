import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkup/explore_screen.dart';
import 'package:linkup/home_screen.dart'; // Ensure HomeScreen is imported
import 'package:linkup/profile_screen.dart'; // Import ProfileScreen (you need to create it)

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _currentIndex = 3; // Set Notification index as active

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notification",
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
                // Navigate to ProfileScreen when the avatar is clicked
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
        child: Column(
          children: [
            _buildNotificationCard(
              Icons.computer,
              "International Conference on Computer Systems Engineering and Technology",
            ),
            const SizedBox(height: 10),
            _buildNotificationCard(
              Icons.lightbulb,
              "AI and Machine Learning Summit 2025",
            ),
            const SizedBox(height: 10),
            _buildNotificationCard(
              Icons.security,
              "Cyber Security & Ethical Hacking Workshop",
            ),
            const SizedBox(height: 10),
            _buildNotificationCard(
              Icons.cloud,
              "Big Data and Cloud Computing Expo",
            ),
            const SizedBox(height: 10),
            _buildNotificationCard(
              Icons.device_hub,
              "IoT and Smart Devices Conference",
            ),
            const SizedBox(height: 10),
            _buildNotificationCard(
              Icons.currency_bitcoin,
              "Blockchain & Cryptocurrency Forum",
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor:
            Colors.blueAccent, // Active icon color (Notification is blue)
        unselectedItemColor: Colors.grey, // Other icons grey
        showUnselectedLabels: false,
        elevation: 5,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.notifications,
              color: Colors.blueAccent,
            ), // Blue Notification Icon
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExplorePage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildNotificationCard(IconData icon, String eventTitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 30,
            color: Colors.blueAccent,
          ), // Icon for Notification Type
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
    );
  }
}
