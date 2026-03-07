import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import '../screens/new_prediction_screen.dart';
import '../screens/prediction_history_screen.dart';
import '../screens/how_prediction_works_screen.dart';
import '../screens/image_capture_guide_screen.dart';
import '../screens/iot_sensor_setup_screen.dart';
import '../screens/weather_impact_screen.dart';
import '../screens/yield_tips_screen.dart';



class HarvestPredictionDashboard extends StatefulWidget {
  const HarvestPredictionDashboard({super.key});

  @override
  State<HarvestPredictionDashboard> createState() =>
      _HarvestPredictionDashboardState();
}

class _HarvestPredictionDashboardState extends State<HarvestPredictionDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    const primary = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        title: const Text(
          "Harvest Prediction",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PredictionHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(responsive, primary),
              const SizedBox(height: 16),
              _buildStatusBanner(responsive),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
                child: _buildSummaryGrid(),
              ),
              const SizedBox(height: 28),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
                child: Text(
                  "What would you like to do?",
                  style: TextStyle(
                    fontSize: responsive.headingFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildActions(responsive),
              const SizedBox(height: 28),
              _buildResources(responsive),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(Responsive responsive, Color primary) {
    return Container(
      width: double.infinity,
      padding: responsive.padding(
        mobile: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        tablet: const EdgeInsets.fromLTRB(32, 40, 32, 40),
        desktop: const EdgeInsets.fromLTRB(40, 48, 40, 48),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primary.withOpacity(0.85)],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(
            responsive.value(mobile: 32, tablet: 36, desktop: 40),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.analytics_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "AI-Based Yield Forecast",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: responsive.bodyFontSize,
                ),
              ),
              Text(
                "Predict Your Harvest",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: responsive.headingFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= STATUS =================
  Widget _buildStatusBanner(Responsive responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Crop condition looks healthy. No immediate action required.",
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _buildSummaryGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryCard("Predictions", "5", Icons.analytics_rounded, Colors.blue),
        _summaryCard("Avg Yield", "35 kg", Icons.trending_up_rounded, Colors.green),
        _summaryCard("Best Yield", "41 kg", Icons.star_rounded, Colors.amber),
        _summaryCard("Last Run", "Jan 6th", Icons.schedule_rounded, Colors.purple),
      ],
    );
  }

  Widget _summaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ================= ACTIONS =================
  Widget _buildActions(Responsive responsive) {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.95,
          children: [
            _actionCard(
              "New\nPrediction",
              "Estimate yield",
              Icons.add_chart_rounded,
              true,
              LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewPredictionScreen()),
              ),
            ),
            _actionCard(
              "Past\nPredictions",
              "View history",
              Icons.history_rounded,
              false,
              LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PredictionHistoryScreen()),
              ),
            ),
            _actionCard(
  "Weather\nImpact",
  "View factors",
  Icons.cloud_rounded,
  false,
  LinearGradient(
    colors: [Colors.orange.shade400, Colors.orange.shade600],
  ),
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WeatherImpactScreen(),
      ),
    );
  },
),

_actionCard(
  "Yield\nTips",
  "Improve output",
  Icons.lightbulb_outline_rounded,
  false,
  LinearGradient(
    colors: [Colors.purple.shade400, Colors.purple.shade600],
  ),
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const YieldTipsScreen(),
      ),
    );
  },
),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
    String title,
    String subtitle,
    IconData icon,
    bool badge,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            if (badge)
              Positioned(
                top: 12,
                right: 12,
                child: _badge("Recommended"),
              ),
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(icon, size: 90, color: Colors.white24),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: Colors.white),
                  const Spacer(),
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= RESOURCES =================
  Widget _buildResources(Responsive responsive) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Resources & Support",
            style: TextStyle(
              fontSize: responsive.headingFontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
      _resourceTile(
  "How Yield Prediction Works",
  "Understand the AI model",
  Icons.school_rounded,
  Colors.indigo,
  "Recommended",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HowPredictionWorksScreen(),
      ),
    );
  },
),

_resourceTile(
  "Image Capture Guide",
  "Improve image quality",
  Icons.camera_alt_rounded,
  Colors.teal,
  "Improves Accuracy",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ImageCaptureGuideScreen(),
      ),
    );
  },
),

_resourceTile(
  "IoT Sensor Setup",
  "Connect soil sensor",
  Icons.sensors_rounded,
  Colors.deepPurple,
  "Required",
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IotSensorSetupScreen(),
      ),
    );
  },
),

        ],
      ),
    );
  }

  Widget _resourceTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String badge,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(child: Text(title)),
            _badge(badge, color: color),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _badge(String text, {Color color = Colors.green}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // ================= DIALOGS =================
  void _showHowPredictionWorks(BuildContext context) {
    _infoDialog(
      context,
      "How Yield Prediction Works",
      "Images of pepper plants are analyzed using deep learning models.\n\nSoil moisture and weather data are combined with visual features to estimate final yield.",
    );
  }

  void _showImageCaptureGuide(BuildContext context) {
    _infoDialog(
      context,
      "Image Capture Guide",
      "• Use natural light\n• Avoid shadows\n• Capture from multiple angles\n• Keep camera 20–30cm away",
    );
  }

  void _showIoTGuide(BuildContext context) {
    _infoDialog(
      context,
      "IoT Sensor Setup",
      "Place soil moisture sensor firmly in soil and allow readings to stabilize before prediction.",
    );
  }

  void _showWeatherDialog(BuildContext context) {
    _infoDialog(
      context,
      "Weather Impact",
      "Current weather conditions are favorable for pepper cultivation.",
    );
  }

  void _showYieldTips(BuildContext context) {
    _infoDialog(
      context,
      "Yield Improvement Tips",
      "• Maintain optimal irrigation\n• Avoid waterlogging\n• Monitor soil moisture weekly",
    );
  }

  void _infoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
