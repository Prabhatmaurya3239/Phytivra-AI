import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  // Centralized state for the application language
  bool _isEnglish = true;

  bool get isEnglish => _isEnglish;

  void toggleLanguage(bool value) {
    _isEnglish = value;
    notifyListeners(); // This magically tells the whole app to update!
  }
}