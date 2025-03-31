import 'package:flutter/material.dart';
import 'dart:async';
import 'homeScreen.dart'; // Import HomeScreen after login
import 'frontPage.dart'; // Import LoginPage if user is not logged in

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate a delay to show the splash screen for 3 seconds
    Timer(const Duration(seconds: 3), () {
      // Navigate to the HomePage after splash screen if needed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FrontPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 150,
          height: 150,
        ), // Splash screen logo
      ),
    );
  }
}
