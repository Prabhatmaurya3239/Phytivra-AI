import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/primary_button.dart';
import '../widgets/language_toggel.dart';
import '../core/app_theme.dart';
import '../core/localization/app_strings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isEnglish = appState.isEnglish;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.get('app_title', isEnglish: isEnglish)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: LanguageToggleWidget(
                  isEnglish: isEnglish,
                  onToggle: (val) => appState.toggleLanguage(val),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Farmer Welcome Card
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade900.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get('home_greeting', isEnglish: isEnglish),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.get('home_tagline', isEnglish: isEnglish),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFE8F5E9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Main Action Card: Start Diagnosis
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(
                      color: Color(0xFFC8E6C9),
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.lightGreen,
                          child: Icon(
                            Icons.document_scanner,
                            size: 40,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.get(
                            'quick_diagnosis',
                            isEnglish: isEnglish,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.get(
                            'upload_instructions',
                            isEnglish: isEnglish,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          text: AppStrings.get(
                            'start_diagnosis',
                            isEnglish: isEnglish,
                          ),
                          icon: Icons.camera_alt,
                          onPressed: () {
                            appState.resetWorkflow();
                            Navigator.pushNamed(context, '/upload');
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Farmer Photo Quality Tips
                Card(
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.amber.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates,
                              color: Colors.amber.shade900,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEnglish
                                  ? 'Photography Tips for Accurate AI'
                                  : 'सटीक जांच के लिए आवश्यक सुझाव',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown.shade900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildTipItem(
                          isEnglish
                              ? 'Focus closely on visible spots or leaf discoloration.'
                              : 'पत्ती पर दिख रहे धब्बों या लक्षणों पर कैमरा फोकस करें।',
                        ),
                        _buildTipItem(
                          isEnglish
                              ? 'Take photo in natural sunlight; avoid heavy shadows.'
                              : 'प्राकृतिक धूप में फोटो लें, तेज छाया से बचें।',
                        ),
                        _buildTipItem(
                          isEnglish
                              ? 'Capture a single affected leaf for best results.'
                              : 'बेहतर परिणाम के लिए एक समय में एक ही पत्ती की फोटो लें।',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.brown.shade800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
