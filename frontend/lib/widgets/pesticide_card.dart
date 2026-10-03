import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/pesticide_model.dart';
import '../core/app_theme.dart';
import '../core/localization/app_strings.dart';

class PesticideCard extends StatelessWidget {
  final PesticideModel pesticide;
  final bool isEnglish;

  const PesticideCard({
    super.key,
    required this.pesticide,
    this.isEnglish = true,
  });

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Ignored safely
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFC8E6C9), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Product Name & Verified Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pesticide.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                      if (pesticide.companyName.isNotEmpty &&
                          pesticide.companyName !=
                              PesticideModel.fallbackUnavailable)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            pesticide.companyName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
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
                    color: AppTheme.lightGreen,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryGreen),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: AppTheme.primaryGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Optional Image (Handles missing/null safely without breaking)
            if (pesticide.image != null && pesticide.image!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  pesticide.image!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 80,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const Divider(height: 24, thickness: 1),

            // Key verified product fields
            _buildDetailRow(
              Icons.science,
              AppStrings.get('chemical_name', isEnglish: isEnglish),
              pesticide.activeIngredient,
            ),
            _buildDetailRow(
              Icons.water_drop,
              AppStrings.get('dosage', isEnglish: isEnglish),
              pesticide.dosage,
            ),
            _buildDetailRow(
              Icons.format_paint,
              AppStrings.get('spray_method', isEnglish: isEnglish),
              pesticide.sprayMethod,
            ),
            _buildDetailRow(
              Icons.inventory_2,
              AppStrings.get('packing_size', isEnglish: isEnglish),
              pesticide.packingSize,
            ),
            _buildDetailRow(
              Icons.currency_rupee,
              AppStrings.get('price_range', isEnglish: isEnglish),
              pesticide.priceRange,
            ),

            if (pesticide.precautions.isNotEmpty &&
                pesticide.precautions !=
                    PesticideModel.fallbackUnavailable) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pesticide.precautions,
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
            ],

            // External Source Link if provided
            if (pesticide.sourceUrl != null &&
                pesticide.sourceUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(
                    AppStrings.get('open_source_link', isEnglish: isEnglish),
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () => _launchUrl(pesticide.sourceUrl),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: value == PesticideModel.fallbackUnavailable
                    ? Colors.grey.shade600
                    : Colors.black87,
                fontStyle: value == PesticideModel.fallbackUnavailable
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
