// class DiseaseResultModel{
//   final String cropName;
//   final String diseaseName;
//   final double confidence;
//   final String severity;
//   final String description;
//   final String? imageUrl; // Optional field for image URL

//   DiseaseResultModel({
//     required this.cropName,
//     required this.diseaseName,
//     required this.confidence,
//     required this.severity,
//     required this.description,
//     this.imageUrl,
//   });

//   // we will map the real JSONkeys later when the backend team gives us the real API response
//   factory DiseaseResultModel.fromJson(Map<String, dynamic> json) {
//     return DiseaseResultModel(
//       cropName: json['crop_name'] ?? 'Unknown Crop',
//       diseaseName: json['disease_name'] ?? 'Unknown Disease',
//       confidence: (json['confidence'] ?? 0.0)?.toDouble(),
//       severity: json['severity'] ?? 'Unknown Severity',
//       description: json['description'] ?? 'No description available.',
//       imageUrl: json['image_url'], // This can be null
//     );
//   }
// }


class DiseaseResultModel {
  final String cropName;
  final String diseaseName;
  final double confidence;
  final String severity;
  final String description;
  final String? imageUrl;

  DiseaseResultModel({
    required this.cropName,
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.description,
    this.imageUrl,
  });

  factory DiseaseResultModel.fromJson(Map<String, dynamic> json) {
    return DiseaseResultModel(
      cropName: _stringValue(
        json['crop_name'],
        fallback: 'Unknown Crop',
      ),
      diseaseName: _stringValue(
        json['disease_name'],
        fallback: 'Unknown Disease',
      ),
      confidence: _doubleValue(
        json['confidence'],
        fallback: 0.0,
      ),
      severity: _stringValue(
        json['severity'],
        fallback: 'Unknown Severity',
      ),
      description: _stringValue(
        json['description'],
        fallback: 'No description available.',
      ),
      imageUrl: _nullableString(json['image_url']),
    );
  }

  static String _stringValue(
    dynamic value, {
    required String fallback,
  }) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  static double _doubleValue(
    dynamic value, {
    required double fallback,
  }) {
    if (value == null) {
      return fallback;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  Map<String, dynamic> toJson() {
    return {
      'crop_name': cropName,
      'disease_name': diseaseName,
      'confidence': confidence,
      'severity': severity,
      'description': description,
      'image_url': imageUrl,
    };
  }
}
