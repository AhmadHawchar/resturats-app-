import 'dart:io';
import 'dart:convert';
import 'package:apptest/pages/auth/restaurant/restaurent_admin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class RestaurantInfoPage extends StatefulWidget {
  const RestaurantInfoPage({super.key});

  @override
  State<RestaurantInfoPage> createState() => _RestaurantInfoPageState();
}

class _RestaurantInfoPageState extends State<RestaurantInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _imgbbApiKey = 'd97d7227eca3b349cbf52ad09b50bafd';

  File? _imageFile;
  String? _imageUrl;
  Position? _selectedLocation;
  bool _isLoading = false;

  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Color palette
  final Color _primaryColor = const Color(0xFF6A1B9A); // Deep Purple
  final Color _accentColor = const Color(0xFFAB47BC); // Light Purple
  final Color _backgroundColor = const Color(0xFFF3E5F5); // Very Light Purple

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToImgbb() async {
    if (_imageFile == null) return null;

    try {
      setState(() {
        _isLoading = true;
      });

      var request = http.MultipartRequest(
          'POST', Uri.parse('https://api.imgbb.com/1/upload'));

      request.fields['key'] = _imgbbApiKey;
      request.files
          .add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseBody);

      setState(() {
        _isLoading = false;
      });

      if (jsonResponse['success']) {
        return jsonResponse['data']['url'];
      } else {
        _showErrorDialog('Image upload failed');
        return null;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error uploading image');
      return null;
    }
  }

  Future<void> _saveRestaurantInfo() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });

        final user = _auth.currentUser;
        if (user == null) throw Exception('No authenticated user');

        // Upload image to Imgbb
        _imageUrl = await _uploadImageToImgbb();

        // Save restaurant info
        await _firestore.collection('restaurants').doc(user.uid).set({
          'info': _infoController.text,
          'contact': _contactController.text,
          'address': _addressController.text,
          'imageUrl': _imageUrl,
          'location': _selectedLocation != null
              ? GeoPoint(
                  _selectedLocation!.latitude, _selectedLocation!.longitude)
              : null,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        setState(() {
          _isLoading = false;
        });

        _showSuccessDialog();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error saving restaurant information');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Okay',
              style: GoogleFonts.poppins(color: _primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Restaurant Information Saved Successfully!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => RestaurantAdminPage()));
            },
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(color: _primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Restaurant Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Upload Section
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                colors: [_primaryColor, _accentColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: _imageFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.file(
                                      _imageFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cloud_upload,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          'Upload Restaurant Image',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Restaurant Info
                      _buildTextField(
                        controller: _infoController,
                        label: 'Restaurant Information',
                        icon: Icons.info_outline,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Contact Number
                      _buildTextField(
                        controller: _contactController,
                        label: 'Contact Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Address
                      _buildTextField(
                        controller: _addressController,
                        label: 'Restaurant Address',
                        icon: Icons.location_on,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _saveRestaurantInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Save Restaurant Information',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: _primaryColor),
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _infoController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
