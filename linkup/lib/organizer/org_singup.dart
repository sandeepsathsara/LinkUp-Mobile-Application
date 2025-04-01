import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:linkup/organizer/event.dart';

class OrgSignupPage extends StatefulWidget {
  const OrgSignupPage({super.key});

  @override
  State<OrgSignupPage> createState() => _OrgSignupPageState();
}

class _OrgSignupPageState extends State<OrgSignupPage> {
  final orgNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> signUpOrganizer() async {
    final orgName = orgNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (orgName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showSnackbar("Please fill in all fields.");
      return;
    }

    if (password != confirmPassword) {
      showSnackbar("Passwords do not match.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection("organizers").doc(user.uid).set({
          "uid": user.uid,
          "orgName": orgName,
          "email": email,
          "role": "organizer",
          "createdAt": FieldValue.serverTimestamp(),
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrganizerEventList()),
        );
      }
    } on FirebaseAuthException catch (e) {
      showSnackbar(e.message ?? "Signup failed.");
    } catch (e) {
      debugPrint("Signup error: $e");
      showSnackbar("Unexpected error occurred.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 🔵 Top Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(110),
                ),
              ),
            ),
          ),

          // 🧾 Form
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                children: [
                  const SizedBox(height: 40),
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
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('assets/logo.png'),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 📄 Input Fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        TextField(
                          controller: orgNameController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.business),
                            labelText: 'Organization Name',
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            labelText: 'Email',
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => obscurePassword = !obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            labelText: 'Confirm Password',
                            suffixIcon: IconButton(
                              icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),

                        // ✅ Signup Button
                        ElevatedButton(
                          onPressed: isLoading ? null : signUpOrganizer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            'Sign up',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 🔁 Sign in
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? "),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                "Sign in.",
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
