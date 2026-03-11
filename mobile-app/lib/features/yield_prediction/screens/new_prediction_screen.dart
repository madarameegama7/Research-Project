import 'package:flutter/material.dart';
import 'dart:async';
import '../screens/prediction_result_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/yield_prediction_provider.dart';
import '../../../utils/yield_prediction/yield_prediction_si.dart';
import '../../disease_detection/services/location_service.dart';
import '../../../services/weather_service.dart';
import '../../../services/iot_ble_service.dart';

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
  String? locationName;
  bool isFetchingWeather = false;
  
  List<File?> selectedImages = [null, null, null, null];
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();
  final IotBleService _iotService = IotBleService();
  
  String plantAge = "6–8 months";
  bool useIoT = false;
  String iotStatus = "Disconnected";
  StreamSubscription? _iotMoistureSubscription;
  StreamSubscription? _iotStatusSubscription;

  final List<String> _imageLabels = [
    "Front View",
    "Side View 1",
    "Side View 2",
    "Top/Close-up"
  ];

  final List<String> _imageLabelsSi = [
    "ඉදිරිපස පෙනුම",
    "පැති පෙනුම 1",
    "පැති පෙනුම 2",
    "ඉහළ/සමීප පෙනුම"
  ];

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _setupIotListeners();
  }

  @override
  void dispose() {
    _iotMoistureSubscription?.cancel();
    _iotStatusSubscription?.cancel();
    _iotService.dispose();
    super.dispose();
  }

  void _setupIotListeners() {
    _iotMoistureSubscription = _iotService.moistureStream.listen((value) {
      if (useIoT) {
        setState(() {
          soilMoisture = value;
        });
      }
    });

    _iotStatusSubscription = _iotService.connectionStatusStream.listen((status) {
      setState(() {
        iotStatus = status;
      });
    });
  }

  Future<void> _fetchWeather() async {
    setState(() {
      isFetchingWeather = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final weatherData = await WeatherService.fetchWeatherData(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        setState(() {
          temperature = weatherData.temperature;
          locationName = weatherData.location;
          isFetchingWeather = false;
        });
      } else {
        setState(() => isFetchingWeather = false);
      }
    } catch (e) {
      print('Error fetching weather: $e');
      setState(() => isFetchingWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSi = widget.language == 'si';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          isSi
              ? YieldPredictionSi.newHarvestPrediction
              : "New Harvest Prediction",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            _buildCaptureGuide(isSi),
            const SizedBox(height: 24),
            _stepHeader(
              icon: Icons.camera_alt_rounded,
              title: isSi
                  ? YieldPredictionSi.step1UploadPlantImage
                  : "Step 1: Plant Images (Up to 4)",
              subtitle: isSi
                  ? "වැඩි නිවැරදිභාවයක් සඳහා විවිධ කෝණවලින් ඡායාරූප ලබා ගන්න"
                  : "Capture images from different angles for better accuracy",
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _buildImageGrid(isSi),
            const SizedBox(height: 32),
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
            const SizedBox(height: 16),
            _iotToggle(isSi),
            const SizedBox(height: 12),
            _sliderField(
              label: isSi
                  ? YieldPredictionSi.soilMoisture
                  : "Soil Moisture (%)",
              value: soilMoisture,
              max: 100,
              color: Colors.blue,
              // Disable manual slider when IoT is active
              onChanged: useIoT ? null : (v) => setState(() => soilMoisture = v),
            ),
            if (useIoT) 
              _infoText(
                "Connected to Sensor: $iotStatus", 
                isError: iotStatus == "Connection failed" || iotStatus == "Device not found"
              ),
            _infoText(
              isSi
                  ? YieldPredictionSi.optimalSoilMoistureImprovesNutrientAbsorption
                  : "Optimal soil moisture improves nutrient absorption and yield accuracy.",
            ),
            const SizedBox(height: 32),
            _stepHeader(
              icon: Icons.thermostat_rounded,
              title: isSi
                  ? YieldPredictionSi.step3Temperature
                  : "Step 3: Temperature",
              subtitle: isSi
                  ? YieldPredictionSi.environmentalTemperatureInCelsius
                  : "Automatically fetched for your location",
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildWeatherCard(isSi),
            _infoText(
              isSi
                  ? YieldPredictionSi.temperatureAffectsGrowthRate
                  : "Temperature is automatically fetched to ensure accuracy for your current location.",
            ),
            const SizedBox(height: 32),
            _confidencePreview(isSi),
            const SizedBox(height: 32),
            _buildPredictButton(isSi),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureGuide(bool isSi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSi ? "ඉඟිය: තවත් රූප, වඩා හොඳ නිරවද්‍යතාවයක්" : "Pro Tip: More Images, Better Accuracy",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  isSi 
                    ? "නිවැරදි අස්වනු අනාවැකි සඳහා එකම පැළයේ රූප 4 ක් දක්වා ලබා ගන්න."
                    : "Upload up to 4 images of the same plant to get the most accurate yield prediction.",
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(bool isSi) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final image = selectedImages[index];
        final label = isSi ? _imageLabelsSi[index] : _imageLabels[index];
        
        return GestureDetector(
          onTap: () => _pickImage(index),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: image != null ? Colors.green.shade300 : Colors.grey.shade300,
                width: image != null ? 2 : 1,
              ),
              image: image != null
                  ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
                  : null,
            ),
            child: Stack(
              children: [
                if (image == null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded, color: Colors.grey[400], size: 32),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                if (image != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => selectedImages[index] = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPredictButton(bool isSi) {
    final validImages = selectedImages.where((img) => img != null).toList();
    final bool canPredict = validImages.isNotEmpty;

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canPredict ? Colors.green : Colors.grey[300],
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: canPredict ? () => _handlePrediction(isSi) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_rounded),
            const SizedBox(width: 12),
            Text(
              isSi ? YieldPredictionSi.predictYield : "Predict Yield",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePrediction(bool isSi) async {
    final validImages = selectedImages.whereType<File>().toList();
    
    // Show loading dialog with premium feel
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                      strokeWidth: 5,
                      backgroundColor: Colors.green.withOpacity(0.1),
                    ),
                  ),
                  Icon(Icons.analytics_rounded, color: Colors.green.shade800, size: 32),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                isSi ? "අනාවැකිය සකසමින්..." : "Processing Prediction",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSi ? "කරුණාකර මොහොතක් රැඳී සිටින්න" : "Analyzing images and soil data...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Perform prediction
    final provider = context.read<YieldPredictionProvider>();
    final success = await provider.performPrediction(
      imageFiles: validImages,
      soilMoisture: soilMoisture,
      temperature: temperature,
      rainfall: null,
      plantAge: plantAge,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PredictionResultScreen(
            predictedYieldKgPerPlant: provider.predictedYieldKgPerPlant,
            confidencePercent: provider.confidencePercent,
            cropCondition: provider.cropCondition,
            timestamp: provider.timestamp,
            soilMoisture: soilMoisture,
            temperature: temperature,
            imageFile: validImages.first, // Preview first image
            language: widget.language,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? (isSi ? YieldPredictionSi.predictionFailed : "Prediction failed"),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= UI COMPONENTS =================

  Widget _buildWeatherCard(bool isSi) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSi ? "වත්මන් උෂ්ණත්වය" : "Current Temperature",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        locationName ?? (isSi ? "ස්ථානය සොයමින්..." : "Locating..."),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: isFetchingWeather ? null : _fetchWeather,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white.withOpacity(0.8),
                ),
                tooltip: "Refresh Weather",
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isFetchingWeather)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              else ...[
                Text(
                  temperature.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    "°C",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dropdownField(bool isSi) {
    return DropdownButtonFormField<String>(
      value: plantAge,
      items: [
        DropdownMenuItem(
          value: "3–5 months",
          child: Text(isSi ? YieldPredictionSi.threeToFiveMonths : "3–5 months"),
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
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        labelText: isSi ? YieldPredictionSi.plantAgeLabel : "Plant Age",
      ),
    );
  }

  Widget _iotToggle(bool isSi) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_rounded, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Text(
                isSi ? YieldPredictionSi.useIoTSensorData : "Use IoT Sensor Data",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          Switch.adaptive(
            value: useIoT,
            activeColor: Colors.blue,
            onChanged: (v) {
              setState(() {
                useIoT = v;
                if (useIoT) {
                  _iotService.startConnecting();
                } else {
                  _iotService.disconnect();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _sliderField({
    required String label,
    required double value,
    required double max,
    required Color color,
    void Function(double)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${value.round()}${label.contains('%') ? '%' : '°C'}",
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color.withOpacity(0.8),
            inactiveTrackColor: color.withOpacity(0.1),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            max: max,
            divisions: max.toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _infoText(String text, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 14, color: isError ? Colors.red : Colors.grey[400]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 11, color: isError ? Colors.red : Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidencePreview(bool isSi) {
    final validImages = selectedImages.where((img) => img != null).length;
    final color = validImages >= 3 ? Colors.green : (validImages >= 1 ? Colors.orange : Colors.grey);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSi ? "අනාවැකි විශ්වාසය" : "Prediction Confidence",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  validImages == 0 
                      ? (isSi ? "ඡායාරූප අවශ්‍යයි" : "Upload images to see impact")
                      : (validImages >= 3 
                          ? (isSi ? "ඉතා ඉහළයි (හොඳම ප්‍රතිඵල)" : "High (Optimal inputs)")
                          : (isSi ? "මධ්‍යම මට්ටමේ" : "Medium (More images recommended)")),
                  style: TextStyle(fontSize: 12, color: color[700], fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImages[index] = File(image.path);
      });
    }
  }
}
