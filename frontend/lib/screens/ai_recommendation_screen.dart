import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/language_toggel.dart'; // Keeping your spelling!
import '../models/recommendation_model.dart';

// Changed to a StatelessWidget since the Provider handles our state now
class AiRecommendationScreen extends StatelessWidget {
  const AiRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Catch the real model if it gets passed from the previous screen...
    final passedModel = ModalRoute.of(context)?.settings.arguments as RecommendationModel?;
    
    // ...otherwise, use this dummy data so the app doesn't crash while we test!
    final rec = passedModel ?? RecommendationModel(
      recommendedTreatment: 'Immediate application of fungicides and isolation of severely affected plants.',
      pesticideName: 'Chlorothalonil 75% WP',
      companyName: 'AgriCare Corp',
      priceRange: '₹450 - ₹550',
      packingSize: '500g',
      dosage: '2.5 grams per liter of water',
      sprayMethod: 'Foliar spray, covering both sides of leaves evenly.',
      precautions: 'Wear protective gear (gloves, mask) while spraying. Do not harvest within 7 days of chemical application.',
      organicAlternatives: 'Copper-based fungicide or Neem oil extract (5ml per liter).',
      preventiveMeasures: '• Practice crop rotation.\n• Ensure proper spacing for air circulation.\n• Avoid overhead irrigation.',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        actions: [
         Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Consumer<AppStateProvider>(
              builder: (context, appState, child) {
                return LanguageToggleWidget(
                  isEnglish: appState.isEnglish,
                  onToggle: (val) {
                    appState.toggleLanguage(val); 
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Recommended Treatment
          RecommendationSection(
            title: 'Recommended Treatment',
            icon: Icons.healing,
            content: rec.recommendedTreatment,
          ),
          
          // 2-7. The specific pesticide details[cite: 2]
          Card(
            elevation: 3,
            color: Colors.blueGrey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pesticide Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const Divider(),
                  _buildDetailRow('Chemical Name', rec.pesticideName),
                  _buildDetailRow('Company Name', rec.companyName),
                  _buildDetailRow('Price Range', rec.priceRange),
                  _buildDetailRow('Packing Size', rec.packingSize),
                  _buildDetailRow('Dosage', rec.dosage),
                  _buildDetailRow('Spray Method', rec.sprayMethod),
                ],
              ),
            ),
          ),
          
          // 8. Organic Alternatives[cite: 2]
          RecommendationSection(
            title: 'Organic Alternative',
            icon: Icons.eco,
            content: rec.organicAlternatives,
          ),
          
          // 9. Preventive Measures[cite: 2]
          RecommendationSection(
            title: 'Preventive Measures',
            icon: Icons.shield,
            content: rec.preventiveMeasures,
          ),
          
          // 10. Precautions[cite: 2]
          RecommendationSection(
            title: 'Precautions',
            icon: Icons.warning_amber,
            content: rec.precautions,
          ),
        ],
      ),
    );
  }

  // A tiny custom widget to keep the pesticide details clean and aligned
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value)),
        ],
      ),
    );
  }
}

// Keeping your local widget exactly how you designed it
class RecommendationSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const RecommendationSection({
    super.key,
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            Text(content, style: const TextStyle(fontSize: 16, height: 1.4)),
          ],
        ),
      ),
    );
  }
}