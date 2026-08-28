// import 'dart:io';
// import 'package:http/http.dart' as http;
// import '../core/app_config.dart';

// class ApiService {
  
//   // This is the function we will call when the user clicks "Upload"
//   Future<Map<String, dynamic>> uploadCropImage(File imageFile) async {
//     try {
//       // 1. Prepare the request to the backend URL
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('${AppConfig.baseUrl}${AppConfig.uploadEndpoint}'),
//       );
      
//       // 2. Attach the image file to the request
//       // We are guessing the field name is 'image' for now.
//       // comented this out while testing on web
//       //request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
//       // 3. Simulate a network delay so we can test the loading screen later
//       await Future.delayed(const Duration(seconds: 2));
      
//       // (We will uncomment the real network call when the backend is ready)
//       // var response = await request.send();
      
//       // 4. Return a dummy successful JSON response so we can keep building the UI
//       return {
//         'status': 'success', 
//         'disease_name': 'Early Blight',
//         'confidence': 0.95
//       }; 
      
//     } on SocketException {
//       // Catches instances where the user has no internet[cite: 2]
//       throw 'Please check your internet connection and try again.';
//     } catch (e) {
//       // Catches generic server crashes[cite: 2]
//       throw 'Something went wrong while analyzing the crop. Please try again.'; 
//     }
//   }
// }

// for android not run in web
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import '../core/app_config.dart';

// class ApiService {
//   Future<Map<String, dynamic>> uploadCropImage(File imageFile) async {
//     try {
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('${AppConfig.baseUrl}${AppConfig.uploadEndpoint}'),
//       );

//       request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

//       var response = await request.send();

//       if (response.statusCode == 201) {
//         final respStr = await response.stream.bytesToString();
//         return jsonDecode(respStr); // ✅ decode JSON properly
//       } else if (response.statusCode == 400) {
//         throw 'Invalid image format or file too large.';
//       } else {
//         throw 'Server error. Please try again later.';
//       }
//     } on SocketException {
//       throw 'Please check your internet connection and try again.';
//     } catch (e) {
//       print(e);
//       throw "Something went wrong while analyzing the crop. Please try again. ${e}";
//     }
//   }
// }

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_config.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> uploadCropImage(
    Uint8List imageBytes, {
    String filename = 'crop_leaf.jpg',
  }) async {
    try {
      if (imageBytes.isEmpty) {
        throw ApiException(
          'The selected image is empty.',
        );
      }

      // Backend documentation:
      // POST /api/prediction/upload/
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.uploadEndpoint}',
      );

      final request = http.MultipartRequest(
        'POST',
        uri,
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: _safeFilename(filename),
        ),
      );

      final streamedResponse = await _client.send(request);

      final responseBody =
          await streamedResponse.stream.bytesToString();

      Map<String, dynamic> responseData = {};

      if (responseBody.isNotEmpty) {
        try {
          final decoded = jsonDecode(responseBody);

          if (decoded is Map<String, dynamic>) {
            responseData = decoded;
          } else if (decoded is Map) {
            responseData = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          responseData = {};
        }
      }

      switch (streamedResponse.statusCode) {
        case 201:
          return responseData;

        case 400:
          throw ApiException(
            _extractValidationError(responseData) ??
                'Invalid image format or file size. '
                    'Please upload a JPG, JPEG, PNG, or WEBP image '
                    'smaller than 5 MB.',
          );

        case 404:
          throw ApiException(
            'Upload API was not found. '
            'Please check the backend URL and endpoint.',
          );

        case 500:
          throw ApiException(
            'The server encountered an error. Please try again later.',
          );

        default:
          throw ApiException(
            'Server error (${streamedResponse.statusCode}). '
            'Please try again later.',
          );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('ApiService upload error: $e');

      throw ApiException(
        _networkErrorMessage(e),
      );
    }
  }

  String _safeFilename(String filename) {
    final cleaned = filename.trim();

    if (cleaned.isEmpty) {
      return 'crop_leaf.jpg';
    }

    return cleaned;
  }

  String? _extractValidationError(
    Map<String, dynamic> response,
  ) {
    final errors = response['errors'];

    if (errors is Map) {
      final imageErrors = errors['image'];

      if (imageErrors is List && imageErrors.isNotEmpty) {
        return imageErrors.first.toString();
      }

      if (imageErrors != null) {
        return imageErrors.toString();
      }
    }

    final detail = response['detail'];

    if (detail != null) {
      return detail.toString();
    }

    final message = response['message'];

    if (message != null) {
      return message.toString();
    }

    return null;
  }

  String _networkErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('connection refused') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection reset') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('socketexception')) {
      return 'Unable to connect to the server. '
          'Please make sure the Phytivra-AI backend is running '
          'and the API address is correct.';
    }

    if (errorString.contains('timeout')) {
      return 'The server took too long to respond. '
          'Please try again.';
    }

    return 'Something went wrong while uploading the crop image. '
        'Please try again.';
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

