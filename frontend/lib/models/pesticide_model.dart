class PesticideModel {
  final int? id;
  final String name;
  final String companyName;
  final String activeIngredient;
  final String description;
  final String priceRange;
  final String packingSize;
  final String dosage;
  final String sprayMethod;
  final String precautions;
  final String? image;
  final String? sourceUrl;
  final String? sourceType;

  static const String fallbackUnavailable =
      'Information not available. Please verify from the official product label/source.';

  PesticideModel({
    this.id,
    required this.name,
    required this.companyName,
    required this.activeIngredient,
    required this.description,
    required this.priceRange,
    required this.packingSize,
    required this.dosage,
    required this.sprayMethod,
    required this.precautions,
    this.image,
    this.sourceUrl,
    this.sourceType,
  });

  factory PesticideModel.fromJson(Map<String, dynamic> json) {
    String safeString(dynamic val) {
      if (val == null) return fallbackUnavailable;
      final str = val.toString().trim();
      return str.isEmpty ? fallbackUnavailable : str;
    }

    return PesticideModel(
      id: json['id'] as int?,
      name: (json['name'] ?? json['product_name'] ?? 'Pesticide Product')
          .toString(),
      companyName: safeString(
        json['company_name'] ?? json['company'] ?? json['manufacturer'],
      ),
      activeIngredient: safeString(
        json['active_ingredient'] ?? json['active_ingredients'],
      ),
      description: safeString(json['description']),
      priceRange: safeString(json['price_range']),
      packingSize: safeString(json['packing_size']),
      dosage: safeString(json['dosage']),
      sprayMethod: safeString(
        json['spray_method'] ?? json['application_method'],
      ),
      precautions: safeString(json['precautions']),
      image: (json['image'] ?? json['product_image'])?.toString(),
      sourceUrl: json['source_url']?.toString(),
      sourceType: json['source_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'company_name': companyName,
    'active_ingredient': activeIngredient,
    'description': description,
    'price_range': priceRange,
    'packing_size': packingSize,
    'dosage': dosage,
    'spray_method': sprayMethod,
    'precautions': precautions,
    'image': image,
    'source_url': sourceUrl,
    'source_type': sourceType,
  };
}
