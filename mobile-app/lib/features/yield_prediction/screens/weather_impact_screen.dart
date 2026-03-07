import 'package:flutter/material.dart';

class WeatherImpactScreen extends StatelessWidget {
  const WeatherImpactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Weather Impact"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(
            icon: Icons.cloud_rounded,
            title: "Weather Influence on Yield",
            subtitle: "How climate affects pepper production",
            color: Colors.orange,
          ),

          const SizedBox(height: 20),

          _infoCard(
            Icons.thermostat_rounded,
            "Temperature",
            "Optimal range: 20°C – 30°C\nHigh temperatures may reduce flowering.",
          ),
          _infoCard(
            Icons.water_drop_rounded,
            "Rainfall",
            "Moderate rainfall supports growth.\nExcess rain may cause root diseases.",
          ),
          _infoCard(
            Icons.wb_sunny_rounded,
            "Sunlight",
            "Adequate sunlight improves photosynthesis and yield.",
          ),

          const SizedBox(height: 16),

          _tipBox(
            Icons.info_rounded,
            "Current weather conditions are suitable for pepper cultivation.",
            Colors.green,
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

Widget _infoCard(IconData icon, String title, String desc) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(desc),
    ),
  );
}

Widget _stepCard(IconData icon, String title, String desc) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ListTile(
      leading: Icon(icon, color: Colors.purple),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(desc),
    ),
  );
}

Widget _tipBox(IconData icon, String text, Color color) {
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
