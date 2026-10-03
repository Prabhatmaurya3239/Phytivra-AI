import 'disease_result_model.dart';
import 'question_model.dart';

class MLResultModel {
  final String? cropName;
  final int? cropId;
  final String? diseaseName;
  final int? diseaseId;
  final double confidence;

  MLResultModel({
    this.cropName,
    this.cropId,
    this.diseaseName,
    this.diseaseId,
    required this.confidence,
  });

  factory MLResultModel.fromJson(Map<String, dynamic> json) {
    final crop = json['crop'];
    final disease = json['disease'];
    final double conf = (json['confidence'] as num?)?.toDouble() ?? 0.0;

    return MLResultModel(
      cropName: crop is Map ? crop['name']?.toString() : null,
      cropId: crop is Map ? crop['id'] as int? : null,
      diseaseName: disease is Map ? disease['name']?.toString() : null,
      diseaseId: disease is Map ? disease['id'] as int? : null,
      confidence: conf,
    );
  }
}

class PredictionResponse {
  final bool success;
  final String predictionId;
  final String status; // 'completed', 'needs_questions', 'processing', 'failed'
  final String? message;
  final MLResultModel? mlResult;
  final DiseaseResultModel? result;
  final List<QuestionModel> questions;

  PredictionResponse({
    required this.success,
    required this.predictionId,
    required this.status,
    this.message,
    this.mlResult,
    this.result,
    this.questions = const [],
  });

  bool get isCompleted => status == 'completed' || status == 'success';
  bool get needsQuestions => status == 'needs_questions';
  bool get isFailed => status == 'failed' || !success;

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    final bool success = json['success'] as bool? ?? true;
    final String predId = (json['prediction_id'] ?? json['id'] ?? '')
        .toString();
    final String statusStr =
        (json['status'] ?? (success ? 'completed' : 'failed'))
            .toString()
            .toLowerCase();
    final String? message = json['message']?.toString();

    // Parse ML result if present
    MLResultModel? parsedMl;
    if (json['ml_result'] is Map<String, dynamic>) {
      parsedMl = MLResultModel.fromJson(json['ml_result']);
    }

    // Parse questions if present
    List<QuestionModel> parsedQuestions = [];
    final rawQuestions =
        json['questions'] ??
        (json['data'] is Map ? json['data']['questions'] : null);
    if (rawQuestions is List) {
      parsedQuestions = rawQuestions
          .whereType<Map<String, dynamic>>()
          .map((q) => QuestionModel.fromJson(q))
          .toList();
    }

    // Parse result if present
    DiseaseResultModel? parsedResult;
    if (json.containsKey('result') && json['result'] is Map<String, dynamic>) {
      parsedResult = DiseaseResultModel.fromJson(json);
    } else if (statusStr == 'completed' || statusStr == 'success') {
      parsedResult = DiseaseResultModel.fromJson(json);
    }

    return PredictionResponse(
      success: success,
      predictionId: predId,
      status: statusStr,
      message: message,
      mlResult: parsedMl,
      result: parsedResult,
      questions: parsedQuestions,
    );
  }
}
