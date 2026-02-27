import 'package:flutter/material.dart';

class HowPredictionWorksScreen extends StatelessWidget {
  const HowPredictionWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("How Yield Prediction Works"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(
            icon: Icons.analytics_rounded,
            title: "AI-Based Yield Estimation",
            subtitle: "How the system predicts harvest output",
            color: Colors.indigo,
          ),

          const SizedBox(height: 20),

          _stepCard(
            "1. Image Analysis",
            "Plant and pepper cone images are analyzed using deep learning models to extract visual features.",
            Icons.image_rounded,
          ),
          _stepCard(
            "2. Soil Data Integration",
            "Soil moisture values are collected via IoT sensor or manual input.",
            Icons.sensors_rounded,
          ),
          _stepCard(
            "3. Weather Fusion",
            "Temperature and rainfall data are integrated into the prediction.",
            Icons.cloud_rounded,
          ),
          _stepCard(
            "4. Yield Estimation",
            "All features are combined to estimate the final yield value.",
            Icons.trending_up_rounded,
          ),

          const SizedBox(height: 16),

          _infoBox(
            Icons.info_rounded,
            "Accurate input data leads to better yield prediction accuracy.",
            Colors.blue,
          ),
        ],
      ),
    );
  }
}
Widget _header({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _stepCard(String title, String desc, IconData icon) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(desc),
    ),
  );
}

Widget _infoBox(IconData icon, String text, Color color) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
