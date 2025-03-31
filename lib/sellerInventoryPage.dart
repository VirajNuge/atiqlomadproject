import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for fetching data
import 'marketplace.dart'; // Import the Marketplace screen
import 'chatScreen.dart'; // Import the Chat screen
import 'orderScreen.dart'; // Import the Order Management page
import 'userProfile.dart'; // Import the User Profile screen
import 'homeScreen.dart'; // Import the Home screen

class SellerInventoryPage extends StatefulWidget {
  const SellerInventoryPage({super.key});

  @override
  _SellerInventoryPageState createState() => _SellerInventoryPageState();
}

class _SellerInventoryPageState extends State<SellerInventoryPage> {
  List<Map<String, dynamic>> _products = [];
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  // Get the current user's ID from FirebaseAuth
  Future<void> _getUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      _fetchProducts(); // Fetch products once we have the user ID
    }
  }

  // Fetch the products for the logged-in seller from Firestore
  Future<void> _fetchProducts() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .where(
                'userId',
                isEqualTo: _userId,
              ) // Filter products by the logged-in user's ID
              .get();

      setState(() {
        _products =
            snapshot.docs.map((doc) {
              return {
                'product': doc['name'],
                'stock': doc['stockQuantity'],
                'id': doc.id, // Assuming each product has a unique ID
                'images': doc['Images'],
                'price': doc['price'],
              };
            }).toList();
      });
    } catch (e) {
      print("Error fetching products: $e");
    }
  }

  // Method to show the dialog to restock an item
  void _restockDialog(int index) {
    final TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restock Product'),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter the quantity to restock',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Restock the product in Firestore
                int quantityToAdd = int.tryParse(quantityController.text) ?? 0;
                if (quantityToAdd > 0) {
                  try {
                    // Update stock in Firestore
                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(_products[index]['id'])
                        .update({
                          'stockQuantity': FieldValue.increment(quantityToAdd),
                        });

                    setState(() {
                      _products[index]['stock'] += quantityToAdd;
                    });
                  } catch (e) {
                    print("Error updating stock: $e");
                  }
                }
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Restock'),
            ),
          ],
        );
      },
    );
  }

  // Method to update product price
  void _updatePriceDialog(int index) {
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Product Price'),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Enter the new price'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Get the new price from the input field
                double newPrice = double.tryParse(priceController.text) ?? 0.0;
                if (newPrice > 0) {
                  try {
                    // Update the price in Firestore
                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(_products[index]['id'])
                        .update({'price': newPrice});

                    setState(() {
                      _products[index]['price'] = newPrice;
                    });
                  } catch (e) {
                    print("Error updating price: $e");
                  }
                }
                Navigator.pop(context); // Close the dialog
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Method to remove a product from Firestore and the list
  void _removeProduct(int index) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(_products[index]['id'])
          .delete(); // Delete product from Firestore

      setState(() {
        _products.removeAt(index); // Remove the product from the list
      });
    } catch (e) {
      print("Error deleting product: $e");
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
          'Inventory Tracking',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF292B41),
          ),
        ),
      ),
      body:
          _products.isEmpty
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Show loading if no products
              : Column(
                children: [
                  // Inventory List
                  Expanded(
                    child: ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _products[index]['product'],
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF292B41),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Stock: ${_products[index]['stock']}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Color(0xFF292B41),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Price: \$${_products[index]['price']}',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Color(0xFF292B41),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    // Restock Button as Upward Arrow Icon
                                    IconButton(
                                      onPressed: () {
                                        _restockDialog(
                                          index,
                                        ); // Open Restock Dialog
                                      },
                                      icon: const Icon(
                                        Icons.arrow_upward,
                                        color: Color(0xFF292B41),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Update Price Button (using dollar icon)
                                    IconButton(
                                      onPressed: () {
                                        _updatePriceDialog(
                                          index,
                                        ); // Open Price Update Dialog
                                      },
                                      icon: const Icon(
                                        Icons.attach_money,
                                        color: Color(0xFF292B41),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Remove Product Button (using cross icon)
                                    IconButton(
                                      onPressed: () {
                                        _removeProduct(
                                          index,
                                        ); // Remove the product from Firestore and the list
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Assuming the current tab is Inventory (index 0)
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF292B41),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        onTap: (index) {
          // Handle bottom nav bar tab selection
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
