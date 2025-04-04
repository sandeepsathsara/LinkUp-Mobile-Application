import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'explore_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'u_event_details.dart';
import 'tech_dev_events_screen.dart';
import 'bus_net_events_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  User? _user;
  String? _profileImageUrl;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadCachedImage().then((_) => _loadUserProfileData());
  }

  Future<void> _loadCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('cachedProfileImageUrl');
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      setState(() {
        _profileImageUrl = cachedUrl;
        _isImageLoaded = true;
      });
    }
  }

  Future<void> _loadUserProfileData() async {
    try {
      if (_user == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final newUrl = data?['profileImageUrl'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cachedProfileImageUrl', newUrl);

        if (mounted && newUrl.isNotEmpty) {
          setState(() {
            _profileImageUrl = newUrl;
            _isImageLoaded = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      // Navigate to Explore (don’t change current index to avoid wrong highlight)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExplorePage()),
      ).then((returned) {
        // Always reset to Home tab after coming back
        if (mounted) {
          setState(() {
            _currentIndex = 0;
          });
        }
      });
    } else if (index == 2) {
      // Set active tab to Notifications during navigation
      setState(() {
        _currentIndex = 2;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      ).then((_) {
        if (mounted) {
          setState(() {
            _currentIndex = 0;
          });
        }
      });
    } else if (index == 3) {
      // Set active tab to Profile during navigation
      setState(() {
        _currentIndex = 3;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ).then((_) {
        if (mounted) {
          setState(() {
            _currentIndex = 0;
          });
        }
      });
    } else {
      // Home tab
      setState(() {
        _currentIndex = 0;
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildMostRecentEvent(),
              const SizedBox(height: 25),
              _buildCategories(),
              const SizedBox(height: 25),
              _buildFavoritesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Home",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          },
          child: _isImageLoaded && _profileImageUrl != null
              ? CircleAvatar(
            radius: 22,
            backgroundImage: CachedNetworkImageProvider(_profileImageUrl!),
          )
              : const CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage('assets/profile.jpg'),
          ),
        ),
      ],
    );
  }

  Widget _buildMostRecentEvent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Most Recent Event",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .orderBy('date', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text("No recent events available.");
            }

            final doc = snapshot.data!.docs.first;
            final data = doc.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserEventDetailsScreen(event: data),
                  ),
                );
              },
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(data['imageUrl'] ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(data['date'] ?? '', style: _eventCardTextStyle(14)),
                          const SizedBox(height: 4),
                          Text(
                            data['eventName'] ?? '',
                            style: _eventCardTextStyle(16, FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(data['venue'] ?? '', style: _eventCardTextStyle(12, FontWeight.normal, Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _buildEventCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UserEventDetailsScreen(event: {})));
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/march.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text("05 March 2025", style: _eventCardTextStyle(14)),
                  const SizedBox(height: 4),
                  Text(
                    "International Conference on Cloud Computing",
                    style: _eventCardTextStyle(16, FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text("Colombo, Sri Lanka", style: _eventCardTextStyle(12, FontWeight.normal, Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _eventCardTextStyle(double size, [FontWeight weight = FontWeight.w500, Color color = Colors.white]) {
    return GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color);
  }

  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Categories",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TechDevEventsScreen()),
                );
              },
              child: _buildCategoryTile("Tech & Development", 'assets/tech.png'),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BusinessNetworkingScreen()),
                );
              },
              child: _buildCategoryTile("Business & Networking", 'assets/data.png'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTile(String title, String assetPath) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.asset(assetPath, width: double.infinity, height: 90, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              title,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Events",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('favorites')
              .where('userId', isEqualTo: _user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final favs = snapshot.data?.docs ?? [];

            if (favs.isEmpty) {
              return const Text("You haven't added any favorite events yet.");
            }

            return Column(
              children: favs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildEventTile(data['title'] ?? '', data['date'] ?? '');
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEventTile(String title, String date) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UserEventDetailsScreen(event: {})));
      },
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/march.png', width: 55, height: 55, fit: BoxFit.cover),
          ),
          title: Text(date, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
          subtitle: Text(title, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
