import 'package:flutter/material.dart';
import '../screens/prediction_result_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class NewPredictionScreen extends StatefulWidget {
  const NewPredictionScreen({super.key});

  @override
  State<NewPredictionScreen> createState() => _NewPredictionScreenState();
}

class _NewPredictionScreenState extends State<NewPredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  double soilMoisture = 40;
 double temperature = 28;
 File? selectedImage;
final ImagePicker _picker = ImagePicker();
  String plantAge = "6–8 months";
  bool useIoT = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("New Harvest Prediction"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _stepHeader(
  icon: Icons.camera_alt_rounded,
  title: "Step 1: Upload Plant Image",
  subtitle: "Capture or select pepper plant image",
  color: Colors.green,
),

const SizedBox(height: 12),

GestureDetector(
  onTap: _pickImage,
  child: Container(
    height: 180,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade400),
      image: selectedImage != null
          ? DecorationImage(
              image: FileImage(selectedImage!),
              fit: BoxFit.cover,
            )
          : null,
    ),
    child: selectedImage == null
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_rounded, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text("Tap to upload image",
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : null,
  ),
),

            _stepHeader(
              icon: Icons.sensors_rounded,
              title: "Step 2: Soil Conditions",
              subtitle: "Critical for yield estimation",
              color: Colors.blue,
            ),

            const SizedBox(height: 8),

            _iotToggle(),

            const SizedBox(height: 12),

            _sliderField(
              label: "Soil Moisture (%)",
              value: soilMoisture,
              max: 100,
              onChanged: (v) => setState(() => soilMoisture = v),
            ),
            _infoText(
              "Optimal soil moisture improves nutrient absorption and yield accuracy.",
            ),

            const SizedBox(height: 24),
_stepHeader(
  icon: Icons.thermostat_rounded,
  title: "Step 3: Temperature",
  subtitle: "Environmental temperature in °C",
  color: Colors.orange,
),

const SizedBox(height: 12),

_sliderField(
  label: "Temperature (°C)",
  value: temperature,
  max: 50,
  onChanged: (v) => setState(() => temperature = v),
),

_infoText(
  "Temperature affects growth rate and fruit development.",
),


            const SizedBox(height: 28),

            _confidencePreview(),

            const SizedBox(height: 20),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.analytics_rounded),
                label: const Text(
                  "Predict Yield",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
               onPressed: () {
  if (selectedImage == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please upload a plant image")),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PredictionResultScreen(
        predictedYield: 0, // placeholder until backend is connected
        soilMoisture: soilMoisture,
        temperature: temperature,
        imageFile: selectedImage!,
      ),
    ),
  );
},

              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _stepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField() {
    return DropdownButtonFormField<String>(
      value: plantAge,
      items: const [
        DropdownMenuItem(value: "3–5 months", child: Text("3–5 months")),
        DropdownMenuItem(value: "6–8 months", child: Text("6–8 months")),
        DropdownMenuItem(value: "9+ months", child: Text("9+ months")),
      ],
      onChanged: (v) => setState(() => plantAge = v!),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        labelText: "Plant Age",
        helperText: "Older plants usually produce higher yields",
      ),
    );
  }

  Widget _iotToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Use IoT Sensor Data",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Switch(
          value: useIoT,
          activeColor: Colors.green,
          onChanged: (v) => setState(() => useIoT = v),
        ),
      ],
    );
  }

  Widget _sliderField({
    required String label,
    required double value,
    required double max,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label : ${value.round()}",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Slider(
          value: value,
          max: max,
          divisions: max.toInt(),
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _infoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget _confidencePreview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: const [
          Icon(Icons.insights_rounded, color: Colors.green),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Based on provided inputs, prediction confidence is expected to be high.",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _pickImage() async {
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    setState(() {
      selectedImage = File(image.path);
    });
  }
}
}



