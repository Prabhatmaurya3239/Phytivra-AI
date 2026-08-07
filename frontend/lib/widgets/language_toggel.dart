import 'package:flutter/material.dart';

class LanguageToggleWidget extends StatelessWidget {
  final bool isEnglish;
  final ValueChanged<bool> onToggle;

  const LanguageToggleWidget({
    super.key,
    required this.isEnglish,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'HI',
          style: TextStyle(fontWeight: !isEnglish ? FontWeight.bold : FontWeight.normal),
        ),
        Switch(
          value: isEnglish,
          activeThumbColor: Colors.green.shade700,
          onChanged: onToggle,
        ),
        Text(
          'EN',
          style: TextStyle(fontWeight: isEnglish ? FontWeight.bold : FontWeight.normal),
        ),
      ],
    );
  }
}