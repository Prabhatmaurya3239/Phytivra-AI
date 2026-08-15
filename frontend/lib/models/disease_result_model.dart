class DiseaseResultModel{
  final String cropName;
  final String diseaseName;
  final double confidence;
  final String severity;
  final String description;
  final String? imageUrl; // Optional field for image URL

  DiseaseResultModel({
    required this.cropName,
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.description,
    this.imageUrl,
  });

  // we will map the real JSONkeys later when the backend team gives us the real API response
  factory DiseaseResultModel.fromJson(Map<String, dynamic> json) {
    return DiseaseResultModel(
      cropName: json['crop_name'] ?? 'Unknown Crop',
      diseaseName: json['disease_name'] ?? 'Unknown Disease',
      confidence: (json['confidence'] ?? 0.0)?.toDouble(),
      severity: json['severity'] ?? 'Unknown Severity',
      description: json['description'] ?? 'No description available.',
      imageUrl: json['image_url'], // This can be null
    );
  }
}