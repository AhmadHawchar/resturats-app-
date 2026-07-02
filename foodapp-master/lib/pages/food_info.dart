import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodInfoPage extends StatefulWidget {
  final Map<String, dynamic> foodItem;
  final String restaurantId;

  const FoodInfoPage({
    super.key,
    required this.foodItem,
    required this.restaurantId,
  });

  @override
  _FoodInfoPageState createState() => _FoodInfoPageState();
}

class _FoodInfoPageState extends State<FoodInfoPage> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _whatsappNumber;
  bool _isOrdered = false;
  String? _errorMessage;
  int _quantity = 1;
  late int _maxQuantity;
  List<String> _selectedMaterials = [];

  @override
  void initState() {
    super.initState();
    _maxQuantity = widget.foodItem['quantity'] ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRestaurantDetails();
      _fetchMenuItemDetails();
    });
  }

  Future<void> _fetchRestaurantDetails() async {
    print('Fetching restaurant details');
    print('Current Restaurant ID: ${widget.restaurantId}');

    try {
      if (widget.restaurantId.isEmpty) {
        print('❌ ERROR: Restaurant ID is empty');
        print('Full widget details: ${widget.toString()}');
        _showErrorSnackBar('Invalid restaurant information');
        return;
      }

      print('Attempting to fetch restaurant document');
      final QuerySnapshot restaurantQuery =
          await _firestore.collection('restaurants').get();

      print('Total restaurants found: ${restaurantQuery.docs.length}');
      for (var doc in restaurantQuery.docs) {
        print('Found Restaurant ID: ${doc.id}');
      }

      final restaurantDoc = await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();

      print('Restaurant Document Fetch Attempt:');
      print('Document exists: ${restaurantDoc.exists}');

      if (!restaurantDoc.exists) {
        print('❌ ERROR: Restaurant document does not exist');
        print('Attempted ID: ${widget.restaurantId}');
        _showErrorSnackBar('Restaurant not found');
        return;
      }

      final data = restaurantDoc.data();
      if (data == null) {
        print('❌ ERROR: Restaurant document data is null');
        _showErrorSnackBar('Unable to fetch restaurant details');
        return;
      }

      print('Restaurant Data: $data');

      setState(() {
        _whatsappNumber = data['whatsappNumber'];
        print('WhatsApp Number: $_whatsappNumber');
      });
    } catch (e, stackTrace) {
      print('❌ CRITICAL ERROR in _fetchRestaurantDetails');
      print('Error: $e');
      print('Stack Trace: $stackTrace');
      _showErrorSnackBar('Could not fetch restaurant details');
    }
  }

  Future<void> _fetchMenuItemDetails() async {
    try {
      final menuItemDoc = await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('menu_items')
          .doc(widget.foodItem['id'])
          .get();

      final data = menuItemDoc.data();
      if (data != null) {
        setState(() {
          _selectedMaterials = List<String>.from(data['materials'] ?? []);
          // Prioritize Firestore data, fallback to widget foodItem
          _maxQuantity =
              data['maxQuantity'] ?? widget.foodItem['quantity'] ?? 10;
        });
      }
    } catch (e) {
      print('Error fetching menu item details: $e');
    }
  }

  void _incrementQuantity() {
    setState(() {
      if (_quantity < _maxQuantity) _quantity++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 1) _quantity--;
    });
  }

  Future<void> _placeOrder() async {
    await _showCommentDialog();
  }

  Future<void> _showCommentDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Order Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Enter any special instructions',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Submit Order'),
              onPressed: () {
                Navigator.of(context).pop();
                _submitOrder();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showLoginRequiredDialog();
        return;
      }

      // Calculate total price and commission
      double totalPrice = (widget.foodItem['price'] ?? 0.0) * _quantity;
      double commission = totalPrice * 0.05; // 5% commission

      // Create order document reference for restaurant
      DocumentReference restaurantOrderRef = _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('orders')
          .doc();

      // Create order document reference for user
      DocumentReference userOrderRef = _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('orders')
          .doc();

      // Prepare order data with quantity and materials
      Map<String, dynamic> orderData = {
        'userOrderId': userOrderRef.id, // Add userOrderId
        'restaurantOrderId': restaurantOrderRef.id, // Add restaurantOrderId
        'userId': currentUser.uid,
        'userName': currentUser.displayName ?? 'Anonymous User',
        'userEmail': currentUser.email ?? 'No email',
        'menuItemId': widget.foodItem['id'],
        'menuItemName': widget.foodItem['name'] ?? 'Unnamed Item',
        'menuItemPrice': widget.foodItem['price'] ?? 0.0,
        'quantity': _quantity,
        'dealQuantity': widget.foodItem['dealQuantity'] ?? 0,
        'selectedMaterials': _selectedMaterials,
        'comment': _commentController.text.isNotEmpty
            ? _commentController.text
            : 'No special instructions',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'restaurantId': widget.restaurantId,
        'totalPrice': totalPrice,
        'commission': commission,
        'imageUrl': widget.foodItem['imageUrl'] ?? '',
      };

      // Submit order to restaurant's orders subcollection
      await restaurantOrderRef.set(orderData);

      // Submit order to user's orders subcollection
      await userOrderRef.set(orderData);

      // Update owner's profit using current user's UID
      DocumentReference ownerRef =
          _firestore.collection('owners').doc("eY3B3EvHvxa1BcKLwEZ79BPDQVG2");

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot ownerSnapshot = await transaction.get(ownerRef);

        if (!ownerSnapshot.exists) {
          // If owner document doesn't exist, create it
          transaction.set(ownerRef, {
            'totalProfit': commission,
            'lastCommissionUpdate': FieldValue.serverTimestamp(),
            'lastCommissionAmount': commission
          });
        } else {
          // Get current profit or default to 0
          double currentProfit =
              (ownerSnapshot.data() as Map<String, dynamic>)['totalProfit'] ??
                  0.0;

          // Update total profit by adding commission
          transaction.update(ownerRef, {
            'totalProfit': currentProfit + commission,
            'lastCommissionUpdate': FieldValue.serverTimestamp(),
            'lastCommissionAmount': commission
          });
        }
      });

      // Update UI
      setState(() {
        _isOrdered = true;
      });

      // Show success message
      _showSuccessSnackBar('Order placed successfully! 5% commission applied.');
    } catch (e, stackTrace) {
      print('Unexpected error in order submission: $e');
      print('Stack trace: $stackTrace');
      _showErrorSnackBar('An unexpected error occurred');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: _errorMessage!.contains('successfully')
                ? Colors.green
                : Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _errorMessage = null;
        });
      });
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Section with Pink Background
            Container(
              height: 300, // Increased height for better layout
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFD75A88), // Pink background
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Back Button - Top Left
                  Positioned(
                    top: 50,
                    left: 10,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Title and Votes - Top Right
                  Positioned(
                    top: 80,
                    right: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          widget.foodItem['name'] ?? '',
                          style: TextStyle(
                            fontSize: 50,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 20),
                              Text('125 Votes',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Image at Bottom Left (Overlaying)
                  Positioned(
                    bottom: -30,
                    left: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.foodItem['imageUrl'] ?? '',
                        height: 200,
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Price Container at Bottom Right (Overlaying)
                  Positioned(
                    bottom: -30,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '\$${widget.foodItem['price']}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD75A88),
                                ),
                              ),
                              SizedBox(width: 10),
                              if (widget.foodItem['originalPrice'] != null)
                                Text(
                                  '\$${widget.foodItem['originalPrice']}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating

                  SizedBox(height: 20),

                  // Price Section

                  SizedBox(height: 20),

                  // Materials Section
                  Text(
                    'Materials',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.foodItem['materials'] ?? 'No materials available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),

                  // Instructions Section
                  Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.foodItem['instructions'] ??
                        'No instructions available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),

                  // Description Icons
                  Text(
                    'Descriptions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildDescriptionItem(
                        icon: Icons.room_service,
                        label: '${widget.foodItem['dealQuantity']} Pieces',
                        color: Colors.blue[100]!,
                      ),
                      SizedBox(width: 20),
                      _buildDescriptionItem(
                        icon: Icons.local_fire_department,
                        label: '313 Calories',
                        color: Colors.red[100]!,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Quantity Selector
                  Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed: _decrementQuantity,
                      ),
                      SizedBox(width: 20),
                      Text(
                        '$_quantity',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 20),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed: _incrementQuantity,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_quantity Items',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Total: \$${(_quantity * (widget.foodItem['price'] ?? 0.0)).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _isOrdered && _whatsappNumber != null
                        ? ElevatedButton.icon(
                            onPressed: _launchWhatsApp,
                            icon: Icon(Icons.phone),
                            label: Text('Contact Restaurant'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFD75A88),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _placeOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFD75A88),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text('Order Now'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color.withOpacity(0.8)),
          SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Color(0xFFD75A88),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login Required'),
        content: Text('Please log in to place an order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _launchWhatsApp() async {
    if (_whatsappNumber == null) {
      _showErrorSnackBar('WhatsApp number not available');
      return;
    }

    final Uri whatsappUrl = Uri.parse('https://wa.me/$_whatsappNumber');

    try {
      await launchUrl(whatsappUrl);
    } catch (e, stackTrace) {
      print('Could not launch WhatsApp: $e');
      print('Stack trace: $stackTrace');
      _showErrorSnackBar('Could not launch WhatsApp');
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
