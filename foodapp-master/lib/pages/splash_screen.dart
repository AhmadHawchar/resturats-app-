import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:apptest/pages/auth/ask_user.dart'; // Adjust this import as needed

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Navigate to ask user page after animation completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AskUserPage()),
        );
      }
    });

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white, // Choose a background color that matches your app theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie animation - replace with your specific Lottie JSON file
            Lottie.asset(
              'assets/splash.json', // Make sure to add this file to your assets
              controller: _controller,
              width: 300,
              height: 300,
              fit: BoxFit.contain,
              repeat: false,
            ),
            const SizedBox(height: 20),
            const Text(
              'Food App', // Replace with your app name
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color:
                    Colors.deepPurple, // Choose a color that matches your theme
              ),
            ),
          ],
        ),
      ),
    );
  }
}
