import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/recommendation_model.dart';
import '../widgets/pesticide_card.dart';
import '../widgets/source_section.dart';
import '../widgets/primary_button.dart';
import '../widgets/language_toggel.dart';
import '../core/app_theme.dart';
import '../core/localization/app_strings.dart';

class AiRecommendationScreen extends StatelessWidget {
  const AiRecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isEnglish = appState.isEnglish;
        final passedModel =
            ModalRoute.of(context)?.settings.arguments as RecommendationModel?;
        final rec = appState.currentRecommendation ?? passedModel;
        final currentResult = appState.currentResult;

        if (rec == null && currentResult == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                AppStrings.get('recommendations_title', isEnglish: isEnglish),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEnglish
                          ? 'No recommendation data available.'
                          : 'कोई सलाह उपलब्ध नहीं है।',
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
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/upload',
                          ModalRoute.withName('/home'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Aggregate pesticides
        final pesticides = rec?.pesticides.isNotEmpty == true
            ? rec!.pesticides
            : (currentResult?.pesticides ?? []);

        // Aggregate precautions
        final precautions = rec?.precautionsList.isNotEmpty == true
            ? rec!.precautionsList
            : (currentResult?.precautions ??
                  (rec?.precautions.isNotEmpty == true
                      ? [rec!.precautions]
                      : []));

        // Aggregate sources
        final sources = rec?.sources.isNotEmpty == true
            ? rec!.sources
            : (currentResult?.sources ?? []);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.get('recommendations_title', isEnglish: isEnglish),
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
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Disease Detected Banner
              if (currentResult != null)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade900.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.eco,
                          color: AppTheme.primaryGreen,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentResult.diseaseName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AppStrings.get('crop_name', isEnglish: isEnglish)}: ${currentResult.cropName}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFE8F5E9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(currentResult.confidence <= 1.0 ? currentResult.confidence * 100 : currentResult.confidence).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 2. What You Should Do / Recommended Action
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.psychology,
                            color: AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.get(
                              'what_you_should_do',
                              isEnglish: isEnglish,
                            ),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rec?.description.isNotEmpty == true
                            ? rec!.description
                            : (currentResult?.description ??
                                  'Follow verified management guidelines.'),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Recommended Treatment / Pesticide Information
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.medication_liquid,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.get('pesticide_details', isEnglish: isEnglish),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                  ],
                ),
              ),

              // Dynamic Pesticides Rendering: Handles 0, 1, 3, 5 cards cleanly
              if (pesticides.isEmpty)
                Card(
                  color: Colors.grey.shade50,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.primaryGreen,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppStrings.get(
                              'no_pesticides',
                              isEnglish: isEnglish,
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...pesticides.map((pest) {
                  return PesticideCard(pesticide: pest, isEnglish: isEnglish);
                }),

              // 4. Organic / Non-Chemical Measures (if available)
              if (rec?.organicAlternatives != null &&
                  rec!.organicAlternatives!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.eco, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.get(
                                'organic_measures',
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
                          rec.organicAlternatives!,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 5. Preventive Measures (if available)
              if (rec?.preventiveMeasures != null &&
                  rec!.preventiveMeasures!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              AppStrings.get(
                                'preventive_measures',
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
                          rec.preventiveMeasures!,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 6. Safety Precautions
              const SizedBox(height: 8),
              Card(
                color: Colors.amber.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.amber.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.get('precautions', isEnglish: isEnglish),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (precautions.isNotEmpty)
                        ...precautions.map(
                          (p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    p,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.brown.shade900,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Text(
                          AppStrings.get(
                            'safety_disclaimer',
                            isEnglish: isEnglish,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.brown.shade900,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 7. Verified Sources Section
              const SizedBox(height: 8),
              SourceSection(sources: sources, isEnglish: isEnglish),

              const SizedBox(height: 24),

              // 8. New Diagnosis Button
              PrimaryButton(
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
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
