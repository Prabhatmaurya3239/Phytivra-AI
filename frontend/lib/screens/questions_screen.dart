import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/question_widget.dart';
import '../widgets/primary_button.dart';
import '../widgets/language_toggel.dart';
import '../core/app_theme.dart';
import '../core/localization/app_strings.dart';

class QuestionsScreen extends StatelessWidget {
  const QuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isEnglish = appState.isEnglish;
        final questions = appState.questions;
        final isSubmitting = appState.isSubmitting;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.get('follow_up_title', isEnglish: isEnglish),
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
          body: questions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.help_outline,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isEnglish
                              ? 'No follow-up questions needed.'
                              : 'अतिरिक्त प्रश्नों की आवश्यकता नहीं है।',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          text: AppStrings.get(
                            'view_recommendations',
                            isEnglish: isEnglish,
                          ),
                          icon: Icons.psychology,
                          onPressed: () => Navigator.pushReplacementNamed(
                            context,
                            '/recommendation',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Diagnostic context banner
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      color: Colors.amber.shade50,
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.get(
                                'follow_up_subtitle',
                                isEnglish: isEnglish,
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.brown.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dynamic Questions List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final q = questions[index];
                          return QuestionWidget(
                            key: ValueKey(q.id),
                            index: index,
                            question: q,
                            initialAnswer: appState.getAnswer(q.id),
                            isEnglish: isEnglish,
                            onAnswerChanged: (val) {
                              appState.setAnswer(q.id, val);
                            },
                          );
                        },
                      ),
                    ),

                    // Submit Bar with double-tap protection & validation
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (appState.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  appState.errorMessage!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            PrimaryButton(
                              text: AppStrings.get(
                                'submit_answers',
                                isEnglish: isEnglish,
                              ),
                              icon: Icons.check_circle_outline,
                              isLoading: isSubmitting,
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (!appState.validateRequiredAnswers()) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppStrings.get(
                                                'required_field_warning',
                                                isEnglish: isEnglish,
                                              ),
                                            ),
                                            backgroundColor:
                                                Colors.orange.shade800,
                                          ),
                                        );
                                        return;
                                      }

                                      final success = await appState
                                          .submitFollowUpAnswers();
                                      if (context.mounted && success) {
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/recommendation',
                                        );
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
