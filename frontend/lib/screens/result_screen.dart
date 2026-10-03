import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../providers/app_state_provider.dart';
import '../models/disease_result_model.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../widgets/language_toggel.dart';
import '../core/app_theme.dart';
import '../core/localization/app_strings.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green.shade600;
      case 'medium':
        return Colors.orange.shade700;
      case 'high':
      case 'critical':
        return Colors.red.shade700;
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isEnglish = appState.isEnglish;

        // Catch model from Provider or Route Arguments
        final routeResult =
            ModalRoute.of(context)?.settings.arguments as DiseaseResultModel?;
        final result = appState.currentResult ?? routeResult;

        if (result == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(isEnglish ? 'Analysis Result' : 'जांच परिणाम'),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEnglish
                          ? 'No result data found.'
                          : 'कोई परिणाम नहीं मिला।',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: AppStrings.get(
                        'new_diagnosis',
                        isEnglish: isEnglish,
                      ),
                      icon: Icons.refresh,
                      onPressed: () {
                        appState.resetWorkflow();
                        Navigator.pushReplacementNamed(context, '/upload');
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final double confPercent = result.confidence <= 1.0
            ? result.confidence * 100
            : result.confidence;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.get('disease_detected', isEnglish: isEnglish),
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Leaf Image Display
                Container(
                  height: 210,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC8E6C9),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child:
                        (result.imageUrl != null && result.imageUrl!.isNotEmpty)
                        ? (result.imageUrl!.startsWith('http://') ||
                                  result.imageUrl!.startsWith('https://'))
                              ? Image.network(
                                  result.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                              : (kIsWeb)
                              ? Image.network(
                                  result.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                              : Image.file(
                                  File(result.imageUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      ),
                                )
                        : const Center(
                            child: Icon(
                              Icons.eco,
                              size: 64,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Severity and Match Badges
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(
                        Icons.warning,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        '${AppStrings.get('severity', isEnglish: isEnglish)}: ${result.severity}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: _getSeverityColor(result.severity),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(
                        Icons.verified,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                      label: Text(
                        AppStrings.get('high_confidence', isEnglish: isEnglish),
                        style: const TextStyle(
                          color: AppTheme.darkGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: AppTheme.lightGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Primary Identification Card (Crop & Disease)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.diseaseName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.grass,
                              size: 18,
                              color: AppTheme.primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${AppStrings.get('crop_name', isEnglish: isEnglish)}: ${result.cropName}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (result.scientificName != null &&
                                result.scientificName!.isNotEmpty)
                              Text(
                                ' (${result.scientificName})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Confidence Meter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.get(
                                'confidence',
                                isEnglish: isEnglish,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              '${confPercent.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (confPercent / 100).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Description Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.description,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.get(
                                'description',
                                isEnglish: isEnglish,
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          result.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Symptoms & Causes if available
                if (result.symptoms != null && result.symptoms!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.coronavirus,
                                color: Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.get(
                                  'symptoms',
                                  isEnglish: isEnglish,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.symptoms!,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (result.causes != null && result.causes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.get('causes', isEnglish: isEnglish),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.causes!,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Primary Action: View Treatment & Recommendations
                PrimaryButton(
                  text: AppStrings.get(
                    'view_recommendations',
                    isEnglish: isEnglish,
                  ),
                  icon: Icons.psychology,
                  onPressed: () {
                    Navigator.pushNamed(context, '/recommendation');
                  },
                ),
                const SizedBox(height: 12),

                // New Diagnosis Button
                SecondaryButton(
                  text: AppStrings.get('new_diagnosis', isEnglish: isEnglish),
                  icon: Icons.refresh,
                  onPressed: () {
                    appState.resetWorkflow();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/upload',
                      ModalRoute.withName('/home'),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
