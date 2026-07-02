import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:apptest/pages/splash_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load secrets from the (gitignored) .env file
    await dotenv.load(fileName: ".env");

    // Initialize Firebase using configuration from environment variables
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
        appId: dotenv.env['FIREBASE_APP_ID']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
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
            child: Text('An error occurred while initializing Firebase'),
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
