import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/app_state_provider.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/language_toggel.dart';
import '../core/app_theme.dart';
import '../core/localization/app_strings.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  Future<void> _pickImage(ImageSource source, AppStateProvider appState) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        appState.setSelectedImage(pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appState.isEnglish
                  ? 'Unable to access camera or gallery. Please check permissions.'
                  : 'कैमरा या गैलरी खोलने में असमर्थ। कृपया अनुमति जांचें।',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isEnglish = appState.isEnglish;
        final selectedImage = appState.selectedImage;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.get('upload_leaf_image', isEnglish: isEnglish),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: LanguageToggleWidget(
                  isEnglish: isEnglish,
                  onToggle: (val) => appState.toggleLanguage(val),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Instructions banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.get(
                            'upload_instructions',
                            isEnglish: isEnglish,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.darkGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selected Image Preview Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedImage != null
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade300,
                        width: selectedImage != null ? 2 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: selectedImage != null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: kIsWeb
                                    ? Image.network(
                                        selectedImage.path,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(selectedImage.path),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Material(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    onPressed: () => appState.clearImage(),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightGreen.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 64,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppStrings.get(
                                  'no_image_selected',
                                  isEnglish: isEnglish,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Camera and Gallery buttons
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        text: AppStrings.get('camera', isEnglish: isEnglish),
                        icon: Icons.camera_alt,
                        onPressed: _isPicking
                            ? null
                            : () => _pickImage(ImageSource.camera, appState),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton(
                        text: AppStrings.get('gallery', isEnglish: isEnglish),
                        icon: Icons.photo_library,
                        onPressed: _isPicking
                            ? null
                            : () => _pickImage(ImageSource.gallery, appState),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Continue / Proceed Button
                PrimaryButton(
                  text: isEnglish
                      ? 'Analyze Crop Health'
                      : 'फसल स्वास्थ्य की जांच करें',
                  icon: Icons.biotech,
                  onPressed: selectedImage != null
                      ? () => Navigator.pushNamed(context, '/processing')
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppStrings.get(
                                  'select_image_first',
                                  isEnglish: isEnglish,
                                ),
                              ),
                              backgroundColor: Colors.orange.shade800,
                            ),
                          );
                        },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
