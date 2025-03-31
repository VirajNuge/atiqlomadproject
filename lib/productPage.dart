import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sellerProfile.dart';
import 'marketplace.dart';
import 'chatScreen.dart';
import 'orderScreen.dart';
import 'userProfile.dart';
import 'homeScreen.dart';
import 'cartPage.dart';
import 'checkoutPage.dart';

class ProductPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ProductPage({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late String selectedImage;

  @override
  void initState() {
    super.initState();
    selectedImage =
        (widget.productData['Images'] != null &&
                widget.productData['Images'].isNotEmpty)
            ? widget.productData['Images'][0]
            : "";
  }

  void _buyNow(Map<String, dynamic> productData) {
    print("Proceeding to checkout with product: ${productData['name']}");
  }

  void _addToCart(Map<String, dynamic> productData) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to add to cart")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .add({
            'item': productData['name'],
            'price': productData['price'],
            'image':
                productData['Images'] != null &&
                        productData['Images'].isNotEmpty
                    ? productData['Images'][0]
                    : 'https://via.placeholder.com/60',
            'productId': widget.productId,
            'quantity': 1,
            'timestamp': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Item added to cart")));
    } catch (e) {
      print("Error adding to cart: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<String> _fetchCompanyName(String userId) async {
    try {
      DocumentSnapshot sellerDoc =
          await FirebaseFirestore.instance
              .collection('sellers')
              .doc(userId)
              .get();
      if (sellerDoc.exists) {
        return sellerDoc['companyName'] ?? 'Unknown Company';
      }
    } catch (e) {
      print("Error fetching company name: $e");
    }
    return 'Unknown Company';
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Product Image
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                image:
                    selectedImage.isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(selectedImage),
                          fit: BoxFit.cover,
                        )
                        : null,
                color:
                    selectedImage.isEmpty
                        ? const Color(0xFF292B41)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 10),

            // Image Gallery
            if (widget.productData['Images'] != null &&
                widget.productData['Images'].isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(widget.productData['Images'].length, (
                    index,
                  ) {
                    String imageUrl = widget.productData['Images'][index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedImage = imageUrl;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(
                            color:
                                selectedImage == imageUrl
                                    ? Colors.blue
                                    : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            const SizedBox(height: 20),

            // Product Info
            Text(
              widget.productData['name'] ?? 'Unknown Product',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292B41),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "\$${widget.productData['price'] ?? 0}",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292B41),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.productData['description'] ?? "No description available",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFF292B41),
              ),
            ),
            const SizedBox(height: 20),

            // Stock
            Text(
              "Stock Status: ${widget.productData['stockQuantity'] ?? 'Unknown'} left in stock",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),

            // Seller Info
            FutureBuilder<String>(
              future: _fetchCompanyName(widget.productData['userId']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF292B41),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "SOLD BY: ${snapshot.data}",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF292B41),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => SellerProfile(
                                      sellerId: widget.productData['userId'],
                                    ),
                              ),
                            );
                          },
                          child: const Text(
                            "View Seller's Page",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: Color(0xFF292B41),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 20),

            // Shipping Details
            const Text(
              "Shipping Details:",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292B41),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.productData['shippingDetails'] ??
                  "- Ships within 2-3 days\n- Free returns within 7 days",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFF292B41),
              ),
            ),
            const SizedBox(height: 30),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _addToCart(widget.productData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5E4E6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    "ADD TO CART",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF292B41),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (widget.productData['userId'] == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Error: Seller ID is missing!"),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => CheckoutPage(
                              productData: widget.productData,
                              sellerId: widget.productData['userId'],
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF292B41),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    "BUY NOW",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
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
}
