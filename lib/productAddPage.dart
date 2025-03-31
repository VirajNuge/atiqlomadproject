import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'dart:io'; // For working with the picked images
import 'package:http/http.dart' as http; // For HTTP requests to Cloudinary
import 'dart:convert'; // To decode the response
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth to get user ID
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for storing product data

class ProductAddPage extends StatefulWidget {
  const ProductAddPage({super.key});

  @override
  _ProductAddPageState createState() => _ProductAddPageState();
}

class _ProductAddPageState extends State<ProductAddPage> {
  // Controllers for text fields
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productDescriptionController =
      TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockQuantityController =
      TextEditingController();
  final TextEditingController _shippingDetailsController =
      TextEditingController();
  final TextEditingController _categoryController = TextEditingController(
    text: '',
  );

  // List to store selected images
  List<File?> _imageFiles = [];

  final ImagePicker _picker = ImagePicker(); // Image picker instance
  bool _isUploading = false;

  // Cloudinary details
  final String _cloudName = 'dfu4tb1t8'; // Use your correct Cloud Name
  final String _apiKey = '578735723339169'; // Your Cloudinary API Key
  final String _apiSecret = 'a1uoOsdFPmvxu5AcAdCap3p2wqk';
  final String _uploadPreset = 'atiqloimages'; // Use your correct Upload Preset

  // Form Key
  final _formKey = GlobalKey<FormState>();

  // Pick multiple images from gallery
  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.length <= 7) {
      setState(() {
        _imageFiles = pickedFiles.map((file) => File(file.path)).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only upload a maximum of 7 images'),
        ),
      );
    }
  }

  // Upload the images to Cloudinary
  Future<List<String?>> _uploadImagesToCloudinary(List<File> images) async {
    List<String?> imageUrls = [];

    for (var image in images) {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/upload', // Correct upload path
      );

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] =
          _uploadPreset; // Using your upload preset
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      try {
        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        final result = json.decode(responseBody);

        if (response.statusCode == 200) {
          imageUrls.add(result['secure_url']); // Store the uploaded image URL
          print('Uploaded image: ${result['secure_url']}');
        } else {
          print('Error uploading image: ${result['error']}');
          imageUrls.add(null); // If upload fails, store null
        }
      } catch (e) {
        print('Error uploading image: $e');
        imageUrls.add(null); // If exception occurs, store null
      }
    }

    return imageUrls; // Return list of uploaded image URLs
  }

  // Add the product details to Firestore
  Future<void> _addProductToFirestore(List<String> imageUrls) async {
    final User? user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId == null) {
      print('User is not authenticated');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
      return;
    }

    try {
      // Add product data to Firestore
      await FirebaseFirestore.instance.collection('products').add({
        'name': _productNameController.text.trim(),
        'description': _productDescriptionController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'category': _categoryController.text.trim(),
        'stockQuantity': int.tryParse(_stockQuantityController.text) ?? 0,
        'shippingDetails': _shippingDetailsController.text.trim(),
        'Images': imageUrls, // Store all valid image URLs in the 'Images' field
        'userId': userId, // Store the user ID who uploaded the product
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('Product added successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product successfully added!')),
      );

      // Clear form fields after successful upload
      _productNameController.clear();
      _productDescriptionController.clear();
      _priceController.clear();
      _categoryController.clear();
      _stockQuantityController.clear();
      _shippingDetailsController.clear();
      setState(() {
        _imageFiles.clear();
      });
    } catch (e) {
      print('Error adding product to Firestore: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error adding product')));
    }
  }

  // Publish the product
  Future<void> _publishProduct() async {
    // Ensure form is valid and there are images selected
    if (!_formKey.currentState!.validate() || _imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select images'),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Upload images to Cloudinary
    final imageUrls = await _uploadImagesToCloudinary(
      _imageFiles.where((image) => image != null).cast<File>().toList(),
    );

    // Filter out any null image URLs
    final validImageUrls = imageUrls.whereType<String>().toList();

    // Check if Cloudinary upload was successful
    if (validImageUrls.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error uploading images')));
      setState(() {
        _isUploading = false;
      });
      return;
    }

    try {
      // Ensure the user is authenticated
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Add product data to Firestore
      await _addProductToFirestore(validImageUrls);

      setState(() {
        _isUploading = false;
      });
    } catch (e) {
      print('Error during product publish: $e');
      setState(() {
        _isUploading = false;
      });
    }
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
          'Add Product',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF292B41),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Section
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Color(0xFFC5E4E6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _imageFiles.isEmpty ? Icons.upload_file : Icons.image,
                        size: 30,
                        color: Color(0xFF292B41),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _imageFiles.isEmpty
                            ? 'UPLOAD IMAGE (MAX 7)'
                            : '${_imageFiles.length} IMAGE(S) SELECTED',
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
              // Product Name, Description, Price, Category, Stock Quantity, Shipping Details Text Fields
              _buildTextField('Product Name', _productNameController),
              const SizedBox(height: 15),
              _buildTextField(
                'Product Description',
                _productDescriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: 15),
              _buildTextField('Price', _priceController),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value:
                    _categoryController.text.isEmpty
                        ? null
                        : _categoryController.text,
                decoration: InputDecoration(
                  labelText: 'Category',
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
                items:
                    [
                      'Paintings',
                      'Pottery',
                      'Jewelry',
                      'Handicrafts',
                      'Furniture',
                      'Textiles',
                      'Calligraphy',
                      'Organic Art',
                    ].map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryController.text = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Category is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),
              _buildTextField('Stock Quantity', _stockQuantityController),
              const SizedBox(height: 15),
              _buildTextField('Shipping Details', _shippingDetailsController),
              const SizedBox(height: 30),
              // Publish Product Button
              ElevatedButton(
                onPressed: _isUploading ? null : _publishProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF292B41),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'PUBLISH PRODUCT',
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
      ),
    );
  }

  // Helper function to create text fields with optional parameters
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label is required';
        }
        return null;
      },
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
}
