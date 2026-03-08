import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/yield_prediction_service.dart';
import '../models/prediction_response.dart';
import 'package:flutter/material.dart';

class YieldPredictionProvider extends ChangeNotifier {
  final YieldPredictionService _service = YieldPredictionService();

  double _predictedYield = 0;
  List<String> _insights = [];
  TopFactors? _topFactors;
  bool _isLoading = false;
  String? _error;
  bool _apiAvailable = false;

  // Getters
  double get predictedYield => _predictedYield;
  List<String> get insights => _insights;
  TopFactors? get topFactors => _topFactors;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get apiAvailable => _apiAvailable;

  /// Check if the prediction API is available
  Future<void> checkApiAvailability() async {
    _apiAvailable = await _service.healthCheck();
    notifyListeners();
  }

  /// Perform yield prediction
  Future<bool> performPrediction({
    required dynamic imageFile,
    required double soilMoisture,
    required double temperature,
    double? rainfall,
    String? plantAge,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.predictYield(
        imageFile: imageFile,
        soilMoisture: soilMoisture,
        temperature: temperature,
        rainfall: rainfall,
        plantAge: plantAge,
      );

      _predictedYield = response.predictedYield;
      _insights = response.insights;
      _topFactors = response.topFactors;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error messages
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset prediction data
  void resetPrediction() {
    _predictedYield = 0;
    _insights = [];
    _topFactors = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
