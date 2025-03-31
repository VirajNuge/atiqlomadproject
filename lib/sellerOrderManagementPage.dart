import 'package:flutter/material.dart';
import 'marketplace.dart';
import 'chatScreen.dart';
import 'orderScreen.dart';
import 'userProfile.dart';
import 'homeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'messageScreen.dart';

class SellerOrderManagementPage extends StatefulWidget {
  const SellerOrderManagementPage({super.key});

  @override
  SellerOrderManagementPageState createState() =>
      SellerOrderManagementPageState();
}

class SellerOrderManagementPageState extends State<SellerOrderManagementPage> {
  final int _currentIndex = 3;
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF292B41)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Management',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF292B41),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTabs(),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance
                      .collection('orders')
                      .where(
                        'sellerId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                      )
                      .where(
                        'status',
                        isEqualTo: _getStatusFromTabIndex(_selectedTabIndex),
                      )
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No orders found."));
                }

                return ListView(
                  shrinkWrap: true,
                  children:
                      snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        data['orderId'] = doc.id; // Include document ID
                        return _buildOrderCard(data);
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
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
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Marketplace()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SellerOrderManagementPage(),
              ),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserProfile()),
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

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildTab('NEW ORDERS', 0),
        _buildTab('SHIPPED ORDERS', 1),
        _buildTab('COMPLETED ORDERS', 2),
      ],
    );
  }

  String _getStatusFromTabIndex(int index) {
    switch (index) {
      case 0:
        return 'new';
      case 1:
        return 'shipped';
      case 2:
        return 'completed';
      default:
        return 'new';
    }
  }

  Widget _buildTab(String label, int index) {
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color:
                  _selectedTabIndex == index
                      ? const Color(0xFF292B41)
                      : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color:
                _selectedTabIndex == index
                    ? const Color(0xFF292B41)
                    : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final item = (order['items'] as List).isNotEmpty ? order['items'][0] : {};
    final productName = item['name'] ?? 'Unknown';
    final orderId = order['orderId'] ?? 'Unknown';
    final buyer = order['buyerName'] ?? 'Unknown';
    final buyerId = order['buyerId'];
    final address = order['address'] ?? 'N/A';
    final totalPrice = order['totalPrice']?.toString() ?? '0.0';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ORDER $orderId',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF292B41),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'PRODUCT: $productName',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF292B41),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'BUYER: $buyer',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF292B41),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'ADDRESS: $address',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF292B41),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'TOTAL PRICE: $totalPrice',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF292B41),
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // ❌ Cancel Icon
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Cancel Order',
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('orders')
                          .doc(orderId)
                          .delete();
                    },
                  ),

                  // 💬 Chat Icon
                  IconButton(
                    icon: const Icon(Icons.message, color: Color(0xFF292B41)),
                    tooltip: 'Chat with Buyer',
                    onPressed: () {
                      final sellerId =
                          FirebaseAuth.instance.currentUser?.uid ?? "";

                      if (buyerId == null || buyerId == "") {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Buyer ID not available for chat."),
                          ),
                        );
                        return;
                      }

                      final chatId =
                          sellerId.compareTo(buyerId) < 0
                              ? "$sellerId-$buyerId"
                              : "$buyerId-$sellerId";

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => Messagescreen(
                                chatId: chatId,
                                otherUserId: buyerId,
                              ),
                        ),
                      );
                    },
                  ),

                  // 🚚 Shipped Icon
                  if (_getStatusFromTabIndex(_selectedTabIndex) == 'new')
                    IconButton(
                      icon: const Icon(
                        Icons.local_shipping,
                        color: Colors.green,
                      ),
                      tooltip: 'Mark as Shipped',
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('orders')
                            .doc(orderId)
                            .update({'status': 'shipped'});
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
