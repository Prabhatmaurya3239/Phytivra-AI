import 'package:crop_app/widgets/language_toggel.dart';
import 'package:flutter/material.dart';


class AiRecommendationScreen extends StatefulWidget {
  const AiRecommendationScreen({super.key});

  @override
  State<AiRecommendationScreen> createState() => _AiRecommendationScreenState();
}

class _AiRecommendationScreenState extends State<AiRecommendationScreen> {
  bool _isEnglish = true; // State for the language toggle[cite: 2]

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        actions: [
          // Language Switch embedded in AppBar[cite: 2]
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: LanguageToggleWidget(
              isEnglish: _isEnglish,
              onToggle: (val) => setState(() => _isEnglish = val),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          // Disease Summary[cite: 2]
          RecommendationSection(
            title: 'Disease Summary',
            icon: Icons.analytics,
            content: 'The crop is severely affected by Early Blight. Immediate action is required to prevent spread to adjacent healthy plants.',
          ),
          
          // Recommended Pesticide details[cite: 2]
          Card(
            elevation: 3,
            color: Colors.blueGrey,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recommended Pesticide', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Chemical Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Chlorothalonil 75% WP'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Company Name', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('AgriCare Corp / Syngenta'), // Company Name[cite: 2]
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Dosage', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('2.5 grams per liter of water'), // Dosage[cite: 2]
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Spray Method', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Foliar spray, covering both sides of leaves evenly.'), // Spray Method[cite: 2]
                  ),
                ],
              ),
            ),
          ),
          
          // Organic Alternative[cite: 2]
          RecommendationSection(
            title: 'Organic Alternative',
            icon: Icons.eco,
            content: 'Use a Copper-based fungicide or Neem oil extract (5ml per liter). Ensure application during early morning or late evening.',
          ),
          
          // Preventive Measures[cite: 2]
          RecommendationSection(
            title: 'Preventive Measures',
            icon: Icons.shield,
            content: '• Practice crop rotation.\n• Ensure proper spacing for air circulation.\n• Avoid overhead irrigation.',
          ),
          
          // Precautions[cite: 2]
          RecommendationSection(
            title: 'Precautions',
            icon: Icons.warning_amber,
            content: 'Wear protective gear (gloves, mask) while spraying. Do not harvest within 7 days of chemical application.',
          ),
        ],
      ),
    );
  }
}

// A local widget specifically for formatting these heavy text sections cleanly
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