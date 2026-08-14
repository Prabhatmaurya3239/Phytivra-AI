import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart'; // The one we built earlier!

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _hasImage = false; // Simulates state management for the UI

  void _simulateImageSelect() {
    setState(() => _hasImage = true);
  }

  void _removeImage() {
    setState(() => _hasImage = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Crop Image')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Preview Selected Image area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: _hasImage
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.grass, size: 120, color: Colors.green), // Dummy preview
                          Positioned(
                            top: 8,
                            right: 8,
                            // Remove Image button
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                              onPressed: _removeImage,
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('No image selected', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Select Image from Gallery & Capture from Camera[cite: 2]
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Camera',
                    icon: Icons.camera_alt,
                    onPressed: _simulateImageSelect, 
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    text: 'Gallery',
                    icon: Icons.photo_library,
                    onPressed: _simulateImageSelect,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Continue Button[cite: 2]
            PrimaryButton(
              text: 'Continue',
              icon: Icons.arrow_forward,
              onPressed: _hasImage 
                  ? () => Navigator.pushNamed(context, '/processing') 
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an image first!')),
                      );
                    },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}