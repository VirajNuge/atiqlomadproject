import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String sellerId; // Make sure sellerId is included

  const CheckoutPage({
    super.key,
    required this.productData,
    required this.sellerId,
  });

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();

  bool _isLoading = false;

  Future<void> _placeOrder() async {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _cardNumberController.text.isEmpty ||
        _cvvController.text.isEmpty ||
        _expiryDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("You must be logged in.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final order = {
        'userId': user.uid, // optional legacy key
        'buyerId': user.uid, // ✅ REQUIRED for chat
        'buyerName': _nameController.text,
        'address': _addressController.text,
        'totalPrice': widget.productData['price'],
        'status': 'new',
        'sellerId': widget.sellerId,
        'timestamp': FieldValue.serverTimestamp(),
        'items': [
          {
            'name': widget.productData['name'],
            'price': widget.productData['price'],
            'image':
                widget.productData['Images'] != null &&
                        widget.productData['Images'].isNotEmpty
                    ? widget.productData['Images'][0]
                    : 'https://via.placeholder.com/60',
            'quantity': 1,
          },
        ],
      };

      await FirebaseFirestore.instance.collection('orders').add(order);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully!")),
      );

      Navigator.pop(context); // Or navigate to confirmation page
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error placing order: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light background
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFF292B41),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductDetails(),
            const SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: _buildCheckoutForm())),
            const SizedBox(height: 10),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ORDER SUMMARY",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Product: ${widget.productData['name']}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            "Price: \$${widget.productData['price']}",
            style: const TextStyle(fontSize: 16, color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutForm() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField("Full Name", _nameController, Icons.person),
          _buildInputField("Shipping Address", _addressController, Icons.home),
          _buildInputField(
            "Card Number",
            _cardNumberController,
            Icons.credit_card,
            isNumeric: true,
          ),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  "CVV",
                  _cvvController,
                  Icons.lock,
                  isNumeric: true,
                  isShort: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInputField(
                  "Expiry Date",
                  _expiryDateController,
                  Icons.calendar_today,
                  isShort: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumeric = false,
    bool isShort = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                onPressed: _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF292B41),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "CONFIRM PURCHASE",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
    );
  }
}
