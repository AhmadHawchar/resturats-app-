import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:apptest/pages/splash_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with specific configuration
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyAjJO0DkylQJa72ex4YDQ4wiIeO1kw6AA8",
        projectId: "apptestshop-d75aa",
        messagingSenderId: "223469946880",
        appId: "1:223469946880:android:5770e23b39d36f787870e5",
        storageBucket: "apptestshop-d75aa.firebasestorage.app",
      ),
    );

    // Run the app
    runApp(const MyApp());
  } catch (e) {
    // Handle Firebase initialization error
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('an error has occured with your firebase'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
