import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:linkup/organizer/org_login.dart';
// Import the OrgLoginScreen

class WelcomeToLinkUp extends StatelessWidget {
  const WelcomeToLinkUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Colors.white], // Professional Blue
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // White Curved Section
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(80),
                  topRight: Radius.circular(80),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Join with us as a',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // User Button with Icon
                  _buildRoleButton(
                    context,
                    icon: Icons.person,
                    label: 'User',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        ),
                  ),

                  const SizedBox(height: 30),

                  // Organizer Button with Icon
                  // Organizer Button with Icon
                  _buildRoleButton(
                    context,
                    icon: Icons.business_center,
                    label: 'Organizer',
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OrgLoginScreen(),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),

          // Logo & Welcome Text
          Positioned(
            top: MediaQuery.of(context).size.height * 0.15,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // App Logo inside a Circle Avatar
                CircleAvatar(
                  radius: 50, // Adjust size as needed
                  backgroundColor:
                      Colors.white, // Background color for contrast
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png', // Add your logo image here
                      width: 90,
                      height: 90,
                      fit:
                          BoxFit
                              .cover, // Ensures the image fits within the circle
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Welcome Text
                const Text(
                  'Welcome to',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'LinkUp',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to create role selection buttons
  Widget _buildRoleButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Icon(icon, size: 60, color: Colors.blue.shade700),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(color: Colors.blue.shade700),
            ),
            elevation: 5,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
