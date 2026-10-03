import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:crop_app/main.dart';
import 'package:crop_app/providers/app_state_provider.dart';
import 'package:crop_app/models/question_model.dart';
import 'package:crop_app/models/pesticide_model.dart';
import 'package:crop_app/models/prediction_response.dart';

void main() {
  testWidgets('App renders Home screen correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AppStateProvider(),
        child: const CropDiseaseApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Greeting are present
    expect(find.text('Phytivra-AI'), findsOneWidget);
    expect(find.text('Namaste, Kisan Mitra! 🌾'), findsOneWidget);
    expect(find.text('Start Diagnosis'), findsOneWidget);
  });

  test('QuestionModel parses all dynamic types correctly', () {
    final textQ = QuestionModel.fromJson({
      'id': 'q1',
      'question': 'What symptoms are you seeing?',
      'type': 'text',
      'required': true,
    });
    expect(textQ.type, 'text');
    expect(textQ.required, true);

    final choiceQ = QuestionModel.fromJson({
      'id': 'q2',
      'question': 'Which part is affected?',
      'type': 'single_choice',
      'options': ['Leaves', 'Stem', 'Fruit'],
      'required': true,
    });
    expect(choiceQ.type, 'single_choice');
    expect(choiceQ.options.length, 3);
  });

  test('PesticideModel handles missing fields with safety fallbacks', () {
    final pest = PesticideModel.fromJson({
      'name': 'Sample Product',
      'dosage': null,
      'price_range': null,
    });
    expect(pest.name, 'Sample Product');
    expect(pest.dosage, PesticideModel.fallbackUnavailable);
    expect(pest.priceRange, PesticideModel.fallbackUnavailable);
  });

  test('PredictionResponse parses completed high confidence result', () {
    final json = {
      'success': true,
      'prediction_id': 'pred_001',
      'status': 'completed',
      'result': {
        'crop': {'id': 1, 'name': 'Tomato'},
        'disease': {'id': 1, 'name': 'Early Blight', 'severity': 'Medium'},
        'confidence': {'score': 0.92, 'percentage': 92},
        'recommendation': {'available': true, 'summary': 'Treatment available'},
        'pesticides': [],
        'precautions': ['Follow label instructions'],
      },
    };
    final resp = PredictionResponse.fromJson(json);
    expect(resp.isCompleted, true);
    expect(resp.result?.cropName, 'Tomato');
    expect(resp.result?.diseaseName, 'Early Blight');
    expect(resp.result?.confidence, 0.92);
  });

  test('PredictionResponse parses low confidence needs_questions flow', () {
    final json = {
      'success': true,
      'prediction_id': 'pred_002',
      'status': 'needs_questions',
      'questions': [
        {'id': 'q1', 'question': 'Symptom duration?', 'type': 'text'},
      ],
    };
    final resp = PredictionResponse.fromJson(json);
    expect(resp.needsQuestions, true);
    expect(resp.questions.length, 1);
    expect(resp.questions[0].id, 'q1');
  });
}
