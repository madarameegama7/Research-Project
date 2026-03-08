import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../utils/yield_prediction/yield_prediction_si.dart';

class PredictionHistoryScreen extends StatelessWidget {
  final String language;

  const PredictionHistoryScreen({super.key, this.language = 'en'});

  @override
  Widget build(BuildContext context) {
    final isSi = language == 'si';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSi ? YieldPredictionSi.predictionHistory : "Prediction History",
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _historyCard(
            context,
            yieldValue: "15 kg",
            soil: "42%",
            temp: "29°C",
            date: "24th Dec 2025 • 10:32 AM",
          ),
          _historyCard(
            context,
            yieldValue: "30 kg",
            soil: "38%",
            temp: "27°C",
            date: "30th Dec 2025 • 4:18 PM",
          ),
          _historyCard(
            context,
            yieldValue: "4 kg",
            soil: "45%",
            temp: "31°C",
            date: "5th Jan 2026 • 9:05 AM",
          ),
        ],
      ),
    );
  }

  // ================= UI COMPONENT =================

  Widget _historyCard(
    BuildContext context, {
    required String yieldValue,
    required String soil,
    required String temp,
    required String date,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // future: open details screen
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const SizedBox(width: 14),

                // INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            yieldValue,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          _miniChip(
                            Icons.water_drop_rounded,
                            soil,
                            Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          _miniChip(
                            Icons.thermostat_rounded,
                            temp,
                            Colors.orange,
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
