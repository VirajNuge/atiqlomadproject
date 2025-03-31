import 'package:firebase_core/firebase_core.dart'; // Firebase core import
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Firebase options for platform-specific initialization
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loginPage.dart'; // Import login page
import 'homeScreen.dart'; // Import home screen

// Cloudinary packages
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_flutter/image/cld_image.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';

void main() async {
  // Ensure Widgets are initialized before the app starts
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the platform-specific options from firebase_options.dart
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Cloudinary SDK
  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(
    cloudName: 'your_cloud_name',
  ); // Replace with your Cloud Name

  // Run the app once Firebase is initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthWrapper(), // Use AuthWrapper to check user login state
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream:
          FirebaseAuth.instance
              .authStateChanges(), // Check if user is logged in
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.hasData) {
          return const HomePage(); // If logged in, navigate to home page
        } else {
          return const LoginPage(); // If not logged in, navigate to login page
        }
      },
    );
  }
}
