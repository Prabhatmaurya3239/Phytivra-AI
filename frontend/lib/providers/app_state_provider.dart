import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/prediction_response.dart';
import '../models/disease_result_model.dart';
import '../models/question_model.dart';
import '../models/recommendation_model.dart';

enum PredictionWorkflowState {
  initial,
  uploading,
  processing,
  predictionCompleted,
  needsQuestions,
  submittingAnswers,
  generatingRecommendation,
  recommendationCompleted,
  failed,
}

class AppStateProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Language state
  bool _isEnglish = true;
  bool get isEnglish => _isEnglish;
  String get languageCode => _isEnglish ? 'en' : 'hi';

  // Workflow state
  PredictionWorkflowState _workflowState = PredictionWorkflowState.initial;
  PredictionWorkflowState get workflowState => _workflowState;

  // Selected image
  XFile? _selectedImage;
  XFile? get selectedImage => _selectedImage;

  // Prediction and AI state
  String? _predictionId;
  String? get predictionId => _predictionId;

  PredictionResponse? _lastPredictionResponse;
  PredictionResponse? get lastPredictionResponse => _lastPredictionResponse;

  DiseaseResultModel? _currentResult;
  DiseaseResultModel? get currentResult => _currentResult;

  RecommendationModel? _currentRecommendation;
  RecommendationModel? get currentRecommendation => _currentRecommendation;

  List<QuestionModel> _questions = [];
  List<QuestionModel> get questions => _questions;

  final Map<String, dynamic> _userAnswers = {};
  Map<String, dynamic> get userAnswers => _userAnswers;

  // Status & Error state
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _errorType; // 'network', 'prediction', 'recommendation', 'general'
  String? get errorType => _errorType;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  void toggleLanguage(bool value) {
    _isEnglish = value;
    notifyListeners();
  }

  void setLanguageCode(String code) {
    _isEnglish = (code.toLowerCase() == 'en');
    notifyListeners();
  }

  void setSelectedImage(XFile? file) {
    _selectedImage = file;
    _errorMessage = null;
    notifyListeners();
  }

  void clearImage() {
    _selectedImage = null;
    notifyListeners();
  }

  void setAnswer(String questionId, dynamic answer) {
    _userAnswers[questionId] = answer;
    notifyListeners();
  }

  dynamic getAnswer(String questionId) {
    return _userAnswers[questionId];
  }

  /// Validates whether all required follow-up questions have been answered
  bool validateRequiredAnswers() {
    for (final q in _questions) {
      if (q.required) {
        final ans = _userAnswers[q.id];
        if (ans == null) return false;
        if (ans is String && ans.trim().isEmpty) return false;
        if (ans is List && ans.isEmpty) return false;
      }
    }
    return true;
  }

  /// Starts disease diagnosis from uploaded leaf image
  Future<bool> startPrediction({String? userNote}) async {
    if (_isSubmitting) return false;
    if (_selectedImage == null) {
      _errorMessage = 'Please select a crop leaf image first.';
      _workflowState = PredictionWorkflowState.failed;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _errorType = null;
    _workflowState = PredictionWorkflowState.uploading;
    notifyListeners();

    try {
      _workflowState = PredictionWorkflowState.processing;
      notifyListeners();

      final response = await _apiService.predictDisease(
        imageFile: _selectedImage!,
        language: languageCode,
        userNote: userNote,
      );

      _lastPredictionResponse = response;
      _predictionId = response.predictionId;

      if (response.needsQuestions) {
        // Low confidence flow -> Agentic AI questions
        _workflowState = PredictionWorkflowState.needsQuestions;
        _questions = response.questions;
        _userAnswers.clear();
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else if (response.isCompleted && response.result != null) {
        // High confidence flow -> Disease result completed
        _workflowState = PredictionWorkflowState.predictionCompleted;
        _currentResult = response.result;

        // Auto-build recommendation model
        _currentRecommendation = RecommendationModel(
          description: response.result!.description,
          pesticideName: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.name
              : '',
          companyName: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.companyName
              : '',
          priceRange: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.priceRange
              : '',
          packingSize: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.packingSize
              : '',
          dosage: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.dosage
              : '',
          sprayMethod: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.sprayMethod
              : '',
          precautions: response.result!.precautions.join('\n• '),
          pesticides: response.result!.pesticides,
          precautionsList: response.result!.precautions,
          sources: response.result!.sources,
        );

        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(
          response.message ?? 'Diagnosis could not be completed.',
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = msg;
      _errorType =
          msg.toLowerCase().contains('connection') ||
              msg.toLowerCase().contains('internet')
          ? 'network'
          : 'prediction';
      _workflowState = PredictionWorkflowState.failed;
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Submits farmer answers to follow-up questions
  Future<bool> submitFollowUpAnswers() async {
    if (_isSubmitting) return false;
    if (_predictionId == null) {
      _errorMessage = 'No active prediction session found.';
      notifyListeners();
      return false;
    }

    if (!validateRequiredAnswers()) {
      _errorMessage = 'Please answer all required questions before submitting.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _workflowState = PredictionWorkflowState.submittingAnswers;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> answersList = [];
      _userAnswers.forEach((key, val) {
        String answerString;
        if (val is List) {
          answerString = val.join(', ');
        } else if (val is bool) {
          answerString = val ? 'Yes' : 'No';
        } else {
          answerString = val.toString();
        }
        answersList.add({'question_id': key, 'answer': answerString});
      });

      _workflowState = PredictionWorkflowState.generatingRecommendation;
      notifyListeners();

      final response = await _apiService.submitFollowUpAnswers(
        predictionId: _predictionId!,
        answers: answersList,
        language: languageCode,
      );

      _lastPredictionResponse = response;

      if (response.isCompleted && response.result != null) {
        _currentResult = response.result;
        _currentRecommendation = RecommendationModel(
          description: response.result!.description,
          pesticideName: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.name
              : '',
          companyName: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.companyName
              : '',
          priceRange: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.priceRange
              : '',
          packingSize: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.packingSize
              : '',
          dosage: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.dosage
              : '',
          sprayMethod: response.result!.pesticides.isNotEmpty
              ? response.result!.pesticides.first.sprayMethod
              : '',
          precautions: response.result!.precautions.join('\n• '),
          pesticides: response.result!.pesticides,
          precautionsList: response.result!.precautions,
          sources: response.result!.sources,
        );
        _workflowState = PredictionWorkflowState.recommendationCompleted;
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(
          response.message ?? 'Failed to generate recommendation.',
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _errorMessage = msg;
      _errorType =
          msg.toLowerCase().contains('connection') ||
              msg.toLowerCase().contains('internet')
          ? 'network'
          : 'recommendation';
      _workflowState = PredictionWorkflowState.failed;
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Retries the failed action according to the workflow state
  Future<bool> retryLastAction() {
    if (_workflowState == PredictionWorkflowState.failed) {
      if (_questions.isNotEmpty && _userAnswers.isNotEmpty) {
        return submitFollowUpAnswers();
      } else if (_selectedImage != null) {
        return startPrediction();
      }
    }
    return Future.value(false);
  }

  /// Resets the workflow completely for a clean new diagnosis
  void resetWorkflow() {
    _workflowState = PredictionWorkflowState.initial;
    _selectedImage = null;
    _predictionId = null;
    _lastPredictionResponse = null;
    _currentResult = null;
    _currentRecommendation = null;
    _questions = [];
    _userAnswers.clear();
    _errorMessage = null;
    _errorType = null;
    _isSubmitting = false;
    notifyListeners();
  }
}
