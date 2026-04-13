import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({Key? key}) : super(key: key);

  @override
  _OwnerHomePageState createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  final String ownerId = "eY3B3EvHvxa1BcKLwEZ79BPDQVG2";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Color Palette
  final Color _primaryColor = const Color(0xFFD75A88);
  final Color _backgroundColor = const Color(0xFFF3E5F5);
  final Color _cardColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Owner Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('owners').doc(ownerId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'No owner information found',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.black54,
                ),
              ),
            );
          }

          // Parse owner data
          Map<String, dynamic> ownerData =
              snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  _buildProfileHeader(ownerData),

                  const SizedBox(height: 20),

                  // Profit Card
                  _buildProfitCard(ownerData),

                  const SizedBox(height: 20),

                  // Additional Information Cards
                  _buildInfoCards(ownerData),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> ownerData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 60,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            ownerData['email'] ?? 'No Email',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(Map<String, dynamic> ownerData) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Profit',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '\$${ownerData['totalProfit']?.toStringAsFixed(2) ?? '0.00'}',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards(Map<String, dynamic> ownerData) {
    return Column(
      children: [
        // Last Commission Update Card
        _buildInfoCard(
          icon: Icons.calendar_today,
          title: 'Last Commission Update',
          value: ownerData['lastCommissionUpdate'] != null
              ? DateFormat('yyyy-MM-dd HH:mm').format(
                  (ownerData['lastCommissionUpdate'] as Timestamp).toDate())
              : 'No recent updates',
        ),

        const SizedBox(height: 10),

        // Last Commission Amount Card
        _buildInfoCard(
          icon: Icons.monetization_on,
          title: 'Last Commission Amount',
          value:
              '\$${ownerData['lastCommissionAmount']?.toStringAsFixed(2) ?? '0.00'}',
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: _primaryColor,
          size: 30,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}
