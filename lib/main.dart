import 'package:firebase_core/firebase_core.dart'; // Firebase core import
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Firebase options for platform-specific initialization
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth
import 'loginPage.dart'; // Import login page
import 'homeScreen.dart'; // Import home screen
import 'frontPage.dart';

// Cloudinary packages
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_url_gen/cloudinary.dart';

void main() async {
  // Ensure Flutter engine and Firebase are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Cloudinary SDK
  CloudinaryContext.cloudinary = Cloudinary.fromCloudName(
    cloudName:
        'your_cloud_name', // <-- Replace with your actual Cloudinary cloud name
  );

  // Start the app
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
      home: AuthWrapper(), // Checks user login state
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Firebase Auth stream
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (snapshot.hasData) {
          return const HomePage(); // User is logged in
        } else {
          return const FrontPage(); // User not logged in
        }
      },
    );
  }
}
