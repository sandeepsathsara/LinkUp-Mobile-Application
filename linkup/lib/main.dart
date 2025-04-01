import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; // ✅ Add this import
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Set the Mapbox access token from --dart-define
  const accessToken = String.fromEnvironment("MAPBOX_ACCESS_TOKEN");
  if (accessToken.isEmpty) {
    throw Exception("MAPBOX_ACCESS_TOKEN not provided via --dart-define.");
  }
  MapboxOptions.setAccessToken(accessToken);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LinkUp',
      home: const SplashScreen(),
    );
  }
}
