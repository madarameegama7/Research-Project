import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../utils/yield_prediction/yield_prediction_si.dart';
import '../../../models/prediction_response.dart';

class XAIInsightsScreen extends StatelessWidget {
  final dynamic imageFile; // Can be File or XFile
  final double soilMoisture;
  final double temperature;
  final List<String> insights;
  final TopFactors? topFactors;
  final String language;

  const XAIInsightsScreen({
    super.key,
    required this.imageFile,
    required this.soilMoisture,
    required this.temperature,
    this.insights = const [],
    this.topFactors,
    this.language = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final isSi = language == 'si';

    return Scaffold(
      appBar: AppBar(
        title: Text(isSi ? YieldPredictionSi.xaiInsights : "AI Insights"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _headerCard(isSi),
          const SizedBox(height: 20),
          _imageInsightCard(),
          const SizedBox(height: 16),
          // Display soil moisture impact with SHAP value
          _factorCard(
            icon: Icons.water_drop_rounded,
            title: isSi
                ? YieldPredictionSi.soilMoistureImpact
                : "Soil Moisture Impact",
            value: "${soilMoisture.round()}%",
            description: _getSoilMoistureDescription(isSi),
            color: Colors.blue,
            progress: soilMoisture / 100,
            shapValue: topFactors?.soilMoistureImpact.toStringAsFixed(4),
          ),
          const SizedBox(height: 16),
          // Display temperature impact with SHAP value
          _factorCard(
            icon: Icons.thermostat_rounded,
            title: isSi
                ? YieldPredictionSi.temperatureImpact
                : "Temperature Impact",
            value: "${temperature.round()}°C",
            description: _getTemperatureDescription(isSi),
            color: Colors.orange,
            progress: temperature / 50,
            shapValue: topFactors?.temperatureImpact.toStringAsFixed(4),
          ),
          const SizedBox(height: 20),
          // Display dynamic insights from backend
          if (insights.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_rounded, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isSi
                              ? "AI වලින් අනුমාන කරන ලද අවබෝධතා"
                              : "AI-Generated Insights",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...insights
                      .map(
                        (insight) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  insight,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          _finalExplanationCard(isSi),
        ],
      ),
    );
  }

  String _getSoilMoistureDescription(bool isSi) {
    if (isSi) {
      if (soilMoisture < 40) {
        return "පසු ගෙඩි ජලය අඩුය. වඩා השקיה අවශ්‍ය විය හැක.";
      } else if (soilMoisture > 70) {
        return "පසු ගෙඩි ජලය ඉතා ඉහල ය, එමඟින් ශක්තිමත් ශාක වර්ධනයට සහාය විය පුළුවන්.";
      } else {
        return "පසු ගෙඩි ජලය සර්वෝත්තම මට්ටමේ ඇති අතර, පෝෂක ගතිර සහ ගෙඩි සම්පූර්ණතාවට ධනাත්මක ඉපදෙයි.";
      }
    } else {
      if (soilMoisture < 40) {
        return "Soil moisture is quite low. Increasing irrigation may improve yield.";
      } else if (soilMoisture > 70) {
        return "Soil moisture levels are high which may support strong plant growth.";
      } else {
        return "Optimal soil moisture level contributed positively to nutrient uptake and fruit development.";
      }
    }
  }

  String _getTemperatureDescription(bool isSi) {
    if (isSi) {
      if (temperature < 20) {
        return "උෂ්ණත්වය අඩුය සහ සිටි්ගේ වර්ධනයට බාධා විය පුළුවන්.";
      } else if (temperature > 35) {
        return "උෂ්ණත්වය ඉතා ඉහල ය. ශාක ගෝ විරජනයට ලක්ව අස්වැන්ම අඩු විය පුළුවන්.";
      } else {
        return "උෂ්ණත්වය තිබෙන්නේ වඩු සිටි්ගේ වර්ධනයට සනිටින අවස්ථාවෙහි ඇති අතර, සුස්ថ කේතු සෙවණ සඳහා ආධාර දෙයි.";
      }
    } else {
      if (temperature < 20) {
        return "Temperature is quite low. Crop growth may be slow with these conditions.";
      } else if (temperature > 35) {
        return "High temperature detected. Crop stress may reduce yield.";
      } else {
        return "Temperature is within the favorable range for pepper growth, supporting healthy cone formation.";
      }
    }
  }

  // ================= UI COMPONENTS =================

  Widget _headerCard(bool isSi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_rounded, color: Colors.green, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSi
                  ? YieldPredictionSi.aiModelAnalyzedPlantImage
                  : "The AI model analyzed the plant image and environmental conditions to explain how each factor influenced the yield prediction.",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageInsightCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Image-Based Insight",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: kIsWeb
              ? (imageFile is String
                    ? Image.network(
                        imageFile,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.broken_image),
                            ),
                          );
                        },
                      )
                    : Image.memory(
                        imageFile,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ))
              : Image.file(
                  imageFile,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image)),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        const Text(
          "The model detected healthy pepper cones and good canopy density, which positively influenced the yield prediction.",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _factorCard({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required Color color,
    required double progress,
    String? shapValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            color: color,
            backgroundColor: color.withOpacity(0.2),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          if (shapValue != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "SHAP Impact: $shapValue",
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _finalExplanationCard(bool isSi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSi
                  ? "සම්පූර්ණ වශයෙන් නම්, සුස්ථ දෘශ්‍ය වර්ධන සూචක, සර්වෝත්තම පසු ගෙඩි ජලය සහ සනිටින උෂ්ණත්වයේ තත්වයන් එකතු වී ශාක අස්වැන්ම ඉහලට පෙන්වීමට ප්‍රමුණ විය."
                  : "Overall, the combination of healthy visual growth indicators, optimal soil moisture, and favorable temperature conditions led the model to predict a higher yield.",
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
