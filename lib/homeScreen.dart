import 'package:flutter/material.dart';
import 'dart:ui';
import 'marketplace.dart';
import 'chatScreen.dart';
import 'orderScreen.dart';
import 'userProfile.dart';
import 'loginPage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore to fetch user data
import 'productPage.dart';
import 'dart:async';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'cartPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _getPostTime(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";

    Duration difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inDays > 0) {
      return "${difference.inDays} days ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hours ago";
    } else {
      return "Just now";
    }
  }

  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String selectedCategory = "";
  List<Map<String, dynamic>> cartItems = [];

  // Sign out the user and navigate to the login page
  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ), // Navigate back to login page
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser; // Get the current logged-in user

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
              Future.microtask(() {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              });
            },

            decoration: InputDecoration(
              hintText: "Search Product",
              hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black54,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Color(0xFF292B41)),
            onPressed: () {},
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
            // Auto-rotating banner gallery
            _buildBannerGallery(),

            const SizedBox(height: 15),

            // Scrollable Categories Section
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _categoryChip("Paintings"),
                  _categoryChip("Pottery"),
                  _categoryChip("Jewelry"),
                  _categoryChip("Handicrafts"),
                  _categoryChip("Furniture"),
                  _categoryChip("Textiles"),
                  _categoryChip("Calligraphy"),
                  _categoryChip("Organic Art"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recommended for You
            const Text(
              "Recommended for You",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF292B41),
              ),
            ),
            const SizedBox(height: 10),

            // Product Grid (Two Containers per Row)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    selectedCategory.isNotEmpty
                        ? FirebaseFirestore.instance
                            .collection('products')
                            .where('category', isEqualTo: selectedCategory)
                            .snapshots()
                        : FirebaseFirestore.instance
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
                        var data = doc.data() as Map<String, dynamic>?;

                        if (data == null)
                          return false; // Prevents null reference
                        if (!data.containsKey('name') || data['name'] == null)
                          return false;
                        if (!data.containsKey('userId') ||
                            data['userId'] == null)
                          return false;

                        // Apply search filter
                        if (searchQuery.isNotEmpty &&
                            !data['name'].toString().toLowerCase().contains(
                              searchQuery,
                            )) {
                          return false; // Exclude products that do not match the search query
                        }

                        return true; // Only valid products that match the search term
                      }).toList();

                  // ✅ Define products properly

                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.6,
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

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // The selected tab (start with 0 or change as needed)
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF292B41),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0, // Removes default shadow
        onTap: (index) {
          if (index == 1) {
            // Navigate to Marketplace screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Marketplace()),
            );
          } else if (index == 2) {
            // Navigate to Chat screen when 'Chat' tab is selected
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatScreen(), // Chat screen
              ),
            );
          } else if (index == 3) {
            // Navigate to Order Management when 'Orders' tab is selected
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => const OrderManagementPage(), // Orders screen
              ),
            );
          } else if (index == 4) {
            // Navigate to User Profile when 'Profile' tab is selected
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => const UserProfile(), // User Profile screen
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Market', // Link to Marketplace screen
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBannerGallery() {
    final PageController _pageController = PageController(initialPage: 0);
    int currentPage = 0;

    final List<String> bannerImages = [
      'assets/banneimg1.png',
      'assets/banneimg2.png',
      'assets/banneimg3.png',
      'assets/banneimg4.png',
    ];

    Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        if (currentPage < bannerImages.length - 1) {
          currentPage++;
        } else {
          currentPage = 0;
        }
        _pageController.animateToPage(
          currentPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: bannerImages.length,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  bannerImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SmoothPageIndicator(
          controller: _pageController,
          count: bannerImages.length,
          effect: WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Colors.blueAccent,
          ),
        ),
      ],
    );
  }

  // Scrollable Category Chip Widget
  Widget _categoryChip(String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              selectedCategory == label
                  ? Colors.blueAccent
                  : const Color(0xFFC5E4E6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color:
                selectedCategory == label
                    ? Colors.white
                    : const Color(0xFF292B41),
          ),
        ),
      ),
    );
  }

  // Product Card UI
  Widget _productCard(
    BuildContext context,
    Map<String, dynamic> data,
    String productId,
    String userId,
  ) {
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
          color: const Color(0xFFC5E4E6),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                image:
                    (data['Images'] != null &&
                            data['Images'] is List &&
                            data['Images'].isNotEmpty)
                        ? DecorationImage(
                          image: NetworkImage(data['Images'][0]),
                          fit: BoxFit.cover,
                        )
                        : const DecorationImage(
                          image: AssetImage('assets/placeholder.png'),
                          fit: BoxFit.cover,
                        ),
                borderRadius: BorderRadius.circular(15),
              ),
            ),

            const SizedBox(height: 8),

            // Product Name & Price
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

            // Seller Name (Fetched from Firestore)
            FutureBuilder<DocumentSnapshot?>(
              future:
                  (data.containsKey('userId') &&
                          data['userId'] != null &&
                          data['userId'].toString().isNotEmpty)
                      ? FirebaseFirestore.instance
                          .collection('sellers')
                          .doc(data['userId'])
                          .get()
                      : Future.value(null),
              builder: (context, snapshot) {
                String sellerName = "Unknown Seller";

                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data!.exists) {
                    var sellerData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    sellerName =
                        sellerData['companyName'] ??
                        sellerData['sellerName'] ??
                        "Unknown Seller";
                  }
                }

                return Text(
                  "by $sellerName",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                );
              },
            ),

            const Spacer(),

            // "Check Listing" Button
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

            const SizedBox(height: 5),

            // Wishlist & Post Date
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
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
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
                        setState(() {}); // Ensure UI updates
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
  }
}
