import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'productPage.dart';
import 'userProfile.dart';
import 'homeScreen.dart';
import 'orderScreen.dart';
import 'chatScreen.dart';
import 'wishlistPage.dart';
import 'cartPage.dart';

class Marketplace extends StatefulWidget {
  const Marketplace({super.key});

  @override
  _MarketplaceState createState() => _MarketplaceState();
}

class _MarketplaceState extends State<Marketplace> {
  double minPrice = 0;
  double maxPrice = 100000; // Default max price filter

  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFC5E4E6),
            borderRadius: BorderRadius.circular(45),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: "Search Product",
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black54,
              ),
              prefixIcon: Icon(Icons.search, color: Colors.black54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Color(0xFF292B41)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WishlistPage(userId: userId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Color(0xFF292B41)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price Range Slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Filter by Price:",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF292B41),
                  ),
                ),
                RangeSlider(
                  values: RangeValues(minPrice, maxPrice),
                  min: 0,
                  max: 100000,
                  divisions: 30,
                  labels: RangeLabels(
                    "\$${minPrice.toInt()}",
                    "\$${maxPrice.toInt()}",
                  ),
                  onChanged: (RangeValues values) {
                    setState(() {
                      minPrice = values.start;
                      maxPrice = values.end;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Fetch and Display Products with Price Filtering
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('products')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading products"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No products available"));
                  }

                  var products =
                      snapshot.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;

                        bool priceMatch = false;
                        if (data["price"] != null) {
                          try {
                            double productPrice = double.parse(
                              data["price"].toString(),
                            );
                            priceMatch =
                                productPrice >= minPrice &&
                                productPrice <= maxPrice;
                          } catch (e) {
                            priceMatch = false;
                          }
                        }

                        bool nameMatch =
                            data["name"] != null &&
                            data["name"].toString().toLowerCase().contains(
                              searchQuery,
                            );

                        return priceMatch && nameMatch;
                      }).toList();

                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.57,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      var product = products[index];
                      var data = product.data() as Map<String, dynamic>;

                      return _productCard(context, data, product.id, userId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

  // ✅ **Fixed Product Card UI with Clickable Check Listing**
  Widget _productCard(
    BuildContext context,
    Map<String, dynamic> data,
    String productId,
    String userId,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('sellers') // Fetch from sellers collection
              .doc(data['userId']) // Ensure this matches Firestore
              .get(),
      builder: (context, sellerSnapshot) {
        String sellerName = "Unknown Seller";

        if (sellerSnapshot.connectionState == ConnectionState.done) {
          if (sellerSnapshot.hasData && sellerSnapshot.data!.exists) {
            var sellerData =
                sellerSnapshot.data!.data() as Map<String, dynamic>;
            sellerName =
                sellerData['companyName'] ??
                sellerData['sellerName'] ??
                "Unknown Seller";
          } else {
            print("Seller not found for userId: ${data['userId']}");
          }
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        ProductPage(productId: productId, productData: data),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFC5E4E6), // Light cyan background
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ **Product Image**
                Container(
                  height: 140, // Image placeholder height
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image:
                        data['Images'] != null && data['Images'].isNotEmpty
                            ? DecorationImage(
                              image: NetworkImage(data['Images'][0]),
                              fit: BoxFit.cover,
                            )
                            : null,
                    color:
                        data['Images'] == null
                            ? const Color(0xFF292B41) // Dark placeholder
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),

                const SizedBox(height: 8),

                // ✅ **Product Name & Price**
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        data['name'] ?? 'Unknown Product',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF292B41),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "\$${data['price'] ?? 0}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF292B41),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // ✅ **Seller Name**
                Text(
                  "by $sellerName",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),

                const Spacer(), // Pushes everything up
                // ✅ **"Check Listing" Button**
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ProductPage(
                                productId: productId,
                                productData: data,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF292B41),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      "CHECK LISTING",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 5), // Adjust spacing
                // ✅ **Wishlist Heart & Post Date**
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "POSTED ${_getPostTime(data['createdAt'])}",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                    FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('wishlist')
                              .doc(productId)
                              .get(),
                      builder: (context, wishlistSnapshot) {
                        bool isWishlisted =
                            wishlistSnapshot.hasData &&
                            wishlistSnapshot.data!.exists;
                        return IconButton(
                          icon: Icon(
                            isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            if (isWishlisted) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .collection('wishlist')
                                  .doc(productId)
                                  .delete();
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .collection('wishlist')
                                  .doc(productId)
                                  .set({
                                    'productId': productId,
                                    'name': data['name'],
                                    'price': data['price'],
                                    'image':
                                        data['Images'] != null
                                            ? data['Images'][0]
                                            : '',
                                  });
                            }
                            setState(() {}); // ✅ Ensure UI updates
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ✅ **Helper function to format posted date**
  String _getPostTime(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    return "${DateTime.now().difference(timestamp.toDate()).inDays} days ago";
  }
}
