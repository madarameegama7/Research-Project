import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api.dart';
import '../models/prediction_response.dart';

// Only import dart:io on non-web platforms
import 'dart:io' as io show SocketException, Platform;

class YieldPredictionService {
  // Get the correct base URL based on platform
  // Android emulator: use 10.0.2.2 to reach host machine
  // Other platforms: use 127.0.0.1
  static String get _baseUrl {
    if (!kIsWeb && io.Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  // For production, use a remote server IP
  // static const String _remoteUrl = 'http://192.168.x.x:8000';

  /// Predict yield from plant image and environmental data
  ///
  /// Parameters:
  /// - [imageFile]: Plant image file (XFile from image_picker, works on all platforms)
  /// - [soilMoisture]: Soil moisture percentage (0-100)
  /// - [temperature]: Environmental temperature in °C
  /// - [rainfall]: Optional rainfall in mm
  ///
  /// Returns: PredictionResponse with yield, insights, and top factors
  Future<PredictionResponse> predictYield({
    required dynamic imageFile,
    required double soilMoisture,
    required double temperature,
    double? rainfall,
    String? plantAge,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/predict'),
      );

      // Handle image file - works on both mobile and web
      Uint8List imageBytes;
      String fileName;

      // Try to get bytes from the file object
      try {
        if (imageFile is XFile) {
          // XFile from image_picker - works on all platforms
          imageBytes = await imageFile.readAsBytes();
          fileName = imageFile.name;
        } else if (!kIsWeb &&
            imageFile.runtimeType.toString().contains('File')) {
          // Mobile platform - use dart:io.File
          imageBytes = await imageFile.readAsBytes();
          fileName = imageFile.path.split('/').last;
        } else if (imageFile.runtimeType.toString().contains('PlatformFile')) {
          // Web platform - PlatformFile from file_picker
          imageBytes = imageFile.bytes ?? Uint8List(0);
          fileName = imageFile.name ?? 'image.jpg';
        } else if (imageFile is Uint8List) {
          // Already bytes
          imageBytes = imageFile;
          fileName = 'image.jpg';
        } else {
          throw Exception(
            'Unsupported image type: ${imageFile.runtimeType}. Please use XFile from image_picker.',
          );
        }

        if (imageBytes.isEmpty) {
          throw Exception('Image file is empty. Please select a valid image.');
        }
      } catch (e) {
        throw Exception('Error reading image: $e');
      }

      // Add image file using fromBytes (works on both platforms)
      // Explicitly set content type as image/jpeg to ensure FastAPI recognizes it
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
          contentType: contentTypeFromFileName(fileName),
        ),
      );

      // Add form fields
      request.fields['soil_moisture'] = soilMoisture.toString();
      request.fields['temperature'] = temperature.toString();

      if (rainfall != null) {
        request.fields['rainfall'] = rainfall.toString();
      }
      if (plantAge != null) {
        request.fields['plant_age'] = plantAge;
      }

      // Debug logging
      print('[YieldPrediction] Sending request to: $_baseUrl/predict');
      print('[YieldPrediction] Image size: ${imageBytes.length} bytes');
      print('[YieldPrediction] Image name: $fileName');
      print('[YieldPrediction] Soil moisture: $soilMoisture');
      print('[YieldPrediction] Temperature: $temperature');
      print('[YieldPrediction] Request fields: ${request.fields}');
      print(
        '[YieldPrediction] Request files: ${request.files.map((f) => '${f.field}(${f.filename})').toList()}',
      );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'Prediction request timed out after 30 seconds',
          );
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(await response.stream.bytesToString());
        print('[YieldPrediction] Response: $responseData');
        return PredictionResponse.fromJson(responseData);
      } else {
        final errorBody = await response.stream.bytesToString();
        print('[YieldPrediction] Error response: $errorBody');
        throw Exception(
          'Failed to predict yield: ${response.statusCode} - $errorBody',
        );
      }
    } on io.SocketException {
      throw Exception(
        'Cannot connect to prediction server. Ensure the API is running on $_baseUrl',
      );
    } catch (e) {
      throw Exception('Error predicting yield: $e');
    }
  }

  /// Get health status of the prediction API
  Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Update the FastAPI server URL (e.g., when using remote server)
  static void setBaseUrl(String url) {
    // This would require making the const mutable
    // For now, edit this file directly based on your deployment
  }

  /// Helper function to get the correct MIME type based on file extension
  static MediaType contentTypeFromFileName(String fileName) {
    final lowerName = fileName.toLowerCase();

    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    } else if (lowerName.endsWith('.png')) {
      return MediaType('image', 'png');
    } else if (lowerName.endsWith('.gif')) {
      return MediaType('image', 'gif');
    } else if (lowerName.endsWith('.webp')) {
      return MediaType('image', 'webp');
    } else {
      // Default to jpeg if extension is unknown
      return MediaType('image', 'jpeg');
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
