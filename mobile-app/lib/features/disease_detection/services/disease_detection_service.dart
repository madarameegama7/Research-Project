import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DiseaseDetectionService {
  // Use 10.0.2.2 for Android Emulator, 10.199.234.103 for physical phone
  // Change this based on your device:
  // - Android Emulator: 10.0.2.2
  // - Physical Phone: 10.199.234.103 (your computer's current IP)
  // static const String baseUrl = 'http://10.0.2.2:5001/api';

  // Uncomment below if using physical phone instead
  static const String baseUrl = 'http://10.199.234.103:5001/api';

  /// Disease detection result model
  static Future<DiseaseDetectionResult?> detectDisease(File imageFile) async {
    try {
      var uri = Uri.parse('$baseUrl/detect-disease');
      var request = http.MultipartRequest('POST', uri);

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      var response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Disease detection request timed out');
        },
      );

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);

        return DiseaseDetectionResult.fromJson(jsonResponse);
      } else {
        final responseBody = await response.stream.bytesToString();
        final errorResponse = jsonDecode(responseBody);
        throw Exception(errorResponse['error'] ?? 'Failed to detect disease');
      }
    } on SocketException {
      throw Exception('Network error: Unable to connect to disease detection service');
    } on TimeoutException {
      throw TimeoutException('Request timed out. Please try again.');
    } catch (e) {
      throw Exception('Disease detection error: $e');
    }
  }

  /// Get disease information
  static Future<DiseaseInfo?> getDiseaseInfo(String diseaseName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/disease-info/$diseaseName'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return DiseaseInfo.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to fetch disease information');
      }
    } catch (e) {
      throw Exception('Error fetching disease info: $e');
    }
  }

  /// Set custom base URL (for testing with different servers)
  static void setBaseUrl(String newBaseUrl) {
    // Can be used to change base URL dynamically if needed
  }
}

class DiseaseDetectionResult {
  final bool success;
  final String disease;
  final double confidence;
  final String description;
  final String treatment;
  final String severity;
  final String prevention;
  final Map<String, dynamic> allPredictions;

  DiseaseDetectionResult({
    required this.success,
    required this.disease,
    required this.confidence,
    required this.description,
    required this.treatment,
    required this.severity,
    required this.prevention,
    required this.allPredictions,
  });

  factory DiseaseDetectionResult.fromJson(Map<String, dynamic> json) {
    return DiseaseDetectionResult(
      success: json['success'] ?? false,
      disease: json['disease'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      treatment: json['treatment'] ?? '',
      severity: json['severity'] ?? '',
      prevention: json['prevention'] ?? '',
      allPredictions: json['all_predictions'] ?? {},
    );
  }

  /// Check if the leaf is healthy
  bool get isHealthy => disease.toLowerCase() == 'healthy';

  /// Check if severity is high
  bool get isHighSeverity => severity.toLowerCase() == 'high';

  /// Get severity color for UI
  String getSeverityColor() {
    switch (severity.toLowerCase()) {
      case 'high':
        return '#FF6B6B'; // Red
      case 'medium':
        return '#FFA500'; // Orange
      case 'low':
        return '#FFD700'; // Yellow
      default:
        return '#4CAF50'; // Green (None/Healthy)
    }
  }
}

class DiseaseInfo {
  final String name;
  final String description;
  final String treatment;
  final String severity;
  final String prevention;

  DiseaseInfo({
    required this.name,
    required this.description,
    required this.treatment,
    required this.severity,
    required this.prevention,
  });

  factory DiseaseInfo.fromJson(Map<String, dynamic> json) {
    return DiseaseInfo(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      treatment: json['treatment'] ?? '',
      severity: json['severity'] ?? '',
      prevention: json['prevention'] ?? '',
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}

