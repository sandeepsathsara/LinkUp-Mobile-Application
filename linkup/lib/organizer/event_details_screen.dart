import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
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

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final String eventName = event['eventName'] ?? 'No Title';
    final String date = event['date'] ?? 'No Date';
    final String time = event['time'] ?? '';
    final String venue = event['venue'] ?? 'No Venue';
    final String description = event['description'] ?? 'No description available.';
    final String payment = event['payment'] ?? 'Free';
    final String category = event['category'] ?? 'Uncategorized';
    final String? imageUrl = event['imageUrl'] as String?;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Event Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: _isImageLoaded && _profileImageUrl != null
                ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: _profileImageUrl!,
                width: 35,
                height: 35,
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircleAvatar(
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
                errorWidget: (context, url, error) => const CircleAvatar(
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
              ),
            )
                : const CircleAvatar(
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) =>
                    Image.asset('assets/march.png', width: double.infinity, height: 200, fit: BoxFit.cover),
              )
                  : Image.asset(
                'assets/march.png',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 15),
            Text(eventName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                const SizedBox(width: 5),
                Text(date, style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 15),
                const Icon(Icons.access_time, size: 16, color: Colors.blue),
                const SizedBox(width: 5),
                Text(time, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 5),
                Expanded(child: Text(venue, style: const TextStyle(color: Colors.grey))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.category, size: 16, color: Colors.orange),
                const SizedBox(width: 5),
                Text(category, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 15),
            const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(description, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(payment, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // Registration logic here
                  },
                  child: const Text('Register', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
