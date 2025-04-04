import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'home_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
import 'u_event_details.dart';

/// Profile image in-memory cache
class ProfileCache {
  static String? profileImageUrl;
}

/// Event image in-memory cache
class EventImageCache {
  static final Map<String, CachedNetworkImageProvider> cache = {};
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final int _currentIndex = 2;
  User? _user;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadCachedProfileImage();
  }

  Future<void> _loadCachedProfileImage() async {
    // Use in-memory cache if available.
    if (ProfileCache.profileImageUrl != null) {
      setState(() {
        _profileImageUrl = ProfileCache.profileImageUrl;
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('cachedProfileImageUrl');
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      ProfileCache.profileImageUrl = cachedUrl;
      setState(() => _profileImageUrl = cachedUrl);
    } else if (_user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      final url = doc.data()?['profileImageUrl'] ?? '';
      if (url.isNotEmpty) {
        await prefs.setString('cachedProfileImageUrl', url);
        ProfileCache.profileImageUrl = url;
        setState(() => _profileImageUrl = url);
      }
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const HomeScreen();
        break;
      case 1:
        destination = const ExplorePage();
        break;
      case 2:
        return;
      case 3:
        destination = const ProfileScreen();
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _navigateToEventDetails(Map<String, dynamic> eventData) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => UserEventDetailsScreen(event: eventData)),
    );
  }

  /// Deletes a notification document from Firestore.
  Future<void> _deleteNotification(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notification deleted")),
      );
    } catch (e) {
      debugPrint("Error deleting notification: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete notification")),
      );
    }
  }

  /// Marks a notification as read by updating its 'read' field in Firestore.
  Future<void> _markNotificationAsRead(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .update({'read': true});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notification marked as read")),
      );
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to mark as read")),
      );
    }
  }

  Widget _buildNotificationCard(Map<String, dynamic> data, String docId) {
    final String title = data['title'] ?? 'Event Update';
    final IconData icon = _getIcon(data['category']);
    final Map<String, dynamic> event = data['event'] ?? {};
    final bool isRead = data['read'] ?? false;
    final String? imageUrl = event['imageUrl'];

    ImageProvider imageProvider;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (EventImageCache.cache.containsKey(imageUrl)) {
        imageProvider = EventImageCache.cache[imageUrl]!;
      } else {
        final cached = CachedNetworkImageProvider(imageUrl);
        EventImageCache.cache[imageUrl] = cached;
        imageProvider = cached;
      }
    } else {
      imageProvider = const AssetImage('assets/notifi.png');
    }

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(docId),
      child: GestureDetector(
        onTap: () => _navigateToEventDetails(event),
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
                child: Image(
                  image: imageProvider,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (!isRead)
                      TextButton.icon(
                        onPressed: () => _markNotificationAsRead(docId),
                        icon: const Icon(Icons.mark_email_read, size: 16),
                        label: const Text(
                          "Mark as read",
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String? category) {
    switch (category) {
      case 'Tech & Development':
        return Icons.computer;
      case 'Business & Networking':
        return Icons.business_center;
      case 'Security':
        return Icons.security;
      default:
        return Icons.event;
    }
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
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 22,
                backgroundImage: _profileImageUrl != null &&
                    _profileImageUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(_profileImageUrl!)
                    : const AssetImage('assets/profile.jpg') as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("No notifications yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              return _buildNotificationCard(data, docId);
            },
          );
        },
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
          BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
