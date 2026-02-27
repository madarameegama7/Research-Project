import 'package:flutter/material.dart';

class QualityResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  const QualityResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final samples = result["samples"] as Map<String, dynamic>? ?? {};
    final finalAvg = result["final"] as Map<String, dynamic>? ?? {};

    Widget block(String title, Map<String, dynamic> data) {
      String fmt(String k) {
        final v = data[k];
        if (v == null) return "-";
        if (v is num) return v.toStringAsFixed(2);
        return v.toString();
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text("Mold %: ${fmt("mold_pct")}"),
              Text("Abnormal texture %: ${fmt("abnormal_texture_pct")}"),
              Text("Extraneous matter %: ${fmt("extraneous_matter_pct")}"),
              Text("Adulterant seed %: ${fmt("adulterant_seed_pct")}"),
              Text("Healthy visual %: ${fmt("healthy_visual_pct")}"),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Quality Result")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (samples["bottom"] is Map<String, dynamic>) block("Bottom sample avg", Map<String, dynamic>.from(samples["bottom"])),
          if (samples["middle"] is Map<String, dynamic>) block("Middle sample avg", Map<String, dynamic>.from(samples["middle"])),
          if (samples["top"] is Map<String, dynamic>) block("Top sample avg", Map<String, dynamic>.from(samples["top"])),
          block("Final batch avg", Map<String, dynamic>.from(finalAvg)),
        ],
      ),
    );
  }
}