import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'xai_insights_screen.dart';

class PredictionResultScreen extends StatelessWidget {
  final double predictedYield;
  final double soilMoisture;
  final double temperature;
  final File imageFile;

  const PredictionResultScreen({
    super.key,
    required this.predictedYield,
    required this.soilMoisture,
    required this.temperature,
    required this.imageFile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Prediction Result")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: kIsWeb
                ? Image.network(
                    imageFile.path,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    imageFile,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),

          const SizedBox(height: 24),

          // YIELD HERO
          _yieldHero(),

          const SizedBox(height: 24),

          // SOIL
          _infoTile(
            Icons.water_drop_rounded,
            "Soil Moisture",
            "${soilMoisture.round()}%",
            Colors.blue,
          ),

          // TEMPERATURE
          _infoTile(
            Icons.thermostat_rounded,
            "Temperature",
            "${temperature.round()}°C",
            Colors.orange,
          ),

          const SizedBox(height: 24),

          // XAI BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.psychology_rounded),
              label: const Text("View AI Insights"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => XAIInsightsScreen(
                      imageFile: imageFile,
                      soilMoisture: soilMoisture,
                      temperature: temperature,
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

  Widget _yieldHero() {
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
          const Text(
            "Predicted Yield",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            "${predictedYield.round()}3 kg",
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

  Widget _infoTile(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
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
