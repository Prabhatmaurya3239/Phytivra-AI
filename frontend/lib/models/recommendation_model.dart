class RecommendationModel {
  final String recommendedTreatment;
  final String pesticides;
  final String companyName;
  final String priceRange;
  final String packingSize;
  final String dosage;
  final String sprayMethod;
  final String precautions;
  final String organicAlternatives;
  final String preventiveMeasures;

  RecommendationModel({
    required this.recommendedTreatment,
    required this.pesticides,
    required this.companyName,
    required this.priceRange,
    required this.packingSize,
    required this.dosage,
    required this.sprayMethod,
    required this.precautions,
    required this.organicAlternatives,
    required this.preventiveMeasures,
  });

  //Palceholder factory constructor for the incoming JSON
  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      recommendedTreatment: json['recommended_treatment'] ?? '',
      pesticides: json['pesticides'] ?? '',
      companyName: json['company_name'] ?? '',
      priceRange: json['price_range'] ?? '',
      packingSize: json['packing_size'] ?? '',
      dosage: json['dosage'] ?? '',
      sprayMethod: json['spray_method'] ?? '',
      precautions: json['precautions'] ?? '',
      organicAlternatives: json['organic_alternatives'] ?? '',
      preventiveMeasures: json['preventive_measures'] ?? '',
    );
  }

}