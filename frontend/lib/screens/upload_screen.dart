import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // This actually opens the hardware camera or gallery[cite: 2]
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() => _selectedImage = null);
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
                child: _selectedImage != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          // Displays the actual photo you just took[cite: 2]
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.network(
                                  _selectedImage!.path,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit:BoxFit.cover,
                                )
                                :Image.file(
                                  _selectedImage!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
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
            
            // Select Image Buttons[cite: 2]
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Camera',
                    icon: Icons.camera_alt,
                    onPressed: () => _pickImage(ImageSource.camera), // Triggers Camera[cite: 2]
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    text: 'Gallery',
                    icon: Icons.photo_library,
                    onPressed: () => _pickImage(ImageSource.gallery), // Triggers Gallery[cite: 2]
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Continue Button[cite: 2]
            PrimaryButton(
              text: 'Continue',
              icon: Icons.arrow_forward,
              //changed this line
              /*onPressed: _selectedImage != null 
                  ? () => Navigator.pushNamed(context, '/processing') */
              // to this
              onPressed: _selectedImage != null 
                  ? () => Navigator.pushNamed(context, '/processing', arguments: _selectedImage) 
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