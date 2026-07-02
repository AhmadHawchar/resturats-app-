import 'package:apptest/pages/auth/client/client_signup.dart';
import 'package:apptest/pages/navbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ClientLoginPage extends StatefulWidget {
  const ClientLoginPage({super.key});

  @override
  _ClientLoginPageState createState() => _ClientLoginPageState();
}

class _ClientLoginPageState extends State<ClientLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _loginClient() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First, authenticate with Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if the user exists in the owners collection
      DocumentSnapshot clientDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (clientDoc.exists) {
        // Successful owner login
        _showSuccessDialog();
      } else {
        // User is not an owner
        await _auth.signOut();
        _showErrorDialog('Access denied. You are not registered as an owner.');
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      String errorMessage = 'Login failed. ';
      switch (e.code) {
        case 'user-not-found':
          errorMessage += 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage += 'Incorrect password.';
          break;
        default:
          errorMessage += 'Please check your credentials.';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('An unexpected error occurred.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Login Successful',
          style: GoogleFonts.poppins(color: Colors.green),
        ),
        content: Text(
          'Welcome back, Client!',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Navigate to Client Home Page
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => NavbarScreen()));
            },
            child: Text('Continue', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Login Error',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0274BC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Lottie Animation
                Lottie.asset(
                  'assets/splash.json', // Use a client-specific animation if possible
                  height: 250,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 30),

                // Email TextField
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Title
                        Text(
                          'Client Login',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),

                        const SizedBox(height: 30),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon:
                                Icon(Icons.email, color: Colors.blue.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // Password TextField
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon:
                                Icon(Icons.lock, color: Colors.blue.shade400),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.blue.shade400,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          obscureText: _obscurePassword,
                        ),

                        const SizedBox(height: 30),

                        // Login Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _loginClient,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFD8700),
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 20),

                        // Forgot Password
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClientSignupPage(),
                              ),
                            );
                          },
                          child: Text(
                            'dont\'t have an account? Register',
                            style: GoogleFonts.poppins(
                              color: Colors.blue.shade600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
