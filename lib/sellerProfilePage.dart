import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'marketplace.dart';
import 'chatScreen.dart';
import 'orderScreen.dart';
import 'userProfile.dart';
import 'homeScreen.dart';
import 'productAddPage.dart';
import 'sellerOrderManagementPage.dart';
import 'sellerInventoryPage.dart';
import 'sellerEditPage.dart';

class SellerProfilePage extends StatelessWidget {
  const SellerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF292B41)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Seller Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF292B41),
          ),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance
                .collection('sellers')
                .doc(currentUser?.uid)
                .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Seller details not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Column(
            children: [
              // Profile Header Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      // Profile Image
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey,
                        backgroundImage:
                            data['profileImage'] != null &&
                                    data['profileImage'].toString().isNotEmpty
                                ? NetworkImage(data['profileImage'])
                                : const AssetImage("assets/default_profile.png")
                                    as ImageProvider,
                      ),
                      const SizedBox(height: 10),

                      // Seller Name
                      Text(
                        data['companyName'] ?? 'Unknown Seller',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF292B41),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Rating (Static for now)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.yellow, size: 20),
                          Text(
                            '4.8',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF292B41),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Location
                      Text(
                        'Location: ${data['location'] ?? "Unknown"}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFF292B41),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    _navButton(
                      context,
                      label: 'ADD NEW PRODUCT',
                      icon: Icons.add,
                      destination: const ProductAddPage(),
                    ),
                    const SizedBox(height: 20),
                    _navButton(
                      context,
                      label: 'ORDER MANAGEMENT',
                      icon: Icons.list_alt,
                      destination: const SellerOrderManagementPage(),
                    ),
                    const SizedBox(height: 20),
                    _navButton(
                      context,
                      label: 'INVENTORY TRACKING',
                      icon: Icons.track_changes,
                      destination: const SellerInventoryPage(),
                    ),
                    const SizedBox(height: 20),
                    _navButton(
                      context,
                      label: 'EDIT SELLER DETAILS',
                      icon: Icons.edit,
                      destination: const SellerEditPage(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF292B41),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        onTap: (index) {
          if (index == 1) {
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
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserProfile()),
            );
          } else if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // Reusable button builder
  Widget _navButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Widget destination,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF292B41),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
