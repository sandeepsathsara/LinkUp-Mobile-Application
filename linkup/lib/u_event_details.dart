import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// In‑memory cache for the profile image URL.
class ProfileCache {
  static String? profileImageUrl;
  static bool initialized = false;
}

/// IMPORTANT: When passing the event to UserEventDetailsScreen, attach the document ID:
///   final doc = snapshot.data!.docs[index];
///   final event = doc.data() as Map<String, dynamic>;
///   event['id'] = doc.id; // ✅ This line is MANDATORY!

class UserEventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const UserEventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<UserEventDetailsScreen> createState() => _UserEventDetailsScreenState();
}

class _UserEventDetailsScreenState extends State<UserEventDetailsScreen> {
  User? _user;
  String? _profileImageUrl;
  bool _isLoadingProfile = true;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    // Immediately set the profile image if already in memory.
    if (ProfileCache.profileImageUrl != null) {
      _profileImageUrl = ProfileCache.profileImageUrl;
    }
    _loadProfileImage();
    if (_user != null) {
      _checkIfFavorite();
    } else {
      _isLoadingProfile = false;
    }
  }

  /// Optimized profile image loader.
  Future<void> _loadProfileImage() async {
    // ✅ If already loaded in memory, skip everything
    if (ProfileCache.initialized && ProfileCache.profileImageUrl != null) {
      setState(() {
        _profileImageUrl = ProfileCache.profileImageUrl;
        _isLoadingProfile = false;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? finalUrl = prefs.getString('cachedProfileImageUrl');

    // ✅ If not initialized, try to load from Firestore
    if (!ProfileCache.initialized && _user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        final firestoreUrl = doc.data()?['profileImageUrl'] as String?;
        if (firestoreUrl != null && firestoreUrl.isNotEmpty) {
          finalUrl = firestoreUrl;
          await prefs.setString('cachedProfileImageUrl', firestoreUrl);
        }
      }

      // ✅ Set in-memory cache after first fetch
      ProfileCache.initialized = true;
      ProfileCache.profileImageUrl = finalUrl;
    }

    // ✅ Final state update
    if (mounted) {
      setState(() {
        _profileImageUrl = finalUrl;
        _isLoadingProfile = false;
      });
    }
  }


  /// Checks if the current event is in the user's favourites.
  Future<void> _checkIfFavorite() async {
    final favDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('favorites')
        .doc(widget.event['id']) // Requires `id` field in event map
        .get();
    if (favDoc.exists) {
      setState(() {
        isFavorite = true;
      });
    }
  }

  /// Toggles the favourite state.
  Future<void> _toggleFavorite() async {
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .collection('favorites')
        .doc(widget.event['id']);

    try {
      if (isFavorite) {
        await favRef.delete();
      } else {
        await favRef.set({
          'eventId': widget.event['id'],
          'eventName': widget.event['eventName'],
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
      setState(() {
        isFavorite = !isFavorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isFavorite ? 'Added to favourites' : 'Removed from favourites'),
        ),
      );
    } catch (e) {
      debugPrint("Error toggling favourite: $e");
    }
  }

  /// Launches the registration link.
  Future<void> _launchRegistrationLink(String url) async {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    try {
      await launchUrlString(url);
    } catch (e) {
      debugPrint("Launch error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open registration link.")),
      );
    }
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  DateTime? _parseDate(String dateStr) {
    dateStr = dateStr.trim();
    if (RegExp(r'^\d{2}-\d{2}$').hasMatch(dateStr)) {
      final year = DateTime.now().year;
      final combined = '$year-$dateStr';
      try {
        return DateFormat('yyyy-MM-dd').parse(combined);
      } catch (_) {
        return null;
      }
    } else {
      try {
        return DateFormat('yyyy-MM-dd').parse(dateStr);
      } catch (_) {
        return null;
      }
    }
  }

  bool _isInThisMonth(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month;
  }

  /// Builds the profile image widget with smooth fade-in.
  Widget _buildProfileImage() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
          ? CircleAvatar(
        key: const ValueKey('network'),
        radius: 18,
        backgroundImage:
        CachedNetworkImageProvider(_profileImageUrl!),
      )
          : const CircleAvatar(
        key: ValueKey('asset'),
        radius: 18,
        backgroundImage: AssetImage('assets/profile.jpg'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final String eventName = event['eventName'] ?? 'No Title';
    final String date = event['date'] ?? 'No Date';
    final String time = event['time'] ?? '';
    final String venue = event['venue'] ?? 'No Venue';
    final String description =
        event['description'] ?? 'No description available.';
    final String payment = event['payment'] ?? 'Free';
    final String category = event['category'] ?? 'Uncategorized';
    final String? imageUrl = event['imageUrl'] as String?;
    final String? registerLink = event['registrationLink'] as String?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Event Details',
          style:
          TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: _isLoadingProfile
                ? const CircularProgressIndicator()
                : _buildProfileImage(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              )
                  : Image.asset(
                'assets/march.png',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 15),
            // Event title
            Text(
              eventName,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Date and time
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Colors.blue),
                const SizedBox(width: 5),
                Text(date, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 15),
                const Icon(Icons.access_time, size: 16, color: Colors.blue),
                const SizedBox(width: 5),
                Text(time, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            // Venue with map link
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 5),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue,
                          style: const TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward,
                            size: 18, color: Colors.black),
                        onPressed: () {
                          final location = widget.event['location'];
                          if (location != null && location is GeoPoint) {
                            final lat = location.latitude;
                            final lng = location.longitude;
                            final url =
                                'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                            launchUrlString(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Location coordinates not available.")),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Category
            Row(
              children: [
                const Icon(Icons.category, size: 16, color: Colors.orange),
                const SizedBox(width: 5),
                Text(category,
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 15),
            // About section
            const Text(
              'About',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 20),
            // Payment and Register button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(payment,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (registerLink != null && registerLink.isNotEmpty) {
                      _launchRegistrationLink(registerLink);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("No registration link available.")),
                      );
                    }
                  },
                  child: const Text('Register',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Favourite toggle button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color:
                    isFavorite ? Colors.red : Colors.grey[600],
                  ),
                  onPressed: _user != null ? _toggleFavorite : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
