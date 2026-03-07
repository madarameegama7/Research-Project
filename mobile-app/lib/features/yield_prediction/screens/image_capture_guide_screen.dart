import 'package:flutter/material.dart';

class ImageCaptureGuideScreen extends StatelessWidget {
  const ImageCaptureGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Image Capture Guide"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(
            icon: Icons.camera_alt_rounded,
            title: "Capture Clear Images",
            subtitle: "Improve prediction accuracy",
            color: Colors.teal,
          ),

          const SizedBox(height: 20),

          _stepCard(
            "Lighting",
            "Use natural daylight. Avoid shadows and artificial lighting.",
            Icons.wb_sunny_rounded,
          ),
          _stepCard(
            "Distance",
            "Hold the camera 20–30 cm above the plant.",
            Icons.photo_size_select_large_rounded,
          ),
          _stepCard(
            "Angles",
            "Capture 4–5 images from different angles.",
            Icons.flip_camera_android_rounded,
          ),
          _stepCard(
            "Focus",
            "Ensure pepper cones and leaves are clearly visible.",
            Icons.center_focus_strong_rounded,
          ),

          const SizedBox(height: 16),

          _infoBox(
            Icons.warning_rounded,
            "Blurry or dark images can reduce prediction accuracy.",
            Colors.orange,
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
