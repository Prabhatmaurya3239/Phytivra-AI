import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/prediction_response.dart';
import '../models/disease_result_model.dart';
import '../models/question_model.dart';
import '../models/recommendation_model.dart';
import '../models/pesticide_model.dart';
import '../models/source_model.dart';

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

  /// Loads a simulated prototype scenario for immediate interactive testing:
  /// - 'high_confidence': 92% Tomato Early Blight completed result
  /// - 'low_confidence': 48% triggering Follow-up questions
  /// - 'unverified': Alien Crop with verified_info_available = false
  /// - 'failure': simulated ML failure
  void loadPrototypeScenario(String scenarioId) {
    resetWorkflow();
    _predictionId =
        'pred_prototype_${DateTime.now().millisecondsSinceEpoch % 10000}';

    if (scenarioId == 'high_confidence') {
      _currentResult = DiseaseResultModel(
        id: 1,
        cropName: 'Tomato',
        scientificName: 'Solanum lycopersicum',
        diseaseName: 'Early Blight',
        confidence: 0.92,
        severity: 'Medium',
        description: _isEnglish
            ? 'Early blight is caused by the fungus Alternaria solani. It produces brown to black spots with concentric rings forming a "target" pattern on older leaves.'
            : 'अगेती झुलसा (अर्ली ब्लाइट) अल्टरनेरिया सोलानी नामक कवक से होता है। पुरानी पत्तियों पर गाढ़े भूरे-काले छल्लेदार धब्बे बनते हैं।',
        symptoms: _isEnglish
            ? 'Dark brown spots with concentric rings, yellow halos around spots, defoliation from the base upwards.'
            : 'पत्तियों पर संकेंद्रित छल्लों वाले भूरे धब्बे, धब्बों के चारों ओर पीलापन और नीचे की पत्तियों का सूखना।',
        causes: _isEnglish
            ? 'High humidity, warm temperatures (24-29°C), and extended leaf wetness.'
            : 'उच्च आर्द्रता, 24-29°C तापमान और पत्तियों पर नमी बने रहना।',
        imageUrl: null,
        predictionId: _predictionId,
        pesticides: [
          PesticideModel(
            id: 1,
            name: 'Saaf (Mancozeb 63% + Carbendazim 12% WP)',
            companyName: 'UPL Ltd.',
            activeIngredient: 'Mancozeb 63% + Carbendazim 12% WP',
            description: _isEnglish
                ? 'Proven contact and systemic fungicide for controlling blights and leaf spots.'
                : 'पत्तियों के धब्बों और झुलसा रोग के प्रभावी नियंत्रण हेतु प्रमाणित फफूंदनाशक।',
            priceRange: '₹380 - ₹480',
            packingSize: '500g',
            dosage: '1.5 - 2.0 g/L',
            sprayMethod: 'Foliar spray',
            precautions: 'Wear gloves and mask. 7 days pre-harvest interval.',
            sourceType: 'government',
            sourceUrl: 'https://cibrc.gov.in',
          ),
          PesticideModel(
            id: 2,
            name: 'Amistar Top (Azoxystrobin 18.2% + Difenoconazole 11.4% SC)',
            companyName: 'Syngenta India Ltd.',
            activeIngredient: 'Azoxystrobin + Difenoconazole',
            description: _isEnglish
                ? 'Broad-spectrum dual systemic fungicide providing curative and preventive control.'
                : 'दोहरी प्रणालीगत फफूंदनाशक जो रोग का निवारक और उपचारात्मक नियंत्रण प्रदान करती है।',
            priceRange: '₹950 - ₹1200',
            packingSize: '200ml',
            dosage: '1.0 ml/L',
            sprayMethod: 'High volume foliar spray',
            precautions:
                'Rotate with different chemical class to prevent resistance.',
            sourceType: 'manufacturer',
            sourceUrl: 'https://www.syngenta.co.in',
          ),
        ],
        precautions: [
          _isEnglish
              ? 'Always wear protective gear during preparation and spraying.'
              : 'दवा मिलाते और छिड़कते समय दस्ताने और मास्क का प्रयोग करें।',
          _isEnglish
              ? 'Avoid spraying in midday heat or strong winds.'
              : 'दोपहर की तेज धूप या तेज हवा में छिड़काव न करें।',
          _isEnglish
              ? 'Observe the safety withholding interval before harvest.'
              : 'फसल तुड़ाई से पहले अनुशंसित प्रतीक्षा अवधि का पालन करें।',
        ],
        sources: [
          SourceModel(
            title:
                'Central Insecticides Board & Registration Committee (CIBRC)',
            url: 'https://cibrc.gov.in',
            sourceType: 'government',
            verified: true,
          ),
          SourceModel(
            title: 'ICAR-IARI Crop Protection Advisory',
            url: 'https://www.iari.res.in',
            sourceType: 'official',
            verified: true,
          ),
        ],
        recommendationSummary: _isEnglish
            ? 'Verified management information is available for Early Blight on Tomato.'
            : 'टमाटर की अगेती झुलसा बीमारी के लिए प्रमाणित प्रबंधन उपाय उपलब्ध हैं।',
      );

      _currentRecommendation = RecommendationModel(
        description: _currentResult!.description,
        pesticideName: _currentResult!.pesticides.first.name,
        companyName: _currentResult!.pesticides.first.companyName,
        priceRange: _currentResult!.pesticides.first.priceRange,
        packingSize: _currentResult!.pesticides.first.packingSize,
        dosage: _currentResult!.pesticides.first.dosage,
        sprayMethod: _currentResult!.pesticides.first.sprayMethod,
        precautions: _currentResult!.precautions.join('\n• '),
        pesticides: _currentResult!.pesticides,
        precautionsList: _currentResult!.precautions,
        sources: _currentResult!.sources,
      );

      _workflowState = PredictionWorkflowState.predictionCompleted;
      notifyListeners();
    } else if (scenarioId == 'low_confidence') {
      _workflowState = PredictionWorkflowState.needsQuestions;
      _questions = _isEnglish
          ? [
              QuestionModel(
                id: 'q1',
                question:
                    'What specific symptoms do you observe on the plant leaves or stems?',
                type: 'text',
                required: true,
              ),
              QuestionModel(
                id: 'q2',
                question: 'Which part of the plant is predominantly affected?',
                type: 'single_choice',
                options: [
                  'Older leaves',
                  'New leaves',
                  'Fruit',
                  'Stem',
                  'Whole plant'
                ],
                required: true,
              ),
              QuestionModel(
                id: 'q3',
                question: 'How long have you noticed these symptoms?',
                type: 'single_choice',
                options: [
                  'Within the last 3 days',
                  'Within the past week',
                  'More than a week ago'
                ],
                required: true,
              ),
              QuestionModel(
                id: 'q4',
                question: 'Are the spots spreading to neighboring plants?',
                type: 'boolean',
                required: false,
              ),
            ]
          : [
              QuestionModel(
                id: 'q1',
                question:
                    'पौधे की पत्तियों या तनों पर आपको क्या विशिष्ट लक्षण दिखाई दे रहे हैं?',
                type: 'text',
                required: true,
              ),
              QuestionModel(
                id: 'q2',
                question: 'पौधे का कौन सा भाग मुख्य रूप से प्रभावित है?',
                type: 'single_choice',
                options: [
                  'पुरानी पत्तियां',
                  'नई पत्तियां',
                  'फल',
                  'तना',
                  'पूरा पौधा'
                ],
                required: true,
              ),
              QuestionModel(
                id: 'q3',
                question: 'आप कितने समय से इन लक्षणों को देख रहे हैं?',
                type: 'single_choice',
                options: [
                  'पिछले 3 दिनों से',
                  'पिछले 1 सप्ताह से',
                  '1 सप्ताह से अधिक समय से'
                ],
                required: true,
              ),
              QuestionModel(
                id: 'q4',
                question:
                    'क्या ये धब्बे आस-पास के पौधों में भी फैल रहे हैं?',
                type: 'boolean',
                required: false,
              ),
            ];
      notifyListeners();
    } else if (scenarioId == 'unverified') {
      _currentResult = DiseaseResultModel(
        id: 99,
        cropName: 'Unidentified Crop',
        diseaseName: 'Unknown Condition',
        confidence: 0.28,
        severity: 'Unknown',
        description: _isEnglish
            ? 'No verified information is available for this case. The AI safety system will not invent unverified pesticide recommendations.'
            : 'इस स्थिति के लिए कोई प्रमाणित जानकारी उपलब्ध नहीं है। एआई सुरक्षा नियम अज्ञात रासायनिक उपचार की सिफारिश नहीं करते।',
        pesticides: [],
        precautions: [
          _isEnglish
              ? 'Do not spray unverified chemicals without agricultural expert confirmation.'
              : 'कृषि विशेषज्ञ की पुष्टि के बिना किसी भी अज्ञात रसायन का छिड़काव न करें।'
        ],
        sources: [
          SourceModel(
            title: 'Krishi Vigyan Kendra (KVK) Advisory',
            sourceType: 'extension',
            verified: true,
          )
        ],
        recommendationSummary: _isEnglish
            ? 'Verified information is not available for this case.'
            : 'इस मामले के लिए प्रमाणित जानकारी उपलब्ध नहीं है।',
      );
      _currentRecommendation = RecommendationModel(
        description: _currentResult!.description,
        pesticideName: 'None',
        companyName: '',
        priceRange: '',
        packingSize: '',
        dosage: '',
        sprayMethod: '',
        precautions: _currentResult!.precautions.join('\n'),
        pesticides: [],
        precautionsList: _currentResult!.precautions,
        sources: _currentResult!.sources,
      );
      _workflowState = PredictionWorkflowState.predictionCompleted;
      notifyListeners();
    } else if (scenarioId == 'failure') {
      _errorMessage = _isEnglish
          ? 'ML Prediction Service error: Failed to process image. Tap retry below.'
          : 'एमएल भविष्यवाणी सेवा त्रुटि: छवि संसाधित करने में विफल। नीचे पुनः प्रयास करें।';
      _errorType = 'prediction';
      _workflowState = PredictionWorkflowState.failed;
      notifyListeners();
    }
  }
}
