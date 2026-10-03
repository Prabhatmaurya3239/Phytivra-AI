import 'pesticide_model.dart';
import 'source_model.dart';

class DiseaseResultModel {
  final int id;
  final String cropName;
  final String? scientificName;
  final String diseaseName;
  final double confidence;
  final String severity;
  final String description;
  final String? symptoms;
  final String? causes;
  final String? imageUrl;
  final String? predictionId;
  final List<PesticideModel> pesticides;
  final List<String> precautions;
  final List<SourceModel> sources;
  final String? recommendationSummary;

  DiseaseResultModel({
    required this.id,
    required this.cropName,
    this.scientificName,
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.description,
    this.symptoms,
    this.causes,
    this.imageUrl,
    this.predictionId,
    this.pesticides = const [],
    this.precautions = const [],
    this.sources = const [],
    this.recommendationSummary,
  });

  factory DiseaseResultModel.fromJson(Map<String, dynamic> json) {
    // Check if nested in 'result' (Contract format)
    final Map<String, dynamic> data =
        json.containsKey('result') && json['result'] is Map<String, dynamic>
        ? json['result']
        : json;

    final cropObj = data['crop'];
    final String crop = cropObj is Map
        ? (cropObj['name'] ?? '')
        : (data['crop_name'] ?? '');
    final String? scientific = cropObj is Map
        ? cropObj['scientific_name']
        : null;

    final diseaseObj = data['disease'];
    final int disId = diseaseObj is Map
        ? (diseaseObj['id'] ?? 0)
        : (data['id'] ?? 0);
    final String disName = diseaseObj is Map
        ? (diseaseObj['name'] ?? '')
        : (data['disease_name'] ?? '');
    final String sev = diseaseObj is Map
        ? (diseaseObj['severity'] ?? 'Medium')
        : (data['severity'] ?? 'Medium');
    final String desc = diseaseObj is Map
        ? (diseaseObj['description'] ?? '')
        : (data['description'] ?? 'No description available.');
    final String? symp = diseaseObj is Map
        ? diseaseObj['symptoms']
        : data['symptoms'];
    final String? caus = diseaseObj is Map
        ? diseaseObj['causes']
        : data['causes'];

    // Confidence can be Map {'score': 0.92, 'percentage': 92} or num 0.92
    double conf = 0.0;
    final rawConf = data['confidence'];
    if (rawConf is Map) {
      conf = (rawConf['score'] as num?)?.toDouble() ?? 0.0;
    } else if (rawConf is num) {
      conf = rawConf.toDouble();
      if (conf > 1.0) conf = conf / 100.0;
    }

    // Pesticides
    List<PesticideModel> parsedPesticides = [];
    final rawPests = data['pesticides'];
    if (rawPests is List) {
      parsedPesticides = rawPests
          .whereType<Map<String, dynamic>>()
          .map((p) => PesticideModel.fromJson(p))
          .toList();
    }

    // Precautions
    List<String> parsedPrecautions = [];
    final rawPrecautions = data['precautions'];
    if (rawPrecautions is List) {
      parsedPrecautions = rawPrecautions.map((e) => e.toString()).toList();
    }

    // Sources
    List<SourceModel> parsedSources = [];
    final rawSources = json['sources'] ?? data['sources'];
    if (rawSources is List) {
      parsedSources = rawSources
          .whereType<Map<String, dynamic>>()
          .map((s) => SourceModel.fromJson(s))
          .toList();
    }

    final recSummary = data['recommendation'] is Map
        ? data['recommendation']['summary']?.toString()
        : null;

    return DiseaseResultModel(
      id: disId,
      cropName: crop.isNotEmpty ? crop : 'Crop',
      scientificName: scientific,
      diseaseName: disName.isNotEmpty ? disName : 'Undetermined Condition',
      confidence: conf,
      severity: sev,
      description: desc.isNotEmpty ? desc : 'Crop health analysis completed.',
      symptoms: symp,
      causes: caus,
      imageUrl: json['image_url'] ?? data['image_url'] ?? json['image']?['url'],
      predictionId: json['prediction_id'],
      pesticides: parsedPesticides,
      precautions: parsedPrecautions,
      sources: parsedSources,
      recommendationSummary: recSummary,
    );
  }
}
