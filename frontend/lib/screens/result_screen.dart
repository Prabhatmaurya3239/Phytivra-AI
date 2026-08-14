import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
// Note: Assuming you still have InfoCard in lib/widgets/info_card.dart

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Disease Image Placeholder[cite: 2]
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            
            // Disease Severity badge[cite: 2]
            const Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text('Severity: High', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.red,
              ),
            ),
            
            // Required Text Fields[cite: 2]
            const Card(
              child: ListTile(
                title: Text('Crop Name', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                subtitle: Text('Tomato (Solanum lycopersicum)', style: TextStyle(fontSize: 16)),
              ),
            ),
            const Card(
              child: ListTile(
                title: Text('Disease Name', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                subtitle: Text('Early Blight', style: TextStyle(fontSize: 16)),
              ),
            ),
            const Card(
              child: ListTile(
                title: Text('Confidence Percentage', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                subtitle: Text('98.5%', style: TextStyle(fontSize: 16)),
              ),
            ),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Disease Description', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Early blight is a fungal disease that causes brown or black spots on leaves, stems, and fruits, often with concentric rings.'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            // View Recommendation Button[cite: 2]
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