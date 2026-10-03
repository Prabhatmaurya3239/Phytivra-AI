import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';
import '../core/app_theme.dart';
import '../core/localization/app_strings.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStarted) {
      _hasStarted = true;
      _initiateAnalysis();
    }
  }

  Future<void> _initiateAnalysis() async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final success = await appState.startPrediction();

    if (!mounted) return;

    if (success) {
      if (appState.workflowState == PredictionWorkflowState.needsQuestions) {
        // Low confidence flow -> Go to follow-up questions screen
        Navigator.pushReplacementNamed(context, '/questions');
      } else if (appState.workflowState ==
          PredictionWorkflowState.predictionCompleted) {
        // High confidence flow -> Go to disease result screen
        Navigator.pushReplacementNamed(context, '/result');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final isEnglish = appState.isEnglish;

        // If the workflow failed, display farmer-friendly recovery UI
        if (appState.workflowState == PredictionWorkflowState.failed) {
          final isNetwork = appState.errorType == 'network';
          final titleMessage = isNetwork
              ? AppStrings.get('network_error', isEnglish: isEnglish)
              : (appState.errorMessage ??
                    AppStrings.get('prediction_failed', isEnglish: isEnglish));

          return Scaffold(
            appBar: AppBar(
              title: Text(isEnglish ? 'Analysis Error' : 'त्रुटि'),
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isNetwork ? Icons.wifi_off : Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      titleMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: AppStrings.get('try_again', isEnglish: isEnglish),
                      icon: Icons.refresh,
                      isLoading: appState.isSubmitting,
                      onPressed: () async {
                        final ok = await appState.retryLastAction();
                        if (mounted && ok) {
                          if (appState.workflowState ==
                              PredictionWorkflowState.needsQuestions) {
                            Navigator.pushReplacementNamed(
                              context,
                              '/questions',
                            );
                          } else if (appState.workflowState ==
                              PredictionWorkflowState.predictionCompleted) {
                            Navigator.pushReplacementNamed(context, '/result');
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      text: isEnglish
                          ? 'Choose Another Photo'
                          : 'दूसरी फोटो चुनें',
                      icon: Icons.photo_library,
                      onPressed: () {
                        appState.clearImage();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Processing & Loading State
        return Scaffold(
          body: Center(
            child: LoadingWidget(
              message: AppStrings.get('analyzing_title', isEnglish: isEnglish),
              subMessage: AppStrings.get(
                'analyzing_subtitle',
                isEnglish: isEnglish,
              ),
            ),
          ),
        );
      },
    );
  }
}
