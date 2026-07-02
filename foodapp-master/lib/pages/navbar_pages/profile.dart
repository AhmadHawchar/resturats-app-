import 'package:apptest/pages/auth/ask_user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apptest/pages/navbar_pages/order.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();

        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>?;
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error fetching user data: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPaymentMethodDialog() {
    final paymentMethods = ['Cash', 'Visa', 'PayPal'];
    String? selectedPaymentMethod = _userData?['paymentMethod'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Update Payment Method',
            style: GoogleFonts.poppins(),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: paymentMethods.map((method) {
              return RadioListTile<String>(
                title: Text(method),
                value: method,
                groupValue: selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    selectedPaymentMethod = value;
                  });
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedPaymentMethod != null) {
                  try {
                    await _firestore
                        .collection('users')
                        .doc(_auth.currentUser!.uid)
                        .update({
                      'paymentMethod': selectedPaymentMethod,
                    });

                    // Refresh user data
                    await _fetchUserData();

                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment method updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating payment method: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMapWidget() {
    // Check if location data exists and is complete
    if (_userData == null ||
        _userData?['location'] == null ||
        _userData?['location']['latitude'] == null ||
        _userData?['location']['longitude'] == null) {
      return Text(
        'Location not available',
        style: GoogleFonts.poppins(color: Colors.grey),
      );
    }

    return Container(
      height: 200,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
              double.parse(_userData?['location']['latitude']),
              double.parse(_userData?['location']['longitude']),
            ),
            initialZoom: 15.0,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.none, // Disable map interactions
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    double.parse(_userData?['location']['latitude']),
                    double.parse(_userData?['location']['longitude']),
                  ),
                  width: 80,
                  height: 80,
                  child: Icon(
                    Icons.location_pin,
                    color: Theme.of(context).primaryColor,
                    size: 50,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _signOut() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AskUserPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 50),
                    SizedBox(height: 10),
                    Container(
                      width: 200,
                      height: 20,
                      color: Colors.white,
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: 150,
                      height: 15,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                // Background color and top section
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFFD53A57),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile Picture (Avatar)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                    _userData?['profileImageUrl'] != null
                                        ? NetworkImage(
                                            _userData!['profileImageUrl'])
                                        : AssetImage(
                                                'assets/default_profile.png')
                                            as ImageProvider,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _userData?['displayName'] ?? 'User Name',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _auth.currentUser?.email ??
                                      'user@example.com',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 10),
                                // Text(
                                //   _userData?['location'] ?? 'Location',
                                //   style: TextStyle(
                                //     color: Colors.white70,
                                //     fontSize: 14,
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom Container
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.75,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width * 0.06,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          _ProfileListItem(
                            icon: Icons.account_balance_wallet,
                            title: 'Payment Method',
                            subtitle:
                                _userData?['paymentMethod'] ?? 'Not selected',
                            onTap: _showPaymentMethodDialog,
                          ),
                          const SizedBox(height: 10),
                          _ProfileListItem(
                            icon: Icons.description,
                            title: 'Orders',
                            subtitle: 'View your past and current orders',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => OrderPage()),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Address',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildLocationMapWidget(),
                          const SizedBox(height: 30),
                          InkWell(
                            onTap: _signOut,
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Log Out',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(color: Colors.grey),
      ),
      trailing: Icon(Icons.edit, color: Colors.grey),
      onTap: onTap,
    );
  }
}
