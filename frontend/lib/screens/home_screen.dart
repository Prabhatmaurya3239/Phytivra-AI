import 'package:flutter/material.dart';
import '../widgets/primary_button.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () => Navigator.pushNamed(context, '/language'), // Language switch[cite: 1]
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.grass, size: 100, color: Colors.green), // Placeholder App Logo[cite: 1]
            const SizedBox(height: 20),
            const Text(
              'Welcome to CropCare!', // Welcome message[cite: 1]
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              text: 'Upload Image', // Upload Image button[cite: 1]
              icon: Icons.upload_file,
              onPressed: () => Navigator.pushNamed(context, '/upload'),
            ),
            const SizedBox(height: 15),
            PrimaryButton(
              text: 'Previous Scan', // Previous scan placeholder[cite: 1]
              icon: Icons.history,
              onPressed: () {
                // Do nothing for now
              },
            ),
          ],
        ),
      ),
    );
  }
}