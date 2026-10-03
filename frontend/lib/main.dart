import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/result_screen.dart';
import 'screens/questions_screen.dart';
import 'screens/ai_recommendation_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/voice_chat_screen.dart';
import 'core/app_theme.dart';
import 'providers/app_state_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppStateProvider(),
      child: const CropDiseaseApp(),
    ),
  );
}

class CropDiseaseApp extends StatelessWidget {
  const CropDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Phytivra-AI Crop Advisor',
      theme: AppTheme.lightTheme,
      initialRoute: '/home',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/language': (context) => const LanguageSelectionScreen(),
        '/home': (context) => const HomeScreen(),
        '/upload': (context) => const UploadScreen(),
        '/processing': (context) => const ProcessingScreen(),
        '/result': (context) => const ResultScreen(),
        '/questions': (context) => const QuestionsScreen(),
        '/recommendation': (context) => const AiRecommendationScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/voice_chat': (context) => const VoiceChatScreen(),
      },
    );
  }
}
