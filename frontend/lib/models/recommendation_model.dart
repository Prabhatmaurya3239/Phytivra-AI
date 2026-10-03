class RecommendationModel {
  final String description;
  final String pesticideName;
  final String companyName;
  final String priceRange;
  final String packingSize;
  final String dosage;
  final String sprayMethod;
  final String precautions;
  // final String organicAlternatives;
  // final String preventiveMeasures;

  RecommendationModel({
    required this.description,
    required this.pesticideName,
    required this.companyName,
    required this.priceRange,
    required this.packingSize,
    required this.dosage,
    required this.sprayMethod,
    required this.precautions,
    // required this.organicAlternatives,
    // required this.preventiveMeasures,
  });

  //Palceholder factory constructor for the incoming JSON
  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    // 1. Grab the pesticides array
    var pesticides = json['recommended_pesticides'] as List<dynamic>? ?? [];
    // 2. Grab the first item (or an empty map if it's missing)
    var pesticide = pesticides.isNotEmpty ? pesticides[0] : {};
    return RecommendationModel(
      description: json['description'] ?? '',
      pesticideName: pesticide['name'] ?? '',
      companyName: json['company_name'] ?? '',
      priceRange: json['price_range'] ?? '',
      packingSize: json['packing_size'] ?? '',
      dosage: json['dosage'] ?? '',
      sprayMethod: json['spray_method'] ?? '',
      precautions: json['precautions'] ?? '',
      // organicAlternatives: json['organic_alternatives'] ?? '',
      // preventiveMeasures: json['preventive_measures'] ?? '',
    );
  }

}