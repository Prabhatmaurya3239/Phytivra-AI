class ConfidenceModel {
  final double score;
  final int percentage;

  ConfidenceModel({required this.score, required this.percentage});

  factory ConfidenceModel.fromJson(dynamic json) {
    if (json is num) {
      final double s = json.toDouble();
      final int p = (s <= 1.0) ? (s * 100).round() : s.round();
      final double normalizedScore = (s > 1.0) ? (s / 100.0) : s;
      return ConfidenceModel(score: normalizedScore, percentage: p);
    }

    if (json is Map<String, dynamic>) {
      final double s = (json['score'] as num?)?.toDouble() ?? 0.0;
      final int p = (json['percentage'] as num?)?.toInt() ?? (s * 100).round();
      return ConfidenceModel(score: s, percentage: p);
    }

    return ConfidenceModel(score: 0.0, percentage: 0);
  }

  Map<String, dynamic> toJson() => {'score': score, 'percentage': percentage};
}
