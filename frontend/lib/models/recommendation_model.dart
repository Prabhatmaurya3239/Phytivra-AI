import 'pesticide_model.dart';
import 'source_model.dart';

class RecommendationSummaryModel {
  final bool available;
  final String type;
  final String summary;
  final List<String> actions;

  RecommendationSummaryModel({
    required this.available,
    this.type = 'disease_management',
    required this.summary,
    this.actions = const [],
  });

  factory RecommendationSummaryModel.fromJson(dynamic json) {
    if (json == null) {
      return RecommendationSummaryModel(
        available: false,
        summary: 'No verified recommendation available.',
      );
    }

    if (json is String) {
      return RecommendationSummaryModel(available: true, summary: json);
    }

    if (json is Map<String, dynamic>) {
      final rawActions = json['actions'];
      List<String> parsedActions = [];
      if (rawActions is List) {
        parsedActions = rawActions.map((e) => e.toString()).toList();
      }

      return RecommendationSummaryModel(
        available: json['available'] as bool? ?? true,
        type: (json['type'] ?? 'disease_management').toString(),
        summary:
            (json['summary'] ??
                    json['message'] ??
                    'Management guidance available.')
                .toString(),
        actions: parsedActions,
      );
    }

    return RecommendationSummaryModel(
      available: false,
      summary: 'No verified recommendation available.',
    );
  }
}

class RecommendationModel {
  final String description;
  final String pesticideName;
  final String companyName;
  final String priceRange;
  final String packingSize;
  final String dosage;
  final String sprayMethod;
  final String precautions;
  final String? organicAlternatives;
  final String? preventiveMeasures;
  final List<PesticideModel> pesticides;
  final List<String> precautionsList;
  final List<SourceModel> sources;

  RecommendationModel({
    required this.description,
    required this.pesticideName,
    required this.companyName,
    required this.priceRange,
    required this.packingSize,
    required this.dosage,
    required this.sprayMethod,
    required this.precautions,
    this.organicAlternatives,
    this.preventiveMeasures,
    this.pesticides = const [],
    this.precautionsList = const [],
    this.sources = const [],
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    // 1. Grab pesticides list
    List<PesticideModel> parsedPesticides = [];
    final rawPests = json['recommended_pesticides'] ?? json['pesticides'];
    if (rawPests is List) {
      parsedPesticides = rawPests
          .whereType<Map<String, dynamic>>()
          .map((p) => PesticideModel.fromJson(p))
          .toList();
    }

    // 2. Grab precautions list
    List<String> parsedPrecautions = [];
    final rawPrecautions = json['precautions'];
    if (rawPrecautions is List) {
      parsedPrecautions = rawPrecautions.map((e) => e.toString()).toList();
    } else if (rawPrecautions is String && rawPrecautions.isNotEmpty) {
      parsedPrecautions = [rawPrecautions];
    }

    // 3. Grab sources list
    List<SourceModel> parsedSources = [];
    final rawSources = json['sources'];
    if (rawSources is List) {
      parsedSources = rawSources
          .whereType<Map<String, dynamic>>()
          .map((s) => SourceModel.fromJson(s))
          .toList();
    }

    // 4. Fallback primary pesticide fields for legacy widgets
    final firstPest = parsedPesticides.isNotEmpty
        ? parsedPesticides.first
        : null;

    final String desc =
        (json['summary'] ??
                json['description'] ??
                (json['recommendation'] is Map
                    ? json['recommendation']['summary']
                    : null) ??
                'Recommended treatment and management practices.')
            .toString();

    final String singlePrecaution = parsedPrecautions.isNotEmpty
        ? parsedPrecautions.join('\n• ')
        : (firstPest?.precautions ??
              'Always read and adhere to official pesticide container labels.');

    return RecommendationModel(
      description: desc,
      pesticideName:
          firstPest?.name ?? json['pesticide_name']?.toString() ?? '',
      companyName:
          firstPest?.companyName ?? json['company_name']?.toString() ?? '',
      priceRange:
          firstPest?.priceRange ?? json['price_range']?.toString() ?? '',
      packingSize:
          firstPest?.packingSize ?? json['packing_size']?.toString() ?? '',
      dosage: firstPest?.dosage ?? json['dosage']?.toString() ?? '',
      sprayMethod:
          firstPest?.sprayMethod ?? json['spray_method']?.toString() ?? '',
      precautions: singlePrecaution,
      organicAlternatives: json['organic_alternatives']?.toString(),
      preventiveMeasures: json['preventive_measures']?.toString(),
      pesticides: parsedPesticides,
      precautionsList: parsedPrecautions,
      sources: parsedSources,
    );
  }
}
