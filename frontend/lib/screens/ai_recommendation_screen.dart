import 'package:flutter/material.dart';
import '../widgets/info_card.dart';

class AiRecommendationScreen extends StatelessWidget {
  const AiRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recommendation'),
        actions: [
          // The requested language switch button
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => Navigator.pushNamed(context, '/language'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dummy content for all the required sections
            InfoCard(
              title: 'Disease Summary', 
              description: 'Late blight is spreading rapidly due to high humidity.'
            ),
            InfoCard(
              title: 'Recommended Treatment', 
              description: 'Apply fungicide immediately and remove infected leaves.'
            ),
            InfoCard(
              title: 'Suggested Pesticide', 
              description: 'Mancozeb 75% WP (2-2.5 gm per liter of water)'
            ),
            InfoCard(
              title: 'Organic Alternative', 
              description: 'Copper spray or Neem oil solution (5ml per liter of water)'
            ),
            InfoCard(
              title: 'Precautions', 
              description: 'Avoid overhead watering. Ensure proper spacing between plants for air circulation.'
            ),
          ],
        ),
      ),
    );
  }
}