import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Make sure this matches the file you created earlier!
import 'screens/upload_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/result_screen.dart';
import 'screens/ai_recommendation_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const CropDiseaseApp());
}

class CropDiseaseApp extends StatelessWidget {
  const CropDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crop Disease Detector',
      theme: ThemeData(
        primarySwatch: Colors.green, // Keeping it farmer-friendly
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/home', // Starting at home for testing purposes
      // Basic Navigation implemented for all required screens[cite: 1]
      routes: {
        '/splash': (context) => const DummyScreen(title: '1. Splash Screen'),
        '/language': (context) => const LanguageSelectionScreen(/*title: '2. Language Selection'*/),
        '/home': (context) => const HomeScreen(), // The screen we built in Phase 2!
        '/upload': (context) => const UploadScreen(/*title: '4. Upload Image'*/),
        '/processing': (context) => const ProcessingScreen(/*title: '5. Processing/Loading'*/),
        '/result': (context) => const ResultScreen(/*title: '6. Disease Result'*/),
        '/recommendation': (context) => const AiRecommendationScreen(/*title: '7. AI Recommendation'*/),
        '/settings': (context) => const SettingsScreen(/*title: '8. Settings Placeholder'*/),
      },
    );
  }
}

// A temporary dummy screen to satisfy the placeholder requirement[cite: 1]
class DummyScreen extends StatelessWidget {
  final String title;
  const DummyScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Placeholder for $title', 
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}