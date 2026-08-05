import 'package:flutter/material.dart';
import '../widgets/info_card.dart';
import '../widgets/primary_button.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.redAccent,
              child: Icon(Icons.warning_amber_rounded, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Dummy information populated via our reusable InfoCard[cite: 1]
            const InfoCard(title: 'Crop Name', description: 'Tomato'),
            const InfoCard(title: 'Disease Name', description: 'Late Blight'),
            const InfoCard(title: 'Confidence Percentage', description: '94%'),
            const InfoCard(
              title: 'Disease Description',
              description: 'Late blight is a potentially devastating disease that can infect potato and tomato plants, causing rotting of leaves, stems, and fruits.',
            ),
            const SizedBox(height: 30),
            // The required button to proceed[cite: 1]
            PrimaryButton(
              text: 'View AI Recommendation',
              icon: Icons.psychology,
              onPressed: () => Navigator.pushNamed(context, '/recommendation'),
            ),
          ],
        ),
      ),
    );
  }
}