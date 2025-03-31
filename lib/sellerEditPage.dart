import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'dart:io'; // For working with picked images
import 'package:http/http.dart' as http; // For HTTP requests to Cloudinary
import 'dart:convert'; // To decode the response
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth for user management
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for storing user data
import 'loginPage.dart'; // For navigating to login page if not authenticated

class SellerEditPage extends StatefulWidget {
  const SellerEditPage({super.key});

  @override
  _SellerEditPageState createState() => _SellerEditPageState();
}

class _SellerEditPageState extends State<SellerEditPage> {
  // Controllers for text fields
  final TextEditingController _sellerNameController = TextEditingController();
  final TextEditingController _sellerDescriptionController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();

  // Cloudinary details
  final String _cloudName = 'dfu4tb1t8'; // Cloud Name for Cloudinary
  final String _uploadPreset = 'atiqloimages'; // Upload preset for Cloudinary

  // Firebase Auth and Firestore instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userId = ''; // To store the user's UID
  String _imagePath = ''; // Placeholder for uploaded profile image

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getUserId(); // Get the user ID when the page loads
  }

  // Get the current user's ID from Firebase Authentication
  Future<void> _getUserId() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      _fetchSellerData(); // Fetch seller data once we have the user ID
    } else {
      // User is not logged in, navigate to login page
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  // Fetch seller data from Firestore
  Future<void> _fetchSellerData() async {
    try {
      // Fetch seller data from Firestore where the seller_id matches the Firebase UID
      QuerySnapshot sellerQuerySnapshot =
          await _firestore
              .collection('sellers')
              .where(
                'seller_id',
                isEqualTo: _userId,
              ) // Use seller_id instead of user_id
              .get();

      if (sellerQuerySnapshot.docs.isNotEmpty) {
        var sellerData =
            sellerQuerySnapshot.docs[0].data() as Map<String, dynamic>;

        // Populate the text controllers with the data fetched from Firestore
        _sellerNameController.text = sellerData['sellerName'] ?? '';
        _sellerDescriptionController.text =
            sellerData['sellerDescription'] ?? '';
        _locationController.text = sellerData['location'] ?? '';
        _contactController.text = sellerData['contact'] ?? '';
        _companyNameController.text = sellerData['companyName'] ?? '';
        _imagePath =
            sellerData['profileImage'] ?? ''; // Optional, profile image URL
      } else {
        print('Seller data not found for user: $_userId');
      }
    } catch (e) {
      print("Error fetching seller data: $e");
    }
  }

  // Method to pick and upload an image
  Future<void> _pickImage() async {
    XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File imageFile = File(image.path);

      // Upload the image to Cloudinary
      String? imageUrl = await _uploadImageToCloudinary(imageFile);
      if (imageUrl != null) {
        setState(() {
          _imagePath = imageUrl; // Save the uploaded image URL
        });
      }
    }
  }

  // Upload image to Cloudinary and return the image URL
  Future<String?> _uploadImageToCloudinary(File image) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/upload');

    final request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final result = json.decode(responseBody);

      if (response.statusCode == 200) {
        return result['secure_url']; // Return the uploaded image URL
      } else {
        print('Error uploading image: ${result['error']}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Update seller data in Firestore
  Future<void> _updateSellerData() async {
    if (_userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    try {
      await _firestore.collection('sellers').doc(_userId).update({
        'sellerName': _sellerNameController.text.trim(),
        'sellerDescription': _sellerDescriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'contact': _contactController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'profileImage': _imagePath, // Store the uploaded image URL
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print("Error updating seller profile: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Helper function to create text fields with optional parameters
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Color(0xFF292B41),
        ),
        filled: true,
        fillColor: Color(0xFFC5E4E6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF292B41)),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF292B41),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload Profile Picture Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5E4E6),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Icon(Icons.upload_file, size: 30, color: Color(0xFF292B41)),
                    const SizedBox(height: 10),
                    Text(
                      _imagePath.isEmpty
                          ? 'UPLOAD PROFILE PICTURE'
                          : 'PROFILE PICTURE UPLOADED',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF292B41),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Seller Name
            _buildTextField(
              label: 'Seller Name',
              controller: _sellerNameController,
            ),
            const SizedBox(height: 15),

            // Seller Description
            _buildTextField(
              label: 'Seller Description',
              controller: _sellerDescriptionController,
              maxLines: 4,
            ),
            const SizedBox(height: 15),

            // Location
            _buildTextField(label: 'Location', controller: _locationController),
            const SizedBox(height: 15),

            // Contact
            _buildTextField(label: 'Contact', controller: _contactController),
            const SizedBox(height: 15),

            // Company Name
            _buildTextField(
              label: 'Company Name',
              controller: _companyNameController,
            ),
            const SizedBox(height: 30),

            // Update Profile Button
            ElevatedButton(
              onPressed: _updateSellerData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF292B41),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'UPDATE PROFILE',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
