import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:apptest/pages/auth/owner/ownerlogin.dart';
import 'package:apptest/pages/auth/restaurant/restaurant_login.dart';
import 'package:apptest/pages/auth/client/client_login.dart';

class AskUserPage extends StatelessWidget {
  const AskUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.deepPurple.shade50,
                Colors.deepPurple.shade100,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              Lottie.asset(
                'assets/splash.json',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 30),

              // Title
              Text(
                'Welcome to FoodApp',
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                ),
              ),

              const SizedBox(height: 20),

              // Subtitle
              Text(
                'Choose Your Role',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.deepPurple.shade600,
                ),
              ),

              const SizedBox(height: 40),

              // Authentication Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    _buildRoleButton(
                      context,
                      'an Owner',
                      Icons.business_center_rounded,
                      Colors.deepPurple.shade400,
                      () {
                        // Navigate to owner login
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const OwnerLoginPage()));
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildRoleButton(
                      context,
                      'Restaurant',
                      Icons.restaurant_rounded,
                      Colors.green.shade400,
                      () {
                        // Navigate to restaurant login
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const RestaurantLoginPage()));
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildRoleButton(
                      context,
                      'Client',
                      Icons.person_rounded,
                      Colors.blue.shade400,
                      () {
                        // Navigate to client login
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ClientLoginPage()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context,
    String role,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 10),
          Text(
            'Continue as $role',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
