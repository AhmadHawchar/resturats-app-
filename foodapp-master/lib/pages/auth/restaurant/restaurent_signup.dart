import 'package:apptest/pages/auth/restaurant/restau_info_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';

class RestaurantSignupPage extends StatefulWidget {
  const RestaurantSignupPage({super.key});

  @override
  _RestaurantSignupPageState createState() => _RestaurantSignupPageState();
}

class _RestaurantSignupPageState extends State<RestaurantSignupPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _restaurantNameController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _restaurantNameController.dispose();
    super.dispose();
  }

  Future<void> _signupRestaurant() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _firestore
          .collection('restaurants')
          .doc(userCredential.user!.uid)
          .set({
        'email': _emailController.text.trim(),
        'restaurantName': _restaurantNameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'restaurant',
        'isActive': true,
      });

      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Signup failed. ';
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage += 'Email is already registered.';
          break;
        case 'weak-password':
          errorMessage += 'Password is too weak.';
          break;
        default:
          errorMessage += 'Please check your details.';
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

  bool _validateInputs() {
    if (_emailController.text.trim().isEmpty) {
      _showErrorDialog('Please enter an email');
      return false;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showErrorDialog('Please enter a valid email');
      return false;
    }

    if (_restaurantNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a restaurant name');
      return false;
    }

    if (_passwordController.text.trim().length < 6) {
      _showErrorDialog('Password must be at least 6 characters');
      return false;
    }

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      _showErrorDialog('Passwords do not match');
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Signup Successful',
          style: GoogleFonts.poppins(
              color: Colors.green, fontWeight: FontWeight.bold),
        ),
        content: Lottie.asset(
          'assets/splash.json',
          height: 150,
          repeat: false,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => RestaurantInfoPage()));
            },
            child: Text('Continue',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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
          'Signup Error',
          style: GoogleFonts.poppins(
              color: Colors.red, fontWeight: FontWeight.bold),
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

  Widget _buildShimmerLottieLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 250,
        width: double.infinity,
        color: Colors.white,
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
                // Animated Lottie Animation
                FadeInDown(
                  controller: (controller) => _animationController,
                  child: FutureBuilder(
                    future: Future.delayed(
                        Duration(milliseconds: 500)), // Simulate loading
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildShimmerLottieLoader();
                      }
                      return Lottie.asset(
                        'assets/restaurant_signup.json',
                        height: 250,
                        fit: BoxFit.contain,
                        frameBuilder: (context, child, composition) {
                          if (composition == null) {
                            return _buildShimmerLottieLoader();
                          }
                          return child;
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Animated Signup Container
                FadeInUp(
                  controller: (controller) => _animationController,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(0, 10),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.blue.shade50,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Title with Animation
                          FadeInRight(
                            controller: (controller) => _animationController,
                            child: Text(
                              'Restaurant Signup',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Animated Text Fields
                          _buildAnimatedTextField(
                            controller: _restaurantNameController,
                            labelText: 'Restaurant Name',
                            icon: Icons.restaurant,
                            animationDelay: 200,
                          ),

                          const SizedBox(height: 20),

                          _buildAnimatedTextField(
                            controller: _emailController,
                            labelText: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            animationDelay: 400,
                          ),

                          const SizedBox(height: 20),

                          _buildAnimatedPasswordField(
                            controller: _passwordController,
                            labelText: 'Password',
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            animationDelay: 600,
                          ),

                          const SizedBox(height: 20),

                          _buildAnimatedPasswordField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm Password',
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            animationDelay: 800,
                          ),

                          const SizedBox(height: 30),

                          // Animated Signup Button
                          FadeInUp(
                            controller: (controller) => _animationController,
                            delay: Duration(milliseconds: 1000),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signupRestaurant,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFD8700),
                                padding: EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text(
                                      'Sign Up',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required int animationDelay,
  }) {
    return FadeInLeft(
      controller: (controller) => _animationController,
      delay: Duration(milliseconds: animationDelay),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: Colors.blue.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required int animationDelay,
  }) {
    return FadeInRight(
      controller: (controller) => _animationController,
      delay: Duration(milliseconds: animationDelay),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(Icons.lock, color: Colors.blue.shade400),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.blue.shade400,
            ),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
        ),
      ),
    );
  }
}
