import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../core/app_theme.dart';

class QuestionWidget extends StatefulWidget {
  final int index;
  final QuestionModel question;
  final dynamic initialAnswer;
  final ValueChanged<dynamic> onAnswerChanged;
  final bool isEnglish;

  const QuestionWidget({
    super.key,
    required this.index,
    required this.question,
    this.initialAnswer,
    required this.onAnswerChanged,
    this.isEnglish = true,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  late TextEditingController _textController;
  late dynamic _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialAnswer;
    _textController = TextEditingController(
      text: widget.initialAnswer is String ? widget.initialAnswer : '',
    );
  }

  @override
  void didUpdateWidget(covariant QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAnswer != oldWidget.initialAnswer) {
      _currentValue = widget.initialAnswer;
      if (widget.question.type == 'text' || widget.question.type == 'number') {
        if (_textController.text != (widget.initialAnswer?.toString() ?? '')) {
          _textController.text = widget.initialAnswer?.toString() ?? '';
        }
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _updateValue(dynamic val) {
    setState(() {
      _currentValue = val;
    });
    widget.onAnswerChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              widget.question.required &&
                  (_currentValue == null ||
                      (_currentValue is String &&
                          (_currentValue as String).isEmpty))
              ? Colors.orange.shade200
              : const Color(0xFFC8E6C9),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Question number & required badge
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.question.question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                if (widget.question.required)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      widget.isEnglish ? 'Required *' : 'आवश्यक *',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Dynamic Input rendering according to question type
            _buildInputControl(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputControl() {
    switch (widget.question.type) {
      case 'number':
        return TextField(
          controller: _textController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: widget.isEnglish
                ? 'Enter number or days...'
                : 'संख्या या दिन दर्ज करें...',
            prefixIcon: const Icon(Icons.numbers, color: AppTheme.primaryGreen),
          ),
          onChanged: _updateValue,
        );

      case 'single_choice':
        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.question.options.map((option) {
            final isSelected = (_currentValue?.toString() == option);
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              selectedColor: AppTheme.primaryGreen,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  _updateValue(option);
                }
              },
            );
          }).toList(),
        );

      case 'multiple_choice':
        final List<String> selectedList = (_currentValue is List)
            ? List<String>.from(_currentValue)
            : [];
        return Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.question.options.map((option) {
            final isSelected = selectedList.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              selectedColor: AppTheme.primaryGreen,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                final updated = List<String>.from(selectedList);
                if (selected) {
                  updated.add(option);
                } else {
                  updated.remove(option);
                }
                _updateValue(updated);
              },
            );
          }).toList(),
        );

      case 'boolean':
        final bool? boolVal = (_currentValue is bool)
            ? _currentValue as bool
            : (_currentValue?.toString().toLowerCase() == 'yes' ||
                      _currentValue?.toString() == 'हाँ'
                  ? true
                  : (_currentValue?.toString().toLowerCase() == 'no' ||
                            _currentValue?.toString() == 'नहीं'
                        ? false
                        : null));

        final String yesText = widget.isEnglish ? 'Yes' : 'हाँ';
        final String noText = widget.isEnglish ? 'No' : 'नहीं';

        return Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: Center(
                  child: Text(
                    yesText,
                    style: TextStyle(
                      color: boolVal == true ? Colors.white : AppTheme.textDark,
                      fontWeight: boolVal == true
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                selected: boolVal == true,
                selectedColor: AppTheme.primaryGreen,
                onSelected: (selected) {
                  if (selected) _updateValue(true);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: Center(
                  child: Text(
                    noText,
                    style: TextStyle(
                      color: boolVal == false
                          ? Colors.white
                          : AppTheme.textDark,
                      fontWeight: boolVal == false
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                selected: boolVal == false,
                selectedColor: Colors.red.shade600,
                onSelected: (selected) {
                  if (selected) _updateValue(false);
                },
              ),
            ),
          ],
        );

      case 'text':
      default:
        return TextField(
          controller: _textController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: widget.isEnglish
                ? 'Describe what you observe...'
                : 'जो लक्षण दिख रहे हैं लिखें...',
            prefixIcon: const Icon(
              Icons.edit_note,
              color: AppTheme.primaryGreen,
            ),
          ),
          onChanged: _updateValue,
        );
    }
  }
}
