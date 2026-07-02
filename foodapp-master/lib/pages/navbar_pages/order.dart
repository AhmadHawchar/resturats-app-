import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _initializeOrdersStream();
  }

  void _initializeOrdersStream() {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      setState(() {
        _ordersStream = _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('orders')
            .snapshots();
      });
    }
  }

  Future<void> _cancelOrder(DocumentSnapshot orderDoc) async {
    try {
      // Get order details
      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      String restaurantOrderId = orderData['restaurantOrderId'];
      String restaurantId = orderData['restaurantId'];

      // Delete from user's orders
      await orderDoc.reference.delete();

      // Delete from restaurant's orders
      await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('orders')
          .doc(restaurantOrderId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateOrderQuantity(
      DocumentSnapshot orderDoc, int newQuantity) async {
    try {
      // Get order details with null safety
      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;

      // Safely extract and convert values
      String restaurantOrderId = orderData['restaurantOrderId'] ?? '';
      String restaurantId = orderData['restaurantId'] ?? '';

      // Handle potential null or dynamic price values
      dynamic priceValue = orderData['menuItemPrice'] ?? 0.0;
      double itemPrice = priceValue is num ? priceValue.toDouble() : 0.0;

      // Calculate total price with 5% commission
      double totalPrice = priceValue! * newQuantity;
      double commission = totalPrice * 0.05; // 5% commission
      double totalPriceWithCommission = totalPrice + commission;

      // Prepare update data with type conversion
      Map<String, dynamic> userOrderUpdate = {
        'quantity': newQuantity,
        'itemPrice': itemPrice,
        'totalPrice': totalPriceWithCommission,
        'commission': commission,
      };

      Map<String, dynamic> restaurantOrderUpdate = {
        'quantity': newQuantity,
        'itemPrice': itemPrice,
        'totalPrice': totalPriceWithCommission,
        'commission': commission,
      };

      // Update user's order
      await orderDoc.reference.update(userOrderUpdate);

      // Update restaurant's order if IDs are valid
      if (restaurantId.isNotEmpty && restaurantOrderId.isNotEmpty) {
        await _firestore
            .collection('restaurants')
            .doc(restaurantId)
            .collection('orders')
            .doc(restaurantOrderId)
            .update(restaurantOrderUpdate);
      }
    } catch (e) {
      print('Error updating order: $e'); // More detailed error logging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildQuantityControl(DocumentSnapshot orderDoc, int currentQuantity) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: Colors.black),
            onPressed: currentQuantity > 1
                ? () => _updateOrderQuantity(orderDoc, currentQuantity - 1)
                : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$currentQuantity',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.black),
            onPressed: () =>
                _updateOrderQuantity(orderDoc, currentQuantity + 1),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _ordersStream == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No orders yet',
                      style: GoogleFonts.poppins(),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var orderDoc = snapshot.data!.docs[index];
                    var orderData = orderDoc.data() as Map<String, dynamic>;

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: orderData['imageUrl'] ?? '',
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.food_bank),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        orderData['menuItemName'] ??
                                            'Unknown Item',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildQuantityControl(
                                            orderDoc,
                                            orderData['quantity'] ?? 1,
                                          ),
                                          Text(
                                            'Total: \$${orderData['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                                            style: GoogleFonts.poppins(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _cancelOrder(orderDoc),
                              icon: Icon(Icons.cancel),
                              label: Text('Cancel Order'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                minimumSize: Size(double.infinity, 50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
