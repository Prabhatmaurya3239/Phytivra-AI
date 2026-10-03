class QuestionModel {
  final String id;
  final String question;
  final String
  type; // 'text', 'number', 'single_choice', 'multiple_choice', 'boolean'
  final List<String> options;
  final bool required;

  QuestionModel({
    required this.id,
    required this.question,
    this.type = 'text',
    this.options = const [],
    this.required = true,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<String> parsedOptions = [];
    if (rawOptions is List) {
      parsedOptions = rawOptions.map((e) => e.toString()).toList();
    }

    return QuestionModel(
      id: (json['id'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString().toLowerCase(),
      options: parsedOptions,
      required: json['required'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'type': type,
    'options': options,
    'required': required,
  };
}
