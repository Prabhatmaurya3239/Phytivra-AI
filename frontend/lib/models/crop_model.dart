class CropModel {
  final int? id;
  final String name;
  final String? scientificName;
  final String? description;
  final String? image;

  CropModel({
    this.id,
    required this.name,
    this.scientificName,
    this.description,
    this.image,
  });

  factory CropModel.fromJson(Map<String, dynamic> json) {
    return CropModel(
      id: json['id'] as int?,
      name: (json['name'] ?? '').toString(),
      scientificName: json['scientific_name']?.toString(),
      description: json['description']?.toString(),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'scientific_name': scientificName,
    'description': description,
    'image': image,
  };
}
