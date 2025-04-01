import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'update_event_screen.dart'; // Contains EditEventScreen
import 'event_details_screen.dart'; // Contains EventDetailsScreen
import 'profile.dart';
import 'add_event.dart';

class OrganizerEventList extends StatefulWidget {
  const OrganizerEventList({Key? key}) : super(key: key);

  @override
  State<OrganizerEventList> createState() => _OrganizerEventListState();
}

class _OrganizerEventListState extends State<OrganizerEventList> {
  int _selectedIndex = 0; // Track selected tab
  User? _user;
  String? _profileImageUrl;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _loadCachedProfileImage().then((_) {
        // Display cached image immediately without loading spinner
        setState(() {
          _isLoadingProfile = false;
        });

        // Firestore fetch in background (optional update if needed)
        _fetchUserProfile();
      });
    } else {
      _isLoadingProfile = false;
    }
  }


  /// Loads a cached profile image URL from SharedPreferences, if any.
  Future<void> _loadCachedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('cachedProfileImageUrl');
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      setState(() {
        _profileImageUrl = cachedUrl;
      });
    }
  }

  /// Fetches the user profile from Firestore and caches the profile image URL.
  Future<void> _fetchUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('organizers') // FIXED: was 'users'
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final fetchedUrl = data['profileImageUrl'] ?? '';

        if (fetchedUrl.isNotEmpty && fetchedUrl != _profileImageUrl) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cachedProfileImageUrl', fetchedUrl);

          if (mounted) {
            setState(() {
              _profileImageUrl = fetchedUrl;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching organizer profile: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
      // Home tab, do nothing since we're already here.
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddEventScreen()),
        ).then((_) {
          setState(() {
            _selectedIndex = 0; // Reset to Home after adding an event.
          });
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        ).then((returnedIndex) {
          if (returnedIndex != null && returnedIndex is int) {
            setState(() {
              _selectedIndex = returnedIndex;
            });
          }
        });
        break;
    }
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event, String eventId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 2),
          ],
        ),
        child: Row(
          children: [
            // Event image – fallback to local asset if not provided.
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: event['imageUrl'] != null && (event['imageUrl'] as String).isNotEmpty
                  ? Image.network(
                event['imageUrl'],
                width: 120,
                height: 100,
                fit: BoxFit.cover,
              )
                  : Image.asset(
                'assets/march.png',
                width: 120,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['date'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      event['eventName'] ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditEventScreen(
                                  eventId: eventId,
                                  eventData: event,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteDialog(context, eventId);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'DELETE CONFIRMATION',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Text('ARE YOU SURE YOU WANT TO DELETE THIS EVENT?'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  ).then((returnedIndex) {
                    if (returnedIndex != null && returnedIndex is int) {
                      setState(() {
                        _selectedIndex = returnedIndex;
                      });
                    }
                  });
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? NetworkImage(_profileImageUrl!)
                      : const AssetImage('assets/profile.jpg') as ImageProvider,
                ),
              ),
            ),
          ],

        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Event List',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          // Display the user's profile image with caching logic.
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                ).then((returnedIndex) {
                  if (returnedIndex != null && returnedIndex is int) {
                    setState(() {
                      _selectedIndex = returnedIndex;
                    });
                  }
                });
              },
              child: _isLoadingProfile
                  ? const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/profile.jpg'),
              )
                  : CircleAvatar(
                radius: 18,
                backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                    ? NetworkImage(_profileImageUrl!)
                    : const AssetImage('assets/profile.jpg') as ImageProvider,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No events found."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final eventDoc = snapshot.data!.docs[index];
              final event = eventDoc.data() as Map<String, dynamic>;
              return _buildEventCard(context, event, eventDoc.id);
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, size: 40), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
