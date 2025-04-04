import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkup/explore_screen.dart';
import 'package:linkup/home_screen.dart';
import 'package:linkup/notification_screen.dart';
import 'package:linkup/edit_profile_screen.dart';
import 'package:linkup/about_app_screen.dart';
import 'package:linkup/favourite_screen.dart';
import 'package:linkup/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:linkup/my_profile_screen.dart';

// Simple in-memory cache for the profile image URL
class ProfileCache {
  static String? profileImageUrl;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 4;
  User? _user;
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isImageReady = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadCachedImage().then((_) {
      // Only fetch from Firebase if there is no in-memory cache
      if (ProfileCache.profileImageUrl == null) {
        _loadUserProfileData();
      } else {
        _profileImageUrl = ProfileCache.profileImageUrl;
        setState(() {
          _isImageReady = true;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _loadCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('cachedProfileImageUrl');

    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      _profileImageUrl = cachedUrl;
      ProfileCache.profileImageUrl = cachedUrl;
      _isImageReady = true;
    }
  }

  Future<void> _loadUserProfileData() async {
    try {
      if (_user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final newUrl = data?['profileImageUrl'] ?? '';

        // If the URL has changed or wasn't cached yet, update both SharedPreferences and our in-memory cache
        if (_profileImageUrl != newUrl) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cachedProfileImageUrl', newUrl);
          _profileImageUrl = newUrl;
          ProfileCache.profileImageUrl = newUrl;
        }

        setState(() {
          _isImageReady = true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = _user?.displayName ?? 'Your Name';
    String email = _user?.email ?? 'your@email.com';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Profile",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Display the profile card only when the image is ready
              if (_isImageReady)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(_profileImageUrl!)
                            : const AssetImage('assets/profile.jpg') as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                          // Refresh cache after editing profile
                          await _loadCachedImage();
                          setState(() {});
                        },
                        icon: const Icon(Icons.edit, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              if (!_isImageReady)
                const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 30),
              _sectionTitle("Account"),
              const SizedBox(height: 10),
              _buildSectionCard([
                _buildListTile(Icons.person_outline, "My Account", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyProfileScreen()),
                  );
                }),
                _buildListTile(Icons.favorite_border, "Favorites", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FavouriteScreen()),
                  );
                }),
                _buildListTile(Icons.logout, "Log out", () async {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('cachedProfileImageUrl');
                  ProfileCache.profileImageUrl = null;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const SplashScreen()),
                        (route) => false,
                  );
                }),
              ]),
              const SizedBox(height: 30),
              _sectionTitle("More"),
              const SizedBox(height: 10),
              _buildSectionCard([
                _buildListTile(Icons.info_outline, "About App", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutAppScreen()),
                  );
                }),
              ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Correct: Profile is at index 3 now (0 = Home, 1 = Explore, 2 = Alerts, 3 = Profile)
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 5,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ExplorePage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            );
          } // index 3 is Profile - stay here
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.blueAccent, size: 26),
          title: Text(
            title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: onTap,
        ),
        const Divider(height: 1, thickness: 0.8, indent: 16, endIndent: 16),
      ],
    );
  }
}
