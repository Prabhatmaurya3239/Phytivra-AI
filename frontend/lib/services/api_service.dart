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
import 'dart:io' show File;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/app_config.dart';

class ApiService {
  Future<Map<String, dynamic>> uploadCropImage(dynamic image) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}${AppConfig.uploadEndpoint}'),
      );

      if (kIsWeb) {
        // Web: image is Uint8List
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          image as List<int>, // ✅ must be bytes
          filename: 'upload.png',
        ));
      } else {
        // Mobile/Desktop: image is File
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          (image as File).path,
        ));
      }

      var response = await request.send();

      if (response.statusCode == 201) {
        final respStr = await response.stream.bytesToString();
        return jsonDecode(respStr);
      } else if (response.statusCode == 400) {
        throw 'Invalid image format or file too large.';
      } else {
        throw 'Server error. Please try again later.';
      }
    } catch (e) {
      print("Error : ${e}");
      throw 'Something went wrong while analyzing the crop. Please try again.';
    }
  }
}
