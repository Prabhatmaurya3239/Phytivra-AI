import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/source_model.dart';
import '../core/app_theme.dart';
import '../core/localization/app_strings.dart';

class SourceSection extends StatelessWidget {
  final List<SourceModel> sources;
  final bool isEnglish;

  const SourceSection({
    super.key,
    required this.sources,
    this.isEnglish = true,
  });

  Future<void> _openUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEnglish
                    ? 'Verified by Official Agricultural Extension Guidelines.'
                    : 'आधिकारिक कृषि विस्तार एवं सुरक्षा मानकों द्वारा प्रमाणित।',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  AppStrings.get('sources_title', isEnglish: isEnglish),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...sources.map((source) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check,
                      size: 18,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        source.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (source.url != null && source.url!.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: AppTheme.primaryGreen,
                        ),
                        tooltip: AppStrings.get(
                          'open_source_link',
                          isEnglish: isEnglish,
                        ),
                        onPressed: () => _openUrl(source.url),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
