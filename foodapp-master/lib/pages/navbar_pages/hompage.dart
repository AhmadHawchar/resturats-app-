import 'package:apptest/pages/food_info.dart';
import 'package:apptest/pages/navbar_pages/category_info.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting

import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Utility function to convert Timestamp to formatted date string
  String formatOfferExpirationDate(dynamic expirationDate) {
    if (expirationDate == null) return 'No Expiry';

    try {
      // If it's already a DateTime, convert to string
      if (expirationDate is DateTime) {
        return DateFormat('MMMM d, y').format(expirationDate);
      }

      // If it's a Firestore Timestamp, convert to DateTime first
      if (expirationDate is Timestamp) {
        final dateTime = expirationDate.toDate();
        return DateFormat('MMMM d, y').format(dateTime);
      }

      // If it's a string, return as is
      if (expirationDate is String) {
        return expirationDate;
      }

      return 'Invalid Date';
    } catch (e) {
      print('Error formatting date: $e');
      return 'No Expiry';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: TextField(
            //     decoration: InputDecoration(
            //       hintText: 'Search...',
            //       prefixIcon: Icon(Icons.search, color: Colors.grey),
            //       filled: true,
            //       fillColor: Colors.grey[200],
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(10),
            //         borderSide: BorderSide.none,
            //       ),
            //     ),
            //   ),
            // ),
            SizedBox(
              height: 30,
            ),
            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryButton(
                      icon: Icons.fastfood,
                      label: 'Meat',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CategoryInfoPage(categoryName: 'Meat'),
                          ),
                        );
                      }),
                  CategoryButton(
                      icon: Icons.local_bar,
                      label: 'Drinks',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CategoryInfoPage(categoryName: 'Drinks'),
                          ),
                        );
                      }),
                  CategoryButton(
                      icon: Icons.grass,
                      label: 'Salads',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CategoryInfoPage(categoryName: 'Salads'),
                          ),
                        );
                      }),
                  CategoryButton(
                      icon: Icons.cake,
                      label: 'Sweets',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CategoryInfoPage(categoryName: 'Sweets'),
                          ),
                        );
                      }),
                  CategoryButton(
                      icon: Icons.dinner_dining,
                      label: 'Plates',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CategoryInfoPage(categoryName: 'Plates'),
                          ),
                        );
                      }),
                  CategoryButton(
                      icon: Icons.fastfood,
                      label: 'Sandwiches',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CategoryInfoPage(categoryName: 'Sandwiches'),
                          ),
                        );
                      }),
                ],
              ),
            ),
            SizedBox(
              height: 30,
            ),
            // Recommended Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended for You',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  _buildRecommendedItemsStreamBuilder(),
                ],
              ),
            ),
            SizedBox(height: 30),
            // Daily Deals Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Deals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  _buildFeaturedItemsStreamBuilder(),
                ],
              ),
            ),

            // Big Offers Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Big Offers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collectionGroup('menu_items')
                        .where('type', isEqualTo: 'Big Offers')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final items = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return _buildBigOfferItemCard(items[index]);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigOfferItemCard(DocumentSnapshot menuItemDoc) {
    // Get the parent restaurant document reference
    DocumentReference restaurantRef = menuItemDoc.reference.parent.parent!;

    return FutureBuilder<DocumentSnapshot>(
      future: restaurantRef.get(),
      builder: (context, restaurantSnapshot) {
        if (!restaurantSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var menuItem = menuItemDoc.data() as Map<String, dynamic>;
        var restaurantId = restaurantRef.id;

        return BigOfferItemCard(
          dealQuantity: menuItem['dealQuantity'] ?? 0,
          imageUrl: menuItem['imageUrl'] ?? '',
          title: menuItem['name'] ?? '',
          description: menuItem['description'] ?? '',
          price: menuItem['price'] ?? 0.0,
          originalPrice: (menuItem['originalPrice'] ?? 0).toDouble(),
          expirationDate:
              formatOfferExpirationDate(menuItem['offerExpirationDate']),

          foodItem: {
            'id': menuItemDoc.id,
            'name': menuItem['name'],
            'description': menuItem['description'],
            'price': menuItem['price'],
            'imageUrl': menuItem['imageUrl'],
            'originalPrice': menuItem['originalPrice'],
            'materials': menuItem['materials'],
            'instructions': menuItem['instructions'],
            "quantity": menuItem['quantity'],
            'dealQuantity': menuItem['dealQuantity'],
          },
          restaurantId: restaurantId, // Pass the correct restaurant ID
        );
      },
    );
  }

  Widget _buildFeatureItemCard(DocumentSnapshot menuItemDoc) {
    // Get the parent restaurant document reference
    DocumentReference restaurantRef = menuItemDoc.reference.parent.parent!;

    return FutureBuilder<DocumentSnapshot>(
      future: restaurantRef.get(),
      builder: (context, restaurantSnapshot) {
        if (!restaurantSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var menuItem = menuItemDoc.data() as Map<String, dynamic>;
        var restaurantId = restaurantRef.id;

        return FeatureItemCard(
          title: menuItem['name'] ?? '',
          description: '${menuItem['dealQuantity']?.toString() ?? ''} pieces',
          price: menuItem['price']?.toDouble() ?? 0.0,
          imageUrl: menuItem['imageUrl'] ?? '',
          discountPrice: menuItem['originalPrice']?.toString() ?? '0',
          restaurantId: restaurantId,
          itemId: menuItemDoc.id,
          foodItem: {
            'id': menuItemDoc.id,
            'name': menuItem['name'],
            'description': menuItem['description'],
            'price': menuItem['price'],
            'imageUrl': menuItem['imageUrl'],
            'originalPrice': menuItem['originalPrice'],
            'materials': menuItem['materials'],
            'instructions': menuItem['instructions'],
            "quantity": menuItem['quantity'],
            'dealQuantity': menuItem['dealQuantity'],
          },
        );
      },
    );
  }

  StreamBuilder<QuerySnapshot> _buildFeaturedItemsStreamBuilder() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collectionGroup('menu_items')
          .where('type', isEqualTo: 'Daily Deals')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No Daily Deals available'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            return _buildFeatureItemCard(snapshot.data!.docs[index]);
          },
        );
      },
    );
  }

  // Method to build recommended items stream
  Widget _buildRecommendedItemsStreamBuilder() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collectionGroup('menu_items').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No items available'));
        }

        // Sort items by dealQuantity (descending) and price (ascending)
        final sortedDocs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aDealQuantity =
                (a.data() as Map<String, dynamic>)['dealQuantity'] ?? 0;
            final bDealQuantity =
                (b.data() as Map<String, dynamic>)['dealQuantity'] ?? 0;
            final aPrice = (a.data() as Map<String, dynamic>)['price'] ?? 0.0;
            final bPrice = (b.data() as Map<String, dynamic>)['price'] ?? 0.0;

            // First compare by dealQuantity (descending)
            final quantityCompare = bDealQuantity.compareTo(aDealQuantity);
            if (quantityCompare != 0) return quantityCompare;

            // If dealQuantity is equal, compare by price (ascending)
            return aPrice.compareTo(bPrice);
          });

        // Take only the top 3 items
        final topItems = sortedDocs.take(3).toList();

        return Container(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: topItems.length,
            itemBuilder: (context, index) {
              return _buildRecommendedItemCard(topItems[index]);
            },
          ),
        );
      },
    );
  }

  // Method to build a recommended item card
  Widget _buildRecommendedItemCard(DocumentSnapshot doc) {
    // Get the parent restaurant document reference
    DocumentReference restaurantRef = doc.reference.parent.parent!;

    return FutureBuilder<DocumentSnapshot>(
      future: restaurantRef.get(),
      builder: (context, restaurantSnapshot) {
        if (!restaurantSnapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var menuItem = doc.data() as Map<String, dynamic>;
        var restaurantId = restaurantRef.id;

        return RecommendedItemCard(
          imageUrl: menuItem['imageUrl'] ?? '',
          title: menuItem['name'] ?? '',
          description: menuItem['description'] ?? '',
          price: (menuItem['price'] ?? 0).toDouble(),
          originalPrice: (menuItem['originalPrice'] ?? 0).toDouble(),
          dealQuantity: menuItem['dealQuantity'] ?? 0,
          foodItem: {
            'id': doc.id,
            'name': menuItem['name'],
            'description': menuItem['description'],
            'price': menuItem['price'],
            'imageUrl': menuItem['imageUrl'],
            'originalPrice': menuItem['originalPrice'],
            'materials': menuItem['materials'],
            'instructions': menuItem['instructions'],
            'quantity': menuItem['quantity'],
            'dealQuantity': menuItem['dealQuantity'],
          },
          restaurantId: restaurantId,
        );
      },
    );
  }
}

// Category Button Widget
class CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const CategoryButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 100,
          height: 70,
          decoration: BoxDecoration(
            color: _getColorForCategory(label),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
              SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForCategory(String label) {
    switch (label) {
      case 'Meat':
        return Colors.deepOrange[400]!;
      case 'Drinks':
        return Colors.green[600]!;
      case 'Salads':
        return Colors.teal[400]!;
      case 'Sweets':
        return Colors.purple[400]!;
      case 'Plates':
        return Colors.blue[600]!;
      case 'Sandwiches':
        return Colors.blue[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

// Feature Item Card Widget
class FeatureItemCard extends StatelessWidget {
  final String title;
  final String description;
  final double price;
  final String discountPrice;
  final String imageUrl;
  final String restaurantId;
  final String itemId;
  final Map<String, dynamic> foodItem;

  FeatureItemCard({
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.discountPrice,
    required this.restaurantId,
    required this.itemId,
    required this.foodItem,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to food info page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodInfoPage(
              foodItem: foodItem,
              restaurantId: restaurantId,
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.none,
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: Image.network(
            imageUrl,
            width: 100,
            height: 100,
          ),
          title: Text(title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(description),
              SizedBox(
                height: 5,
              ),
              Row(
                children: [
                  Text(
                    '\$$price',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 40,
                  ),
                  Text(
                    '\$$discountPrice',
                    style: TextStyle(
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
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

// Recommended Item Card Widget
class RecommendedItemCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final double price;
  final double originalPrice;
  final Map<String, dynamic> foodItem;
  final String restaurantId;
  final int dealQuantity;

  const RecommendedItemCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.foodItem,
    required this.restaurantId,
    required this.dealQuantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodInfoPage(
              foodItem: foodItem,
              restaurantId: restaurantId,
            ),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: EdgeInsets.only(right: 16),
        child: Stack(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        if (dealQuantity > 0)
                          Text(
                            '$dealQuantity pieces',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            if (originalPrice > 0)
                              Text(
                                '\$${originalPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Recommended',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BigOfferItemCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final double price;
  final double originalPrice;
  final String expirationDate;
  final Map<String, dynamic> foodItem;
  final String restaurantId;
  final int dealQuantity;

  const BigOfferItemCard({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.expirationDate,
    required this.foodItem,
    required this.restaurantId,
    required this.dealQuantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodInfoPage(
              foodItem: foodItem,
              restaurantId: restaurantId,
            ),
          ),
        );
      },
      child: Card(
        color: Colors.pink.shade50,
        margin: EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          clipBehavior: Clip.none, // Allows children to overflow the card
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Space for the image (invisible placeholder)
                  SizedBox(width: 100 + 16), // Width of the image + spacing
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '$dealQuantity pieces',
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '\$$price',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 50),
                            Text(
                              '\$$originalPrice',
                              style: TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          ' until $expirationDate',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Positioned Image
            Positioned(
              left: -10, // Move the image outside the card
              top: 55, // Adjust vertical position as needed
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl,
                  width: 130, // Slightly larger to make it stand out
                  height: 130,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 50,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
