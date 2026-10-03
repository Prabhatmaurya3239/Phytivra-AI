import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import 'package:image_picker/image_picker.dart';

class ApiService {
  
  // This is the function we will call when the user clicks "Upload"
  Future<Map<String, dynamic>> uploadCropImage(XFile imageFile) async {
    try {
      // 1. Prepare the request to the backend URL
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}${AppConfig.uploadEndpoint}'),
      );
      
      // 2. Attach the image file to the request
      // We are guessing the field name is 'image' for now.
      // comented this out while testing on web
      var fileBytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', fileBytes, filename: imageFile.name));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var uploadData = json.decode(responseBody);
      
       if (response.statusCode == 201) {
        // Since upload doesn't return ML predictions yet, chain the GET requests
        // (Hardcoding ID 1 for now as per your instructions)
        var diseaseResponse = await http.get(Uri.parse('${AppConfig.baseUrl}/disease/1/'));
        var diseaseData = json.decode(diseaseResponse.body);
        
        var cropResponse = await http.get(Uri.parse('${AppConfig.baseUrl}/crops/${diseaseData['crop']}/'));
        var cropData = json.decode(cropResponse.body);
        
        return {
          'id': diseaseData['id'],
          'crop_name': cropData['name'],
          'disease_name': diseaseData['name'],
          'confidence': 0.95, 
          'severity': diseaseData['severity'],
          'description': diseaseData['description'],
          'image_url': uploadData['image_url'], 
        };
      } else if (response.statusCode == 400) {
        throw uploadData['errors']?['image']?[0] ?? 'Bad Request';
      } else {
        throw 'Failed to upload image. Status code: ${response.statusCode}';
      }
    } on SocketException {
      throw 'Please check your internet connection and try again.';
    } catch (e) {
      throw e.toString();
    }
  }
      // Add this new method to fetch the recommendations!
  Future<Map<String, dynamic>> getRecommendations(int diseaseId) async {
    try {
      var response = await http.get(Uri.parse('${AppConfig.baseUrl}/recommendations/$diseaseId/'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw 'Failed to fetch recommendations.';
      }
    } catch (e) {
      throw e.toString();
    }
  }
}
/*      // 3. Simulate a network delay so we can test the loading screen later
      await Future.delayed(const Duration(seconds: 2));
      
      // (We will uncomment the real network call when the backend is ready)
      // var response = await request.send();
      
      // 4. Return a dummy successful JSON response so we can keep building the UI
      return {
        'status': 'success', 
        'disease_name': 'Early Blight',
        'confidence': 0.95
      }; 
      
    } on SocketException {
      // Catches instances where the user has no internet[cite: 2]
      throw 'Please check your internet connection and try again.';
    } catch (e) {
      // Catches generic server crashes[cite: 2]
      throw 'Something went wrong while analyzing the crop. Please try again.'; 
    }
  }
}*/