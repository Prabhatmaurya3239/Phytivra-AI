import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/loading_widget.dart';
import '../services/api_service.dart';
import '../models/disease_result_model.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _isInit = true;
  String _statusMessage = 'Analyzing your crop...';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This runs as soon as the screen loads
    if (_isInit) {
      // Catch the image passed from the upload screen
      final File? imageFile = ModalRoute.of(context)?.settings.arguments as File?;
      
      if (imageFile != null) {
        _processImage(imageFile);
      } else {
        _showError('No image found. Please try again.');
      }
      _isInit = false;
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      // 1. Send the image to our API Service
      final response = await ApiService().uploadCropImage(imageFile);
      
      // 2. Parse the dummy JSON into our Dart model
      final resultModel = DiseaseResultModel.fromJson(response);
      
      // 3. If successful, push to Result Screen and hand over the model
      if (mounted) {
        Navigator.pushReplacementNamed(
          context, 
          '/result',
          arguments: resultModel, // Passing the data forward!
        );
      }
    } catch (e) {
      // 4. Catch the farmer-friendly error messages from the service
      _showError(e.toString());
    }
  }

  void _showError(String errorMessage) {
    // This tells Flutter to wait until the screen is fully built before popping the snackbar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        // Kick them back to the upload screen to try again
        Navigator.pop(context); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LoadingWidget(message: _statusMessage),
      ),
    );
  }
}