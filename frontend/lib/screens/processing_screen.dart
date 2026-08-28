// import 'dart:io';
// import 'package:flutter/material.dart';
// import '../widgets/loading_widget.dart';
// import '../services/api_service.dart';
// import '../models/disease_result_model.dart';

// class ProcessingScreen extends StatefulWidget {
//   const ProcessingScreen({super.key});

//   @override
//   State<ProcessingScreen> createState() => _ProcessingScreenState();
// }

// class _ProcessingScreenState extends State<ProcessingScreen> {
//   bool _isInit = true;
//   String _statusMessage = 'Analyzing your crop...';

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // This runs as soon as the screen loads
//     if (_isInit) {
//       // Catch the image passed from the upload screen
//       final File? imageFile = ModalRoute.of(context)?.settings.arguments as File?;
      
//       if (imageFile != null) {
//         _processImage(imageFile);
//       } else {
//         _showError('No image found. Please try again.');
//       }
//       _isInit = false;
//     }
//   }

//   Future<void> _processImage(File imageFile) async {
//     try {
//       // 1. Send the image to our API Service
//       final response = await ApiService().uploadCropImage(imageFile);
      
//       // 2. Parse the dummy JSON into our Dart model
//       final resultModel = DiseaseResultModel.fromJson(response);
      
//       // 3. If successful, push to Result Screen and hand over the model
//       if (mounted) {
//         Navigator.pushReplacementNamed(
//           context, 
//           '/result',
//           arguments: resultModel, // Passing the data forward!
//         );
//       }
//     } catch (e) {
//       // 4. Catch the farmer-friendly error messages from the service
//       _showError(e.toString());
//     }
//   }

//   void _showError(String errorMessage) {
//     // This tells Flutter to wait until the screen is fully built before popping the snackbar
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(errorMessage),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 4),
//           ),
//         );
//         // Kick them back to the upload screen to try again
//         Navigator.pop(context); 
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: LoadingWidget(message: _statusMessage),
//       ),
//     );
//   }
// }




import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/disease_result_model.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _hasStarted = false;

  String _statusMessage = 'Uploading your crop image...';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasStarted) {
      return;
    }

    _hasStarted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processImage();
    });
  }

  Future<void> _processImage() async {
    try {
      final arguments = ModalRoute.of(context)?.settings.arguments;

      if (arguments == null) {
        _showErrorAndGoBack(
          'No image found. Please select an image again.',
        );
        return;
      }

      Uint8List imageBytes;

      if (arguments is Uint8List) {
        imageBytes = arguments;
      } else if (arguments is List<int>) {
        imageBytes = Uint8List.fromList(arguments);
      } else {
        _showErrorAndGoBack(
          'Invalid image data. Please select the image again.',
        );
        return;
      }

      if (imageBytes.isEmpty) {
        _showErrorAndGoBack(
          'The selected image is empty. Please select another image.',
        );
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = 'Uploading your crop image...';
      });

      /*
       * Call backend.
       *
       * Expected response from your documented API:
       *
       * {
       *   "message": "Image uploaded successfully.",
       *   "image_id": 1,
       *   "image_url": "http://127.0.0.1:8000/media/leaf_images/..."
       * }
       */
      final response = await ApiService().uploadCropImage(
        imageBytes,
        filename: 'crop_leaf.jpg',
      );

      debugPrint('Upload response: $response');

      if (!mounted) {
        return;
      }

      /*
       * IMPORTANT:
       *
       * Your current backend documentation does NOT return:
       *
       * crop_name
       * disease_name
       * confidence
       * severity
       * description
       *
       * It only returns image_id and image_url.
       *
       * Therefore we create a DiseaseResultModel here using the
       * available image_url and fallback values for the prediction
       * fields.
       *
       * When your backend starts returning prediction data,
       * DiseaseResultModel.fromJson(response) will automatically
       * use those values.
       */

      final resultJson = <String, dynamic>{
        'crop_name': response['crop_name'] ?? 'Unknown Crop',
        'disease_name': response['disease_name'] ?? 'Unknown Disease',
        'confidence': response['confidence'] ?? 0.0,
        'severity': response['severity'] ?? 'Unknown Severity',
        'description':
            response['description'] ??
            'The image was uploaded successfully, but disease prediction data was not returned by the server yet.',
        'image_url': response['image_url'],
      };

      final DiseaseResultModel result =
          DiseaseResultModel.fromJson(resultJson);

      /*
       * IMPORTANT:
       *
       * We now send DiseaseResultModel,
       * NOT Map<String, dynamic>.
       *
       * Therefore ResultScreen can safely do:
       *
       * final result =
       *     arguments as DiseaseResultModel;
       */
      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: result,
      );
    } on ApiException catch (e) {
      debugPrint('API error: ${e.message}');

      _showErrorAndGoBack(e.message);
    } catch (e) {
      debugPrint('Processing error: $e');

      _showErrorAndGoBack(
        'Something went wrong while analyzing the crop. '
        'Please try again.',
      );
    }
  }

  void _showErrorAndGoBack(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: LoadingWidget(
            message: _statusMessage,
          ),
        ),
      ),
    );
  }
}
