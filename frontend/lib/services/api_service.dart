import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/app_config.dart';
import '../core/localization/app_strings.dart';
import '../models/prediction_response.dart';
import '../models/disease_result_model.dart';
import '../models/crop_model.dart';
import '../models/disease_model.dart';
import '../models/pesticide_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Executes crop disease prediction pipeline
  Future<PredictionResponse> predictDisease({
    required XFile imageFile,
    required String language,
    String? userNote,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.predictEndpoint}');
      final request = http.MultipartRequest('POST', uri);

      final fileBytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          fileBytes,
          filename: imageFile.name.isNotEmpty
              ? imageFile.name
              : 'leaf_image.jpg',
        ),
      );

      request.fields['language'] = language;
      if (userNote != null && userNote.trim().isNotEmpty) {
        request.fields['user_note'] = userNote.trim();
      }

      final streamedResponse = await request.send().timeout(
        AppConfig.receiveTimeout,
      );
      final responseBody = await streamedResponse.stream.bytesToString();
      final statusCode = streamedResponse.statusCode;

      if (statusCode == 200 || statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(responseBody);
        final predictionResponse = PredictionResponse.fromJson(jsonResponse);

        // Preserve local image path if server response did not include an image URL
        if (predictionResponse.result != null &&
            predictionResponse.result!.imageUrl == null) {
          final enrichedResult = DiseaseResultModel(
            id: predictionResponse.result!.id,
            cropName: predictionResponse.result!.cropName,
            scientificName: predictionResponse.result!.scientificName,
            diseaseName: predictionResponse.result!.diseaseName,
            confidence: predictionResponse.result!.confidence,
            severity: predictionResponse.result!.severity,
            description: predictionResponse.result!.description,
            symptoms: predictionResponse.result!.symptoms,
            causes: predictionResponse.result!.causes,
            imageUrl: imageFile.path,
            predictionId: predictionResponse.predictionId,
            pesticides: predictionResponse.result!.pesticides,
            precautions: predictionResponse.result!.precautions,
            sources: predictionResponse.result!.sources,
            recommendationSummary:
                predictionResponse.result!.recommendationSummary,
          );
          return PredictionResponse(
            success: predictionResponse.success,
            predictionId: predictionResponse.predictionId,
            status: predictionResponse.status,
            message: predictionResponse.message,
            mlResult: predictionResponse.mlResult,
            result: enrichedResult,
            questions: predictionResponse.questions,
          );
        }
        return predictionResponse;
      } else if (statusCode == 400) {
        final Map<String, dynamic> errJson = json.decode(responseBody);
        final msg =
            errJson['message'] ??
            errJson['errors']?['image']?[0] ??
            'Invalid image request.';
        throw Exception(msg.toString());
      } else {
        throw Exception(
          AppStrings.get('prediction_failed', isEnglish: language == 'en'),
        );
      }
    } on SocketException {
      throw Exception(
        AppStrings.get('network_error', isEnglish: language == 'en'),
      );
    } on http.ClientException {
      throw Exception(
        AppStrings.get('network_error', isEnglish: language == 'en'),
      );
    } on TimeoutException {
      throw Exception(
        AppStrings.get('network_error', isEnglish: language == 'en'),
      );
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception(e.toString());
    }
  }

  /// Submits answers to Agentic AI follow-up questions
  Future<PredictionResponse> submitFollowUpAnswers({
    required String predictionId,
    required List<Map<String, dynamic>> answers,
    required String language,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.aiRecommendationEndpoint}',
      );
      final payload = json.encode({
        'prediction_id': predictionId,
        'answers': answers,
        'language': language,
      });

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return PredictionResponse.fromJson(jsonResponse);
      } else {
        // Fallback to /api/prediction/<predictionId>/answers/
        final fallbackUri = Uri.parse(
          '${AppConfig.baseUrl}/prediction/$predictionId/answers/',
        );
        final fallbackResponse = await http
            .post(
              fallbackUri,
              headers: {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(AppConfig.receiveTimeout);

        if (fallbackResponse.statusCode == 200 ||
            fallbackResponse.statusCode == 201) {
          final Map<String, dynamic> fallbackJson = json.decode(
            fallbackResponse.body,
          );
          return PredictionResponse.fromJson(fallbackJson);
        }

        throw Exception(
          AppStrings.get('recommendation_failed', isEnglish: language == 'en'),
        );
      }
    } on SocketException {
      throw Exception(
        AppStrings.get('network_error', isEnglish: language == 'en'),
      );
    } on http.ClientException {
      throw Exception(
        AppStrings.get('network_error', isEnglish: language == 'en'),
      );
    } on TimeoutException {
      throw Exception(
        AppStrings.get('network_error', isEnglish: language == 'en'),
      );
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception(e.toString());
    }
  }

  /// Fetches recommendation details by disease ID
  Future<Map<String, dynamic>> getRecommendations(int diseaseId) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.recommendationsEndpoint}$diseaseId/',
      );
      final response = await http.get(uri).timeout(AppConfig.connectTimeout);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to fetch recommendations. Status: ${response.statusCode}',
        );
      }
    } on SocketException {
      throw Exception(AppStrings.get('network_error'));
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches prediction detail by ID
  Future<PredictionResponse> getPrediction(String predictionId) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/prediction/$predictionId/');
      final response = await http.get(uri).timeout(AppConfig.connectTimeout);
      if (response.statusCode == 200) {
        return PredictionResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Prediction not found.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches all crops
  Future<List<CropModel>> getCrops() async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}${AppConfig.cropsEndpoint}');
      final response = await http.get(uri).timeout(AppConfig.connectTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list
            .map((item) => CropModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches all diseases
  Future<List<DiseaseModel>> getDiseases() async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.diseasesEndpoint}',
      );
      final response = await http.get(uri).timeout(AppConfig.connectTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list
            .map((item) => DiseaseModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetches all pesticides
  Future<List<PesticideModel>> getPesticides() async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.pesticidesEndpoint}',
      );
      final response = await http.get(uri).timeout(AppConfig.connectTimeout);
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list
            .map(
              (item) => PesticideModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
