import 'dart:io';
import 'package:apptest/pages/auth/ask_user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For formatting dates

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode;

class RestaurantAdminPage extends StatefulWidget {
  const RestaurantAdminPage({super.key});

  @override
  State<RestaurantAdminPage> createState() => _RestaurantAdminPageState();
}

class _RestaurantAdminPageState extends State<RestaurantAdminPage>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  Map? _restaurantData;
  bool _isLoading = true;

  // Editable controllers
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Time controllers
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  // Color palette
  final Color _primaryColor = const Color(0xFF6A1B9A);
  final Color _backgroundColor = const Color(0xFFF3E5F5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRestaurantData();
  }

  Future<void> _fetchRestaurantData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }
      final docSnapshot =
          await _firestore.collection('restaurants').doc(user.uid).get();
      setState(() {
        _restaurantData = docSnapshot.data() as Map?;
        _isLoading = false;

        // Initialize controllers with existing data
        _infoController.text = _restaurantData?['info'] ?? '';
        _contactController.text = _restaurantData?['contact'] ?? '';
        _addressController.text = _restaurantData?['address'] ?? '';

        // Parse stored times if available
        if (_restaurantData?['openingTime'] != null) {
          _openingTime = _parseStoredTime(_restaurantData!['openingTime']);
        }
        if (_restaurantData?['closingTime'] != null) {
          _closingTime = _parseStoredTime(_restaurantData!['closingTime']);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error fetching restaurant data: $e');
    }
  }

  TimeOfDay? _parseStoredTime(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      timeStr = timeStr.trim();
      final parts = timeStr.split(':');
      if (parts.length < 2) return null;
      final hour = int.tryParse(parts[0]);
      final minuteParts = parts[1].split(' ');
      if (hour == null || minuteParts.length < 2) return null;
      final minute = int.tryParse(minuteParts[0]);
      final period = minuteParts[1];
      if (minute == null) return null;
      int convertedHour = hour;
      if (period == 'PM') {
        convertedHour = (hour == 12) ? 12 : hour + 12;
      } else if (period == 'AM') {
        convertedHour = (hour == 12) ? 0 : hour;
      } else {
        return null;
      }
      return TimeOfDay(hour: convertedHour, minute: minute);
    } catch (e) {
      debugPrint('Unexpected error parsing time: $timeStr - $e');
      return null;
    }
  }

  bool _isRestaurantOpen() {
    try {
      if (_restaurantData == null) return false;
      final openingTimeStr = _restaurantData!['openingTime'] as String?;
      final closingTimeStr = _restaurantData!['closingTime'] as String?;
      final openingTime = _parseStoredTime(openingTimeStr);
      final closingTime = _parseStoredTime(closingTimeStr);
      if (openingTime == null || closingTime == null) return false;
      final now = TimeOfDay.now();
      final currentMinutes = now.hour * 60 + now.minute;
      final openingMinutes = openingTime.hour * 60 + openingTime.minute;
      final closingMinutes = closingTime.hour * 60 + closingTime.minute;
      if (closingMinutes < openingMinutes) {
        return currentMinutes >= openingMinutes ||
            currentMinutes <= closingMinutes;
      }
      return currentMinutes >= openingMinutes &&
          currentMinutes <= closingMinutes;
    } catch (e) {
      debugPrint('Error checking restaurant status: $e');
      return false;
    }
  }

  String _formatTimeOfDayWithAmPm(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AskUserPage()),
      );
    } catch (e) {
      _showErrorSnackBar('Logout failed: $e');
    }
  }

  Future<void> _updateRestaurantHours() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final openingTimeStr =
          _openingTime != null ? _formatTimeOfDayWithAmPm(_openingTime!) : null;
      final closingTimeStr =
          _closingTime != null ? _formatTimeOfDayWithAmPm(_closingTime!) : null;
      await _firestore.collection('restaurants').doc(user.uid).update({
        'openingTime': openingTimeStr,
        'closingTime': closingTimeStr,
      });
      await _fetchRestaurantData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restaurant hours updated successfully',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error updating restaurant hours: $e');
    }
  }

  void _showHoursEditDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Restaurant Hours',
            style: GoogleFonts.poppins(
              color: _primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimePicker(
                title: 'Opening Time',
                initialTime: _openingTime,
                onTimeChanged: (time) {
                  setState(() {
                    _openingTime = time;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTimePicker(
                title: 'Closing Time',
                initialTime: _closingTime,
                onTimeChanged: (time) {
                  setState(() {
                    _closingTime = time;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _updateRestaurantHours();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String title,
    required TimeOfDay? initialTime,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: initialTime ?? TimeOfDay.now(),
              builder: (context, child) => Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    primary: _primaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: _primaryColor,
                  ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              onTimeChanged(picked);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
          child: Text(
            initialTime != null
                ? _formatTimeOfDayWithAmPm(initialTime)
                : 'Select Time',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab() {
    if (_restaurantData == null) {
      return Center(
        child: Text(
          'No restaurant information available',
          style: GoogleFonts.poppins(color: _primaryColor),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEditableInfoCard(
          icon: Icons.restaurant,
          title: 'Restaurant Information',
          value: _restaurantData?['info'] ?? 'Not provided',
          controller: _infoController,
          field: 'info',
        ),
        _buildEditableInfoCard(
          icon: Icons.phone,
          title: 'Contact Number',
          value: _restaurantData?['contact'] ?? 'Not provided',
          controller: _contactController,
          field: 'contact',
        ),
        _buildEditableInfoCard(
          icon: Icons.location_on,
          title: 'Address',
          value: _restaurantData?['address'] ?? 'Not provided',
          controller: _addressController,
          field: 'address',
        ),
        _buildRestaurantStatusCard(),
      ],
    );
  }

  Widget _buildEditableInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required TextEditingController controller,
    required String field,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: _primaryColor),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        subtitle: Text(
          value,
          style: GoogleFonts.poppins(),
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: _primaryColor),
          onPressed: () => _showEditDialog(title, controller, field),
        ),
      ),
    );
  }

  Widget _buildRestaurantStatusCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          _isRestaurantOpen() ? Icons.check_circle : Icons.highlight_off,
          color: _isRestaurantOpen() ? Colors.green : Colors.red,
        ),
        title: Text(
          'Restaurant Status',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        subtitle: Text(
          _openingTime != null && _closingTime != null
              ? 'Open: ${_formatTimeOfDayWithAmPm(_openingTime!)} - ${_formatTimeOfDayWithAmPm(_closingTime!)}'
              : 'Hours not set',
          style: GoogleFonts.poppins(),
        ),
        trailing: IconButton(
          icon: Icon(Icons.edit, color: _primaryColor),
          onPressed: () => _showHoursEditDialog(),
        ),
      ),
    );
  }

  void _showEditDialog(
    String title,
    TextEditingController controller,
    String field,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit $title',
          style: GoogleFonts.poppins(color: _primaryColor),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: title,
            labelStyle: GoogleFonts.poppins(color: _primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _updateRestaurantInfo(field, controller.text);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRestaurantInfo(String field, String value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await _firestore.collection('restaurants').doc(user.uid).update({
        field: value,
      });
      await _fetchRestaurantData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restaurant information updated successfully',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error updating restaurant information: $e');
    }
  }

  Widget _buildRestaurantNameHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: _primaryColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${_restaurantData?['restaurantName']}\'s restaurant ',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
            ),
          ),
          _buildStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isOpen = _isRestaurantOpen();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isOpen ? Icons.check_circle : Icons.highlight_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Open' : 'Closed',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTab() {
    final List<String> categories = [
      'Meat',
      'Drinks',
      'Salads',
      'Sweets',
      'Plates',
      'Sandwiches'
    ];

    final TextEditingController nameController = TextEditingController();
    final TextEditingController materialsController = TextEditingController();
    final TextEditingController instructionsController =
        TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController quantityController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController originalPriceController =
        TextEditingController();
    final TextEditingController dealQuantityController =
        TextEditingController();

    final ValueNotifier<XFile?> imageNotifier = ValueNotifier(null);
    final ValueNotifier<String?> categoryNotifier = ValueNotifier(null);
    final ValueNotifier<DateTime?> offerDateNotifier = ValueNotifier(null);

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        imageNotifier.value = pickedFile;
      }
    }

    Future<String?> uploadImageToImgBB(XFile imageFile) async {
      try {
        // Read image file as bytes
        final bytes = await imageFile.readAsBytes();

        // Convert bytes to base64
        final base64Image = base64Encode(bytes);

        // ImgBB API endpoint
        final url = Uri.parse('https://api.imgbb.com/1/upload');

        // API request
        final response = await http.post(
          url,
          body: {
            'key': 'd97d7227eca3b349cbf52ad09b50bafd', // Your ImgBB API key
            'image': base64Image,
          },
        );

        // Check response
        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          final imageUrl = jsonResponse['data']['url'];

          if (kDebugMode) {
            debugPrint('Image uploaded successfully: $imageUrl');
          }

          return imageUrl;
        } else {
          if (kDebugMode) {
            debugPrint('Image upload failed: ${response.body}');
          }
          return null;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error uploading image: $e');
        }
        return null;
      }
    }

    Future<void> saveMenuItem(String type) async {
      try {
        if (nameController.text.isEmpty ||
            categoryNotifier.value == null ||
            imageNotifier.value == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please fill all required fields')),
          );
          return;
        }

        // Upload image and get URL
        final imageUrl = await uploadImageToImgBB(imageNotifier.value!);

        if (imageUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed')),
          );
          return;
        }

        final menuItemData = {
          'name': nameController.text,
          'category': categoryNotifier.value,
          'materials': materialsController.text,
          'instructions': instructionsController.text,
          'description': descriptionController.text,
          'quantity': int.parse(quantityController.text),
          'dealQuantity': int.parse(dealQuantityController.text),
          'price': double.parse(priceController.text),
          'type': type,
          'imageUrl': imageUrl, // Use the uploaded image URL
        };

        if (type == 'Daily Deals' || type == 'Big Offers') {
          menuItemData['originalPrice'] =
              double.parse(originalPriceController.text);
        }

        if (type == 'Big Offers') {
          menuItemData['offerExpirationDate'] =
              Timestamp.fromDate(offerDateNotifier.value!);
        }

        await _firestore
            .collection('restaurants')
            .doc(_auth.currentUser!.uid)
            .collection('menu_items')
            .add(menuItemData);

        // Clear form after successful save
        nameController.clear();
        materialsController.clear();
        instructionsController.clear();
        descriptionController.clear();
        quantityController.clear();
        priceController.clear();
        originalPriceController.clear();
        dealQuantityController.clear();
        imageNotifier.value = null;
        categoryNotifier.value = null;
        offerDateNotifier.value = null;

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Menu item saved successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving menu item: $e')),
        );
      }
    }

    Widget buildMenuItemForm(String type) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ValueListenableBuilder(
              valueListenable: imageNotifier,
              builder: (context, image, child) => GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: image == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: _primaryColor),
                            Text(
                              'Add Product Image',
                              style: GoogleFonts.poppins(color: _primaryColor),
                            ),
                          ],
                        )
                      : Image.file(File(image.path), fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder(
              valueListenable: categoryNotifier,
              builder: (context, selectedCategory, child) =>
                  DropdownButtonFormField(
                value: selectedCategory,
                hint: Text('Select Category'),
                items: categories
                    .map((category) => DropdownMenuItem(
                        value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) {
                  categoryNotifier.value = value;
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: materialsController,
              decoration: InputDecoration(
                labelText: 'Materials',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: instructionsController,
              decoration: InputDecoration(
                labelText: 'Preparation Instructions',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (type == 'Daily Deals' || type == 'Big Offers')
              TextField(
                controller: originalPriceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Original Price',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            if (type == 'Daily Deals' || type == 'Big Offers')
              TextField(
                controller: dealQuantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Deal Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 16),
            if (type == 'Big Offers')
              ValueListenableBuilder(
                valueListenable: offerDateNotifier,
                builder: (context, selectedDate, child) => ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      offerDateNotifier.value = pickedDate;
                    }
                  },
                  child: Text(
                    selectedDate == null
                        ? 'Select Offer Expiration Date'
                        : 'Offer Expires: ${DateFormat.yMd().format(selectedDate)}',
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => saveMenuItem(type),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              child: Text('Save $type Item'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Daily Deals', icon: Icon(Icons.local_offer)),
              Tab(text: 'Big Offers', icon: Icon(Icons.card_giftcard)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // _buildMenuItemForm('Features'),
            buildMenuItemForm('Daily Deals'),
            buildMenuItemForm('Big Offers'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('restaurants')
          .doc(_auth.currentUser!.uid)
          .collection('orders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No Orders',
              style: GoogleFonts.poppins(color: _primaryColor),
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
              child: ListTile(
                title: Text(
                  orderData['userEmail'] ?? 'Unknown User',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, fontSize: 10),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'order name : ${orderData['menuItemName']}',
                      style: GoogleFonts.poppins(),
                    ),
                    Text(
                      'Quantity: ${orderData['quantity']}',
                      style: GoogleFonts.poppins(),
                    ),
                    Text(
                      'Total Price: \$${orderData['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  onPressed: () => _completeOrder(orderDoc),
                  child: Text(
                    'Complete',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _completeOrder(DocumentSnapshot orderDoc) async {
    try {
      var orderData = orderDoc.data() as Map<String, dynamic>;

      // Delete from restaurant's orders subcollection
      await _firestore
          .collection('restaurants')
          .doc(_auth.currentUser!.uid)
          .collection('orders')
          .doc(orderDoc.id)
          .delete();

      // Delete from user's orders subcollection
      await _firestore
          .collection('users')
          .doc(orderData['userId'])
          .collection('orders')
          .doc(orderData['userOrderId'])
          .delete();

      // Show success snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order completed successfully',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (e) {
      // Show error snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error completing order: $e',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_primaryColor),
              ),
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.logout, color: Colors.white),
                      onPressed: _logout,
                    ),
                  ],
                  expandedHeight: MediaQuery.of(context).size.height * 0.3,
                  floating: false,
                  pinned: true,
                  backgroundColor: _primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    background: _restaurantData?['imageUrl'] != null
                        ? Image.network(
                            _restaurantData!['imageUrl'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation(_primaryColor),
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: _primaryColor,
                              child: Center(
                                child: Icon(
                                  Icons.restaurant,
                                  color: Colors.white,
                                  size: 100,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: _primaryColor,
                            child: Center(
                              child: Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 100,
                              ),
                            ),
                          ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildRestaurantNameHeader(),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: _primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: _primaryColor,
                      tabs: [
                        Tab(icon: Icon(Icons.info_outline), text: 'Info'),
                        Tab(icon: Icon(Icons.menu_book), text: 'Menu'),
                        Tab(icon: Icon(Icons.shopping_cart), text: 'Orders'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildInfoTab(),
                  _buildMenuTab(),
                  _buildOrdersTab(),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _infoController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
