import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class XAIInsightsScreen extends StatelessWidget {
  final File imageFile;
  final double soilMoisture;
  final double temperature;

  const XAIInsightsScreen({
    super.key,
    required this.imageFile,
    required this.soilMoisture,
    required this.temperature,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Insights"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _headerCard(),
          const SizedBox(height: 20),
          _imageInsightCard(),
          const SizedBox(height: 16),
          _factorCard(
            icon: Icons.water_drop_rounded,
            title: "Soil Moisture Impact",
            value: "${soilMoisture.round()}%",
            description:
                "Optimal soil moisture level contributed positively to nutrient uptake and fruit development.",
            color: Colors.blue,
            progress: soilMoisture / 100,
          ),
          const SizedBox(height: 16),
          _factorCard(
            icon: Icons.thermostat_rounded,
            title: "Temperature Impact",
            value: "${temperature.round()}°C",
            description:
                "Temperature is within the favorable range for pepper growth, supporting healthy cone formation.",
            color: Colors.orange,
            progress: temperature / 50,
          ),
          const SizedBox(height: 20),
          _finalExplanationCard(),
        ],
      ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          Icon(Icons.psychology_rounded, color: Colors.green, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "The AI model analyzed the plant image and environmental conditions to explain how each factor influenced the yield prediction.",
              style: TextStyle(fontSize: 14),
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
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color),
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
        ],
      ),
    );
  }

  Widget _finalExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.lightbulb_rounded, color: Colors.deepPurple),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Overall, the combination of healthy visual growth indicators, optimal soil moisture, and favorable temperature conditions led the model to predict a higher yield.",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
