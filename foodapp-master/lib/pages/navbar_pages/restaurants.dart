// Other Pages (Placeholders)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apptest/pages/navbar_pages/restaurants_info_page.dart';

class RestaurantPage extends StatefulWidget {
  const RestaurantPage({super.key});

  @override
  State<RestaurantPage> createState() => _RestaurantPageState();
}

class _RestaurantPageState extends State<RestaurantPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _allRestaurants = [];
  List<DocumentSnapshot> _filteredRestaurants = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchAllRestaurants();
  }

  Future<void> _fetchAllRestaurants() async {
    try {
      final querySnapshot = await _firestore.collection('restaurants').get();
      setState(() {
        _allRestaurants = querySnapshot.docs;
        _filteredRestaurants = _allRestaurants;
      });
    } catch (e) {
      debugPrint('Error fetching restaurants: $e');
    }
  }

  void _filterRestaurants(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredRestaurants = _allRestaurants.where((restaurant) {
        final restaurantName =
            (restaurant.data() as Map<String, dynamic>)['restaurantName']
                    ?.toLowerCase() ??
                '';
        return restaurantName.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 24, top: 24, bottom: 16, right: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Restaurants',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterRestaurants,
              decoration: InputDecoration(
                hintText: 'Search restaurants...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredRestaurants.isEmpty
                ? Center(
                    child: Text(
                      _isSearching
                          ? 'No restaurants found'
                          : 'No Restaurants Available',
                      style: GoogleFonts.poppins(),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _filteredRestaurants.length,
                    itemBuilder: (context, index) {
                      var restaurantDoc = _filteredRestaurants[index];
                      var restaurantData =
                          restaurantDoc.data() as Map<String, dynamic>;

                      return _buildRestaurantCard(
                        restaurantId: restaurantDoc.id,
                        name: restaurantData['restaurantName'] ??
                            'Unnamed Restaurant',
                        imageUrl: restaurantData['imageUrl'] ?? '',
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard({
    required String restaurantId,
    required String name,
    required String imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    RestaurantInfoPage(restaurantId: restaurantId)));
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
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.restaurant,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
