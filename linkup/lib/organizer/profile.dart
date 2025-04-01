import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linkup/welcome.dart';
import 'package:linkup/organizer/org_edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  String _orgName = "Organizer";
  String _email = "No email";
  String? _profileImageUrl;
  bool _isLoading = true;

  @override
  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _loadCachedImage().then((_) {
        // Immediately render UI if cache exists
        setState(() {
          _isLoading = false;
        });
        _fetchOrganizerInfo(); // Firestore fetch happens in background
      });
    } else {
      _isLoading = false;
    }
  }


  Future<void> _loadCachedImage() async {
    final prefs = await SharedPreferences.getInstance();

    final cachedUrl = prefs.getString('cachedProfileImageUrl');
    final cachedName = prefs.getString('cachedOrgName');
    final cachedEmail = prefs.getString('cachedEmail');

    setState(() {
      _profileImageUrl = cachedUrl;
      _orgName = cachedName ?? _orgName;
      _email = cachedEmail ?? _email;
    });
  }


  Future<void> _fetchOrganizerInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("organizers")
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final newName = data["orgName"] ?? _orgName;
        final newEmail = data["email"] ?? _email;
        final newUrl = data["profileImageUrl"] ?? _profileImageUrl;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("cachedOrgName", newName);
        await prefs.setString("cachedEmail", newEmail);
        if (newUrl != null) {
          await prefs.setString("cachedProfileImageUrl", newUrl);
        }

        setState(() {
          _orgName = newName;
          _email = newEmail;
          _profileImageUrl = newUrl;
        });
      }
    } catch (e) {
      debugPrint("Error fetching organizer info: $e");
    }
  }


  void _navigateToEditProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrgEditProfileScreen()),
    ).then((_) => _fetchOrganizerInfo());
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cachedProfileImageUrl');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeToLinkUp()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: ${e.toString()}")),
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, 0); // Return to previous screen with index 0
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, 0),
          ),
          title: const Text(
            'Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                    ? NetworkImage(_profileImageUrl!)
                    : const AssetImage('assets/profile.jpg') as ImageProvider,
                onBackgroundImageError: (_, __) {
                  setState(() {
                    _profileImageUrl = null;
                  });
                },
              ),
              const SizedBox(height: 15),
              Text(_orgName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(_email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profile'),
                onTap: () => _navigateToEditProfile(context),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () => _showLogoutDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
