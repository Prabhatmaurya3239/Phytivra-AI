class DiseaseModel {
  final int? id;
  final String name;
  final int? crop;
  final String? cropName;
  final String? symptoms;
  final String? causes;
  final String? description;
  final String? severity;
  final String? image;

  DiseaseModel({
    this.id,
    required this.name,
    this.crop,
    this.cropName,
    this.symptoms,
    this.causes,
    this.description,
    this.severity,
    this.image,
  });

  factory DiseaseModel.fromJson(Map<String, dynamic> json) {
    return DiseaseModel(
      id: json['id'] as int?,
      name: (json['name'] ?? '').toString(),
      crop: json['crop'] is int ? json['crop'] : null,
      cropName: json['crop_name']?.toString(),
      symptoms: json['symptoms']?.toString(),
      causes: json['causes']?.toString(),
      description: json['description']?.toString(),
      severity: json['severity']?.toString() ?? 'Medium',
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'crop': crop,
    'crop_name': cropName,
    'symptoms': symptoms,
    'causes': causes,
    'description': description,
    'severity': severity,
    'image': image,
  };
}
