import 'dart:io';
import 'package:flutter/material.dart';
import '../services/pepper_inference_api.dart';
import 'quality_result_screen.dart';

class ProcessingScreen2 extends StatefulWidget {
  final Map<String, File?> images;
  const ProcessingScreen2({super.key, required this.images});

  @override
  State<ProcessingScreen2> createState() => _ProcessingScreen2State();
}

class _ProcessingScreen2State extends State<ProcessingScreen2> {
  int sent = 0;
  int total = 1;
  String status = "Uploading images...";

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      // IMPORTANT: set fastApiBaseUrl based on emulator vs phone
      // Emulator:
      const fastApiBaseUrl = "http://10.89.148.24:8000";
      // Phone: const fastApiBaseUrl = "http://192.168.x.x:8000";

      final api = PepperInferenceApi(fastApiBaseUrl);

      setState(() => status = "Uploading and analyzing...");

      final result = await api.inferQuality(
        images: widget.images,
        textureFirst: true,
        onSendProgress: (s, t) {
          setState(() {
            sent = s;
            total = t == 0 ? 1 : t;
          });
        },
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QualityResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Failed"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = sent / total;

    return Scaffold(
      appBar: AppBar(title: const Text("Processing")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: progress.isFinite ? progress : 0),
            const SizedBox(height: 8),
            Text("${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%"),
            const SizedBox(height: 24),
            const Text("Please keep the app open."),
          ],
        ),
      ),
    );
  }
}