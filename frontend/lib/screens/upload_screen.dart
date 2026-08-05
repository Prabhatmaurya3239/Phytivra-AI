import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Crop Image'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Selected image preview placeholder[cite: 1]
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 80, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('No image selected', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Camera and Gallery buttons[cite: 1]
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    text: 'Camera',
                    icon: Icons.camera_alt,
                    onPressed: () {}, // No logic required today[cite: 1]
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    text: 'Gallery',
                    icon: Icons.photo_library,
                    onPressed: () {}, // No logic required today[cite: 1]
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Continue button[cite: 1]
            PrimaryButton(
              text: 'Continue',
              icon: Icons.check_circle,
              // Routes to the Processing screen when clicked
              onPressed: () => Navigator.pushNamed(context, '/processing'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}