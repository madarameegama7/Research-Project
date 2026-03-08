import 'package:flutter/material.dart';
import '../screens/prediction_result_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/yield_prediction_provider.dart';
import '../../../utils/yield_prediction/yield_prediction_si.dart';

class NewPredictionScreen extends StatefulWidget {
  final String language;

  const NewPredictionScreen({super.key, this.language = 'en'});

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
    final isSi = widget.language == 'si';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          isSi
              ? YieldPredictionSi.newHarvestPrediction
              : "New Harvest Prediction",
        ),
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
              title: isSi
                  ? YieldPredictionSi.step1UploadPlantImage
                  : "Step 1: Upload Plant Image",
              subtitle: isSi
                  ? YieldPredictionSi.captureOrSelectPepperPlantImage
                  : "Capture or select pepper plant image",
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.upload_rounded,
                              size: 40,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isSi
                                  ? YieldPredictionSi.tapToUploadImage
                                  : "Tap to upload image",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            ),

            _stepHeader(
              icon: Icons.sensors_rounded,
              title: isSi
                  ? YieldPredictionSi.step2SoilConditions
                  : "Step 2: Soil Conditions",
              subtitle: isSi
                  ? YieldPredictionSi.criticalForYieldEstimation
                  : "Critical for yield estimation",
              color: Colors.blue,
            ),

            const SizedBox(height: 8),

            _iotToggle(isSi),

            const SizedBox(height: 12),

            _sliderField(
              label: isSi
                  ? YieldPredictionSi.soilMoisture
                  : "Soil Moisture (%)",
              value: soilMoisture,
              max: 100,
              onChanged: (v) => setState(() => soilMoisture = v),
            ),
            _infoText(
              isSi
                  ? YieldPredictionSi
                        .optimalSoilMoistureImprovesNutrientAbsorption
                  : "Optimal soil moisture improves nutrient absorption and yield accuracy.",
            ),

            const SizedBox(height: 24),
            _stepHeader(
              icon: Icons.thermostat_rounded,
              title: isSi
                  ? YieldPredictionSi.step3Temperature
                  : "Step 3: Temperature",
              subtitle: isSi
                  ? YieldPredictionSi.environmentalTemperatureInCelsius
                  : "Environmental temperature in °C",
              color: Colors.orange,
            ),

            const SizedBox(height: 12),

            _sliderField(
              label: isSi ? YieldPredictionSi.temperature : "Temperature (°C)",
              value: temperature,
              max: 50,
              onChanged: (v) => setState(() => temperature = v),
            ),

            _infoText(
              isSi
                  ? YieldPredictionSi.temperatureAffectsGrowthRate
                  : "Temperature affects growth rate and fruit development.",
            ),

            const SizedBox(height: 28),

            _confidencePreview(isSi),

            const SizedBox(height: 20),

            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.analytics_rounded),
                label: Text(
                  isSi ? YieldPredictionSi.predictYield : "Predict Yield",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  if (selectedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isSi
                              ? YieldPredictionSi.pleaseUploadAPlantImage
                              : "Please upload a plant image",
                        ),
                      ),
                    );
                    return;
                  }

                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  // Perform prediction
                  final provider = context.read<YieldPredictionProvider>();
                  final success = await provider.performPrediction(
                    imageFile: selectedImage!,
                    soilMoisture: soilMoisture,
                    temperature: temperature,
                    rainfall: null,
                    plantAge: plantAge,
                  );

                  Navigator.pop(context); // Close loading dialog

                  if (success) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PredictionResultScreen(
                          predictedYield: provider.predictedYield,
                          soilMoisture: soilMoisture,
                          temperature: temperature,
                          imageFile: selectedImage!,
                          language: widget.language,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          provider.error ??
                              (isSi
                                  ? YieldPredictionSi.predictionFailed
                                  : "Prediction failed"),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField(bool isSi) {
    return DropdownButtonFormField<String>(
      value: plantAge,
      items: [
        DropdownMenuItem(
          value: "3–5 months",
          child: Text(
            isSi ? YieldPredictionSi.threeToFiveMonths : "3–5 months",
          ),
        ),
        DropdownMenuItem(
          value: "6–8 months",
          child: Text(isSi ? YieldPredictionSi.sixToEightMonths : "6–8 months"),
        ),
        DropdownMenuItem(
          value: "9+ months",
          child: Text(isSi ? YieldPredictionSi.ninePlusMonths : "9+ months"),
        ),
      ],
      onChanged: (v) => setState(() => plantAge = v!),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        labelText: isSi ? YieldPredictionSi.plantAgeLabel : "Plant Age",
        helperText: isSi
            ? YieldPredictionSi.plantAgeHelper
            : "Older plants usually produce higher yields",
      ),
    );
  }

  Widget _iotToggle(bool isSi) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          isSi ? YieldPredictionSi.useIoTSensorData : "Use IoT Sensor Data",
          style: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget _confidencePreview(bool isSi) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_rounded, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSi
                  ? YieldPredictionSi.basedOnProvidedInputs
                  : "Based on provided inputs, prediction confidence is expected to be high.",
              style: const TextStyle(fontSize: 13),
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
