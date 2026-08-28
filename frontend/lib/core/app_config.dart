// class AppConfig {
//   // We will swap these out when the backend team actually gives us the real URLs.
//   // For now, these are just safe placeholders.
//   static const String baseUrl = 'http://127.0.0.1:8000/api/';
//   static const String uploadEndpoint = '/predict-disease';
//   static const String crops = '/crops';

// }

class AppConfig {
  // Base URL for all API requests
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Image upload endpoint (for crop leaf disease prediction)
  static const String uploadEndpoint = '/prediction/upload/';

  // Crop APIs
  static const String crops = '/crops/';
  static const String cropDetails = '/crops/'; // append <id>/ when fetching details

  // Disease APIs
  static const String diseases = '/diseases/';
  static const String diseaseDetails = '/diseases/'; // append <id>/ when fetching details

  // Pesticide APIs
  static const String pesticides = '/pesticides/';
  static const String pesticideDetails = '/pesticides/'; // append <id>/ when fetching details

  // Recommendation API
  static const String recommendations = '/recommendations/'; // append <disease_id>/ when fetching
}
