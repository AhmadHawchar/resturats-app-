import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:apptest/pages/food_info.dart';

class CategoryInfoPage extends StatefulWidget {
  final String categoryName;

  const CategoryInfoPage({Key? key, required this.categoryName})
      : super(key: key);

  @override
  _CategoryInfoPageState createState() => _CategoryInfoPageState();
}

class _CategoryInfoPageState extends State<CategoryInfoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _categoryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategoryItems();
  }

  Future<void> _fetchCategoryItems() async {
    try {
      // Normalize category name to match Firestore data
      String normalizedCategory = widget.categoryName;
      print("Searching for category: $normalizedCategory");

      // Fetch all restaurants first
      final restaurantsSnapshot =
          await _firestore.collection('restaurants').get();

      // Collect menu items across all restaurants
      List<DocumentSnapshot> allCategoryItems = [];

      for (var restaurantDoc in restaurantsSnapshot.docs) {
        final menuItemsSnapshot = await restaurantDoc.reference
            .collection('menu_items')
            .where('category', isEqualTo: normalizedCategory)
            .get();

        allCategoryItems.addAll(menuItemsSnapshot.docs);
      }

      setState(() {
        _categoryItems = allCategoryItems;
        _isLoading = false;
        print(
            "Found ${_categoryItems.length} items in $normalizedCategory category");
      });
    } catch (e) {
      print('Error fetching category items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to normalize category names
  String _normalizeCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'meat':
        return 'meat';
      case 'drinks':
        return 'drinks';
      case 'salads':
        return 'salad';
      case 'sweets':
        return 'dessert';
      case 'plates':
        return 'main course';
      case 'sandwiches':
        return 'sandwich';
      default:
        return category.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.categoryName} Items',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _categoryItems.isEmpty
              ? Center(
                  child: Text(
                    'No items found in ${widget.categoryName} category',
                    style: GoogleFonts.poppins(),
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: _categoryItems.length,
                  itemBuilder: (context, index) {
                    var menuItemDoc = _categoryItems[index];
                    return _buildCategoryItemCard(menuItemDoc);
                  },
                ),
    );
  }

  Widget _buildCategoryItemCard(DocumentSnapshot menuItemDoc) {
    var menuItemData = menuItemDoc.data() as Map<String, dynamic>;
    var restaurantRef = menuItemDoc.reference.parent.parent;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodInfoPage(
              foodItem: menuItemData,
              restaurantId: restaurantRef!.id,
            ),
          ),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                child: CachedNetworkImage(
                  imageUrl: menuItemData['imageUrl'] ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menuItemData['name'] ?? 'Unnamed Item',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$${menuItemData['price']?.toString() ?? '0.00'}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
