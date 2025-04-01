import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkup/home_screen.dart';
import 'package:linkup/explore_screen.dart';
import 'package:linkup/notification_screen.dart';
import 'package:linkup/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'u_event_details.dart';

class FavouriteScreen extends StatefulWidget {
  const FavouriteScreen({super.key});

  @override
  State<FavouriteScreen> createState() => _FavouriteScreenState();
}

class _FavouriteScreenState extends State<FavouriteScreen> {
  final int _currentIndex = 2;
  String? _profileImageUrl;
  bool _isLoading = true;
  List<Map<String, dynamic>> _favorites = [];
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _fetchFavorites();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('cachedProfileImageUrl');
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      setState(() {
        _profileImageUrl = cachedUrl;
      });
    }
    if (_user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['profileImageUrl'] != null) {
          await prefs.setString('cachedProfileImageUrl', data['profileImageUrl']);
          setState(() {
            _profileImageUrl = data['profileImageUrl'];
          });
        }
      }
    }
  }

  Future<void> _fetchFavorites() async {
    if (_user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .get();

    final List<Map<String, dynamic>> favs = [];
    for (final doc in snapshot.docs) {
      final favData = doc.data();
      final eventId = favData['eventId'];
      if (eventId != null) {
        final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
        if (eventDoc.exists) {
          final eventData = eventDoc.data()!;
          eventData['id'] = eventDoc.id;
          favs.add(eventData);
        }
      }
    }

    setState(() {
      _favorites = favs;
      _isLoading = false;
    });
  }

  Future<void> _removeFromFavorites(String eventId) async {
    if (_user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('favorites')
        .doc(eventId)
        .delete();

    setState(() {
      _favorites.removeWhere((event) => event['id'] == eventId);
    });
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
        destination = const NotificationScreen();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Favorites",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? NetworkImage(_profileImageUrl!)
                  : const AssetImage('assets/profile.jpg') as ImageProvider,
            ),
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
          ? const Center(child: Text("No favorite events yet."))
          : ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final event = _favorites[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserEventDetailsScreen(event: event),
                ),
              );
            },
            child: _buildFavoriteEventCard(event),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildFavoriteEventCard(Map<String, dynamic> event) {
    final String name = event['eventName'] ?? 'No Title';
    final String date = event['date'] ?? 'No Date';
    final String venue = event['venue'] ?? 'No Venue';
    final String? imageUrl = event['imageUrl'];
    final String eventId = event['id'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/march.png',
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
              ),
            )
                : Image.asset(
              'assets/march.png',
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  venue,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => _removeFromFavorites(eventId),
            ),
          ),
        ],
      ),
    );
  }
}