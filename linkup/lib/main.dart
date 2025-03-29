import 'package:flutter/material.dart';
import 'user/splash_screen.dart';
// ✅ Import this file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LinkUp',
      home: SplashScreen(),
    );
  }
}
