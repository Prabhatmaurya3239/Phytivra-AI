import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.language, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                'Select Your Language\nअपनी भाषा चुनें',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              // English and Hindi Options[cite: 2]
              Card(
                color: selectedLanguage == 'English' ? Colors.green.shade50 : Colors.white,
                child: ListTile(
                  title: const Text('English', style: TextStyle(fontSize: 18)),
                  trailing: selectedLanguage == 'English' 
                      ? const Icon(Icons.check_circle, color: Colors.green) 
                      : null,
                  onTap: () => setState(() => selectedLanguage = 'English'),
                ),
              ),
              Card(
                color: selectedLanguage == 'Hindi' ? Colors.green.shade50 : Colors.white,
                child: ListTile(
                  title: const Text('हिंदी (Hindi)', style: TextStyle(fontSize: 18)),
                  trailing: selectedLanguage == 'Hindi' 
                      ? const Icon(Icons.check_circle, color: Colors.green) 
                      : null,
                  onTap: () => setState(() => selectedLanguage = 'Hindi'),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Continue',
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 