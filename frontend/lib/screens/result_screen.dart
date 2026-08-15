import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../models/disease_result_model.dart'; // We need this to read the model!
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Catch the model passed from the ProcessingScreen
    final result = ModalRoute.of(context)?.settings.arguments as DiseaseResultModel?;

    // 2. Safety check: If someone routes here without data, show an error
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('No result data found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Disease Image Placeholder (we'll hook up the real image URL later)[cite: 2]
            // Dynamic Image Display (Replaced the dummy placeholder!)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300, width: 2),
              ),
              child: result.imageUrl != null 
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: kIsWeb 
                          ? Image.network(
                              result.imageUrl!, 
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(result.imageUrl!), 
                              fit: BoxFit.cover,
                            ),
                    )
                  : const Center(
                      // This fallback triggers if the JSON doesn't actually have an image
                      child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 20),
            
            // Dynamic Severity badge[cite: 2]
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text('Severity: ${result.severity}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.red,
              ),
            ),
            
            // Required Text Fields now reading from the Model![cite: 2]
            Card(
              child: ListTile(
                title: const Text('Crop Name', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                subtitle: Text(result.cropName, style: const TextStyle(fontSize: 16)),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Disease Name', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                subtitle: Text(result.diseaseName, style: const TextStyle(fontSize: 16)),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Confidence Percentage', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                // Multiplies the 0.95 decimal by 100 to make it look nice
                subtitle: Text('${(result.confidence * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 16)),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Disease Description', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(result.description),
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