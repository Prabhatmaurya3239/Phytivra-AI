import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AppConfig {
  /// Base API URL dynamically chosen based on runtime platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Emulator loops back to host via 10.0.2.2
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://127.0.0.1:8000/api';
    }
  }

  // Endpoints
  static const String predictEndpoint = '/prediction/predict/';
  static const String uploadEndpoint = '/prediction/upload/';
  static const String cropsEndpoint = '/crops/';
  static const String diseasesEndpoint = '/diseases/';
  static const String pesticidesEndpoint = '/pesticides/';
  static const String recommendationsEndpoint = '/recommendations/';
  static const String aiFollowUpEndpoint = '/ai/follow-up/';
  static const String aiRecommendationEndpoint = '/ai/recommendation/';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
