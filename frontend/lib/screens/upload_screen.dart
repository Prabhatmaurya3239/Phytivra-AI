// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../widgets/primary_button.dart';
// import '../widgets/secondary_button.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;

// class UploadScreen extends StatefulWidget {
//   const UploadScreen({super.key});

//   @override
//   State<UploadScreen> createState() => _UploadScreenState();
// }

// class _UploadScreenState extends State<UploadScreen> {
//   File? _selectedImage;
//   final ImagePicker _picker = ImagePicker();

//   // This actually opens the hardware camera or gallery[cite: 2]
//   Future<void> _pickImage(ImageSource source) async {
//     final XFile? pickedFile = await _picker.pickImage(source: source);
//     if (pickedFile != null) {
//       setState(() {
//         _selectedImage = File(pickedFile.path);
//       });
//     }
//   }

//   void _removeImage() {
//     setState(() => _selectedImage = null);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Upload Crop Image')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // Preview Selected Image area
//             Expanded(
//               child: Container(
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.green.shade200, width: 2),
//                 ),
//                 child: _selectedImage != null
//                     ? Stack(
//                         alignment: Alignment.center,
//                         children: [
//                           // Displays the actual photo you just took[cite: 2]
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(10),
//                             child: kIsWeb
//                                 ? Image.network(
//                                   _selectedImage!.path,
//                                   width: double.infinity,
//                                   height: double.infinity,
//                                   fit:BoxFit.cover,
//                                 )
//                                 :Image.file(
//                                   _selectedImage!,
//                                   width: double.infinity,
//                                   height: double.infinity,
//                                   fit: BoxFit.cover,
//                             ),
//                           ),
//                           Positioned(
//                             top: 8,
//                             right: 8,
//                             child: IconButton(
//                               icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
//                               onPressed: _removeImage,
//                             ),
//                           ),
//                         ],
//                       )
//                     : const Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.image_outlined, size: 80, color: Colors.grey),
//                           SizedBox(height: 10),
//                           Text('No image selected', style: TextStyle(color: Colors.grey)),
//                         ],
//                       ),
//               ),
//             ),
//             const SizedBox(height: 20),
            
//             // Select Image Buttons[cite: 2]
//             Row(
//               children: [
//                 Expanded(
//                   child: SecondaryButton(
//                     text: 'Camera',
//                     icon: Icons.camera_alt,
//                     onPressed: () => _pickImage(ImageSource.camera), // Triggers Camera[cite: 2]
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: SecondaryButton(
//                     text: 'Gallery',
//                     icon: Icons.photo_library,
//                     onPressed: () => _pickImage(ImageSource.gallery), // Triggers Gallery[cite: 2]
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
            
//             // Continue Button[cite: 2]
//             PrimaryButton(
//               text: 'Continue',
//               icon: Icons.arrow_forward,
//               //changed this line
//               /*onPressed: _selectedImage != null 
//                   ? () => Navigator.pushNamed(context, '/processing') */
//               // to this
//               onPressed: _selectedImage != null 
//                   ? () => Navigator.pushNamed(context, '/processing', arguments: _selectedImage) 
//                   : () {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Please select an image first!')),
//                       );
//                     },
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }




import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  Uint8List? _selectedImageBytes;
  String? _selectedImagePath;

  final ImagePicker _picker = ImagePicker();

  bool get _hasImage => _selectedImageBytes != null;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();

      if (bytes.isEmpty) {
        _showError('The selected image is empty.');
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImagePath = pickedFile.path;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError('Unable to select the image. Please try again.');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBytes = null;
      _selectedImagePath = null;
    });
  }

  void _continue() {
    if (!_hasImage) {
      _showError('Please select an image first.');
      return;
    }

    Navigator.pushNamed(
      context,
      '/processing',
      arguments: _selectedImageBytes,
    );
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Crop Image'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 2,
                    ),
                  ),
                  child: _hasImage
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _selectedImageBytes!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 70,
                                          color: Colors.red,
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Unable to display image',
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            Positioned(
                              top: 8,
                              right: 8,
                              child: Material(
                                color: Colors.white.withOpacity(0.9),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                  tooltip: 'Remove image',
                                  onPressed: _removeImage,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No image selected',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Take a photo or select one from gallery',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'Camera',
                      icon: Icons.camera_alt,
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SecondaryButton(
                      text: 'Gallery',
                      icon: Icons.photo_library,
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              PrimaryButton(
                text: 'Continue',
                icon: Icons.arrow_forward,
                onPressed: _continue,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
