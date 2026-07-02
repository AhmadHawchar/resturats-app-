import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';

import '../../navbar.dart';

class ClientInfoPage extends StatefulWidget {
  const ClientInfoPage({super.key});

  @override
  _ClientInfoPageState createState() => _ClientInfoPageState();
}

class _ClientInfoPageState extends State<ClientInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  File? _imageFile;
  String? _profileImageUrl;
  String _selectedPaymentMethod = '';

  String? _latitude;
  String? _longitude;
  String? _locationName;

  final List<String> _paymentMethods = [
    'Cash',
    'Visa',
    'PayPal',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    String? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationPickerPage()),
    );

    if (selectedLocation != null) {
      // Split the location string into coordinates and name
      List<String> locationParts = selectedLocation.split('|');

      if (locationParts.length == 2) {
        // Parse coordinates
        List<String> coordinates = locationParts[0].split(',');
        if (coordinates.length == 2) {
          setState(() {
            _latitude = coordinates[0];
            _longitude = coordinates[1];
            _locationName = locationParts[1];

            // Update location controller with location details
            _locationController.text =
                '$_locationName\nLat: $_latitude, Lon: $_longitude';
          });
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      await _uploadImageToImgBB();
    }
  }

  Future<void> _uploadImageToImgBB() async {
    if (_imageFile == null) return;

    // ImgBB API key
    const apiKey = 'd97d7227eca3b349cbf52ad09b50bafd';

    try {
      // Prepare multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload'),
      );

      request.fields['key'] = apiKey;
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _imageFile!.path,
          filename: path.basename(_imageFile!.path),
        ),
      );

      // Send request
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      // Parse response
      final responseJson = json.decode(responseBody);

      if (response.statusCode == 200 && responseJson['success']) {
        // Extract image URL from response
        String imageUrl = responseJson['data']['url'];

        setState(() {
          _profileImageUrl = imageUrl;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Handle upload failure
        throw Exception(responseJson['error']['message'] ?? 'Upload failed');
      }
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveUserInfo() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    // Validate location is selected
    if (_latitude == null || _longitude == null || _locationName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    // Check if profile image is uploaded
    if (_profileImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload a profile image')),
      );
      return;
    }

    try {
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Update Firestore document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'displayName': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'location': {
            'name': _locationName,
            'latitude': _latitude,
            'longitude': _longitude,
          },
          'profileImageUrl': _profileImageUrl,
          'paymentMethod': _selectedPaymentMethod,
          'profileCompleted': true,
        });

        // Navigate to next page or show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile Updated Successfully')),
        );

        // Optional: Navigate to next page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => NavbarScreen()),
        );
      }
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Complete Your Profile',
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Picture Upload
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null
                          ? Icon(
                              Icons.camera_alt,
                              size: 50,
                              color: Colors.grey[800],
                            )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),

                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),

                // Location Input with Map Picker
                GestureDetector(
                  onTap: _pickLocation,
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(Icons.location_on),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.map),
                          onPressed: _pickLocation,
                        ),
                      ),
                      maxLines: 2,
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a location';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // Payment Method Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Payment Method',
                  ),
                  value: _selectedPaymentMethod.isEmpty
                      ? null
                      : _selectedPaymentMethod,
                  hint: Text('Select Payment Method'),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPaymentMethod = newValue ?? '';
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a payment method';
                    }
                    return null;
                  },
                  items: _paymentMethods
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 30),

                // Save Button
                ElevatedButton(
                  onPressed: _saveUserInfo,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text('Save Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Location Picker Page
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  _LocationPickerPageState createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  LatLng? _selectedLocation;
  String? _selectedLocationName;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchSuggestions = [];
  MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Set initial location to Lebanon center
    _selectedLocation = LatLng(33.8547, 35.8623);
    _mapController = MapController();

    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Debounce search suggestions
    if (_searchController.text.length >= 3) {
      _fetchSearchSuggestions(_searchController.text);
    } else {
      setState(() {
        _searchSuggestions.clear();
      });
    }
  }

  Future<void> _fetchSearchSuggestions(String query) async {
    try {
      // Use geocoding to get location suggestions
      List<Location> locations = await locationFromAddress(query);

      // Create more detailed suggestions
      List<Map<String, dynamic>> suggestions = locations.map((location) {
        return {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'displayName': query, // Use the original search query as display name
        };
      }).toList();

      setState(() {
        _searchSuggestions = suggestions;
      });
    } catch (e) {
      // Clear suggestions if no results found
      setState(() {
        _searchSuggestions.clear();
      });
    }
  }

  void _searchLocation() async {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a location')),
      );
      return;
    }

    try {
      // Geocode the entered location
      List<Location> locations =
          await locationFromAddress(_searchController.text);

      if (locations.isNotEmpty) {
        Location location = locations.first;

        // Update selected location
        setState(() {
          _selectedLocation = LatLng(location.latitude, location.longitude);
        });

        // Reverse geocode to get detailed location name
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _selectedLocationName = _formatPlacemark(place);
          });
        }

        // Zoom and center map on the location
        _mapController.move(LatLng(location.latitude, location.longitude),
            12.0 // Closer zoom level
            );

        // Clear suggestions
        _searchSuggestions.clear();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not find the location. Please try again.')),
      );
    }
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    // Update search controller
    _searchController.text = suggestion['displayName'];

    // Update selected location
    setState(() {
      _selectedLocation =
          LatLng(suggestion['latitude'], suggestion['longitude']);
      _searchSuggestions.clear();
    });

    // Zoom and center map
    _mapController.move(LatLng(suggestion['latitude'], suggestion['longitude']),
        12.0 // Closer zoom level
        );
  }

  String _formatPlacemark(Placemark placemark) {
    return '${placemark.street}, ${placemark.locality}, ${placemark.country}';
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) async {
    try {
      // Reverse geocode the selected location
      List<Placemark> placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _selectedLocation = point;
          _selectedLocationName = _formatPlacemark(place);
        });
      }
    } catch (e) {
      setState(() {
        _selectedLocation = point;
        _selectedLocationName = 'Unnamed Location';
      });
    }
  }

  void _saveLocation() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a location first')),
      );
      return;
    }

    // Convert location to a string representation with name
    String locationString =
        '${_selectedLocation!.latitude},${_selectedLocation!.longitude}|${_selectedLocationName ?? ''}';

    // Return the location string to the previous screen
    Navigator.of(context).pop(locationString);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Location',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar with Suggestions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search location',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: _searchLocation,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onSubmitted: (_) => _searchLocation(),
                ),

                // Search Suggestions
                if (_searchSuggestions.isNotEmpty)
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: 200, // Limit height
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _searchSuggestions[index];
                        return ListTile(
                          title: Text(
                            suggestion['displayName'],
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${suggestion['latitude']}, ${suggestion['longitude']}',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Expanded Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(33.8547, 35.8623), // Lebanon center
                initialZoom: 7.0,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 100,
                        height: 100,
                        child: Column(
                          children: [
                            Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 50,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Location Info and Confirm Button
          if (_selectedLocationName != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _selectedLocationName!,
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Latitude: ${_selectedLocation?.latitude.toStringAsFixed(6) ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Longitude: ${_selectedLocation?.longitude.toStringAsFixed(6) ?? 'N/A'}',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _saveLocation,
              icon: Icon(Icons.check_circle),
              label: Text(
                'Confirm Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
