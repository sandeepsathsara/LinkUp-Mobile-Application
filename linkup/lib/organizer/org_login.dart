import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:linkup/forgot_password_screen.dart';
import 'org_singup.dart';
import 'event.dart';

class OrgLoginScreen extends StatefulWidget {
  const OrgLoginScreen({super.key});

  @override
  State<OrgLoginScreen> createState() => _OrgLoginScreenState();
}

class _OrgLoginScreenState extends State<OrgLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool isLoading = false;

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void loginOrganizer() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showSnackbar("Please fill all fields");
      return;
    }

    try {
      setState(() => isLoading = true);
      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final userDoc = await FirebaseFirestore.instance
          .collection("organizers")
          .doc(credential.user!.uid)
          .get();

      if (userDoc.exists) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const OrganizerEventList()),
              (route) => false,
        );
      } else {
        showSnackbar("Not authorized as an organizer.");
        FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      showSnackbar(e.message ?? "Login failed. Try again.");
    } catch (e) {
      showSnackbar("Something went wrong. Try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Stack(
          children: [
            // Background
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(110),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  'Welcome Organizer!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/logo.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 160),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email),
                          labelText: 'Email',
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            );
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: isLoading ? null : loginOrganizer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 80,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 500),
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                  const OrgSignupPage(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                ),
                              );
                            },
                            child: Text(
                              "Sign up.",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
