import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'xai_insights_screen.dart';
import '../../../utils/yield_prediction/yield_prediction_si.dart';
import '../../../providers/yield_prediction_provider.dart';
import '../../../models/prediction_response.dart';

class PredictionResultScreen extends StatefulWidget {
  final double predictedYield;
  final double soilMoisture;
  final double temperature;
  final dynamic imageFile; // XFile or File
  final String language;

  const PredictionResultScreen({
    super.key,
    required this.predictedYield,
    required this.soilMoisture,
    required this.temperature,
    required this.imageFile,
    this.language = 'en',
  });

  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen> {
  @override
  Widget build(BuildContext context) {
    final isSi = widget.language == 'si';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSi ? YieldPredictionSi.predictionResult : "Prediction Result",
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildImageWidget(),
          ),

          const SizedBox(height: 24),

          // YIELD HERO
          _buildYieldHero(isSi),

          const SizedBox(height: 24),

          // SOIL
          _infoTile(
            Icons.water_drop_rounded,
            isSi ? YieldPredictionSi.soilMoisture : "Soil Moisture",
            "${widget.soilMoisture.round()}%",
            Colors.blue,
          ),

          // TEMPERATURE
          _infoTile(
            Icons.thermostat_rounded,
            isSi ? YieldPredictionSi.temperature : "Temperature",
            "${widget.temperature.round()}°C",
            Colors.orange,
          ),

          const SizedBox(height: 24),

          // XAI BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.psychology_rounded),
              label: Text(
                isSi ? YieldPredictionSi.viewAiInsights : "View AI Insights",
              ),
              onPressed: () {
                final provider = context.read<YieldPredictionProvider>();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => XAIInsightsScreen(
                      imageFile: widget.imageFile,
                      soilMoisture: widget.soilMoisture,
                      temperature: widget.temperature,
                      insights: provider.insights,
                      topFactors: provider.topFactors,
                      language: widget.language,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _buildImageWidget() {
    if (widget.imageFile is XFile) {
      return FutureBuilder<Uint8List>(
        future: (widget.imageFile as XFile).readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            );
          } else if (snapshot.hasError) {
            return Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(child: Text('Error loading image')),
            );
          }
          return Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    } else {
      // Handle dart:io.File
      return Image.file(
        widget.imageFile,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildYieldHero(bool isSi) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSi ? YieldPredictionSi.estimatedYield : "Predicted Yield",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            "${widget.predictedYield} ${isSi ? YieldPredictionSi.kilogramPerPlant : "kg"}",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
