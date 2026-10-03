class SourceModel {
  final String title;
  final String? url;
  final String? sourceType;
  final bool verified;

  SourceModel({
    required this.title,
    this.url,
    this.sourceType,
    this.verified = true,
  });

  factory SourceModel.fromJson(Map<String, dynamic> json) {
    return SourceModel(
      title:
          (json['title'] ??
                  json['name'] ??
                  'Official Agricultural Knowledge Base')
              .toString(),
      url: json['url']?.toString(),
      sourceType: json['source_type']?.toString() ?? 'official',
      verified: json['verified'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'source_type': sourceType,
    'verified': verified,
  };
}
