import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'loginPage.dart';
import 'marketplace.dart';
import 'chatScreen.dart';
import 'homeScreen.dart';
import 'orderScreen.dart';
import 'sellerProfilePage.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String firstName = "Loading...";
  String lastName = "";
  String email = "";
  String phone = "";
  String profileImage = "";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          setState(() {
            firstName = userDoc['first_name'] ?? "No Name";
            lastName = userDoc['last_name'] ?? "";
            email = userDoc['email'] ?? "";
            phone = userDoc['phone'] ?? "";
            profileImage = userDoc['profileImage'] ?? "";
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    String cloudinaryUrl = await _uploadToCloudinary(imageFile);

    if (cloudinaryUrl.isNotEmpty) {
      await _updateUserProfileImage(cloudinaryUrl);
    }
  }

  Future<String> _uploadToCloudinary(File imageFile) async {
    try {
      const String cloudinaryUploadUrl =
          "https://api.cloudinary.com/v1_1/dfu4tb1t8/upload";
      const String cloudinaryPreset = "atiqloimages";

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(cloudinaryUploadUrl),
      );
      request.fields['upload_preset'] = cloudinaryPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'];
      } else {
        print("Cloudinary upload failed: ${response.statusCode}");
        return "";
      }
    } catch (e) {
      print("Error uploading image to Cloudinary: $e");
      return "";
    }
  }

  Future<void> _updateUserProfileImage(String imageUrl) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String uid = user.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImage': imageUrl,
      });

      setState(() {
        profileImage = imageUrl;
      });

      print("Profile image updated successfully!");
    } catch (e) {
      print("Error updating profile image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            color: Color(0xFF292B41),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF292B41)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SellerProfilePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF292B41),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: const Text(
                "Switch to Selling",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            GestureDetector(
              onTap: _uploadProfilePicture,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF292B41),
                backgroundImage:
                    (profileImage.isNotEmpty &&
                            Uri.tryParse(profileImage)?.hasAbsolutePath == true)
                        ? NetworkImage(profileImage)
                        : const AssetImage("assets/default_profile.png")
                            as ImageProvider,
                child:
                    (profileImage.isEmpty)
                        ? const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 30,
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "$firstName $lastName",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292B41),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 User Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.email, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            phone,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Action Buttons
            _profileOptionButton("CHECK CART", Icons.shopping_cart),
            _profileOptionButton("MY WISHLIST", Icons.favorite_border),
            _profileOptionButton("MY REVIEWS", Icons.rate_review),

            const SizedBox(height: 20),

            // 🔹 Logout Button
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),

      // 🔹 Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF292B41),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Marketplace()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderManagementPage(),
              ),
            );
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // 🔹 Reusable Button Widget
  Widget _profileOptionButton(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          // Add functionality here
        },
        icon: Icon(icon, color: const Color(0xFF292B41)),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF292B41),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: Color(0xFF292B41), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
