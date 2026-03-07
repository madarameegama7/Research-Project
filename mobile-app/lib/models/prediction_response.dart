class PredictionResponse {
  final double predictedYield;
  final List<String> insights;
  final TopFactors topFactors;

  PredictionResponse({
    required this.predictedYield,
    required this.insights,
    required this.topFactors,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      predictedYield: (json['predicted_yield'] ?? 0.0).toDouble(),
      insights: List<String>.from(json['insights'] ?? []),
      topFactors: TopFactors.fromJson(json['top_factors'] ?? {}),
    );
  }
}

class TopFactors {
  final double soilMoistureImpact;
  final double temperatureImpact;

  TopFactors({
    required this.soilMoistureImpact,
    required this.temperatureImpact,
  });

  factory TopFactors.fromJson(Map<String, dynamic> json) {
    return TopFactors(
      soilMoistureImpact: (json['soil_moisture_impact'] ?? 0.0).toDouble(),
      temperatureImpact: (json['temperature_impact'] ?? 0.0).toDouble(),
    );
  }
}
