import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  // We will swap these out when the backend team actually gives us the real URLs.
  // For now, these are just safe placeholders.
  // static const String baseUrl = 'https://api.dummy-backend.com/api/v1';
  // static const String uploadEndpoint = '/predict-disease';
 static const String baseUrl = kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://10.0.2.2:8000/api';
  static const String uploadEndpoint = '/prediction/upload/';

  // Add these new endpoints from the API Docs:
  static const String cropsEndpoint = '/crops/';
  static const String diseasesEndpoint = '/diseases/';
  static const String pesticidesEndpoint = '/pesticides/';
  static const String recommendationsEndpoint = '/recommendations/';
}