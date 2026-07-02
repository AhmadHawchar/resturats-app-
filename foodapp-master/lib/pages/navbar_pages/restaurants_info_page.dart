import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apptest/pages/food_info.dart';

class RestaurantInfoPage extends StatefulWidget {
  final String restaurantId;

  const RestaurantInfoPage({super.key, required this.restaurantId});

  @override
  State<RestaurantInfoPage> createState() => _RestaurantInfoPageState();
}

class _RestaurantInfoPageState extends State<RestaurantInfoPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  Map<String, dynamic>? _restaurantData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchRestaurantDetails();
  }

  Future<void> _fetchRestaurantDetails() async {
    try {
      final docSnapshot = await _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();

      setState(() {
        _restaurantData = docSnapshot.data();
      });
    } catch (e) {
      debugPrint('Error fetching restaurant details: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load restaurant details')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _restaurantData == null
          ? Center(child: CircularProgressIndicator())
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 300.0,
                    floating: false,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        "${_restaurantData?['restaurantName'] ?? 'Restaurant'}'s restaurant",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: CachedNetworkImage(
                        imageUrl: _restaurantData?['imageUrl'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            Icon(Icons.restaurant, size: 100),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.black,
                        tabs: [
                          Tab(text: 'Restaurant Info'),
                          Tab(text: 'Menu Items'),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildRestaurantInfoTab(),
                  _buildMenuItemsTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildRestaurantInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Address',
            value: _restaurantData?['address'] ?? 'Not provided',
          ),
          _buildInfoRow(
            icon: Icons.phone,
            label: 'Contact',
            value: _restaurantData?['contact'] ?? 'Not provided',
          ),
          _buildInfoRow(
            icon: Icons.access_time,
            label: 'Opening Hours',
            value: '${_restaurantData?['openingTime'] ?? 'Not set'} - '
                '${_restaurantData?['closingTime'] ?? 'Not set'}',
          ),
          _buildInfoRow(
            icon: Icons.info_outline,
            label: 'Description',
            value: _restaurantData?['info'] ?? 'No description available',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('menu_items')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No Menu Items',
              style: GoogleFonts.poppins(),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var menuItemDoc = snapshot.data!.docs[index];
            var menuItemData = menuItemDoc.data() as Map<String, dynamic>;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FoodInfoPage(
                      restaurantId: widget.restaurantId,
                      foodItem: {
                        'id': menuItemDoc.id,
                        ...menuItemData,
                      },
                    ),
                  ),
                );
              },
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: menuItemData['imageUrl'] ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.fastfood),
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
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '\$${menuItemData['price']?.toString() ?? '0'}',
                            style: GoogleFonts.poppins(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black54),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
