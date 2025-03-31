import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'homeScreen.dart';
import 'marketplace.dart';
import 'chatScreen.dart';
import 'userProfile.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  String selectedStatus = 'new'; // Default tab: new orders

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
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
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // 🔁 Tab Selection
            Row(
              children: [
                _tabButton("New Orders", 'new'),
                const SizedBox(width: 10),
                _tabButton("Completed Orders", 'completed'),
              ],
            ),
            const SizedBox(height: 20),

            // 🔁 Orders List from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('orders')
                        .where('userId', isEqualTo: user?.uid)
                        .where('status', isEqualTo: selectedStatus)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No orders yet."));
                  }

                  final orders = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final data = order.data() as Map<String, dynamic>;
                      return _orderTile(order.id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNavBar(context),
    );
  }

  // 🔁 Tab Button
  Widget _tabButton(String label, String value) {
    bool isSelected = selectedStatus == value;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedStatus = value;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF292B41) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF292B41),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF292B41)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🔁 Order Tile
  Widget _orderTile(String orderId, Map<String, dynamic> data) {
    final List items = data['items'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFC5E4E6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ORDER ID: $orderId", style: _boldText()),
          const SizedBox(height: 8),
          Text("BUYER: ${data['buyerName']}", style: _smallText()),
          Text("ADDRESS: ${data['address']}", style: _smallText()),
          Text("TOTAL PRICE: \$${data['totalPrice']}", style: _smallText()),
          const SizedBox(height: 10),

          // ✅ List all ordered items
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  SizedBox(
                    height: 30,
                    width: 30,
                    child: Image.network(
                      item['image'] ?? 'https://via.placeholder.com/30',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['name'] ?? 'Unnamed',
                      style: _smallText(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text("\$${item['price']}", style: _smallText()),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 10),

          // ✅ Action Button for New Orders
          if (selectedStatus == 'new')
            ElevatedButton(
              onPressed: () => _markAsShipped(orderId),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              ),
              child: const Text(
                "MARKED AS SHIPPED",
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  // 🔁 Update order status to "completed"
  Future<void> _markAsShipped(String orderId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': 'completed',
    });
  }

  // 🔁 Reusable Text Styles
  TextStyle _boldText() => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Color(0xFF292B41),
  );

  TextStyle _smallText() => const TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    color: Color(0xFF292B41),
  );

  // 🔁 Bottom Navigation Bar
  Widget _bottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 3,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF292B41),
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
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
        } else if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserProfile()),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Marketplace'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
