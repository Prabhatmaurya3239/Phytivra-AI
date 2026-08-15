import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';

class ApiService {
  
  // This is the function we will call when the user clicks "Upload"
  Future<Map<String, dynamic>> uploadCropImage(File imageFile) async {
    try {
      // 1. Prepare the request to the backend URL
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}${AppConfig.uploadEndpoint}'),
      );
      
      // 2. Attach the image file to the request
      // We are guessing the field name is 'image' for now.
      // comented this out while testing on web
      //request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
      // 3. Simulate a network delay so we can test the loading screen later
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
}