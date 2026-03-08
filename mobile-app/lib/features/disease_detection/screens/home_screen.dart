import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'image_picker_screen.dart';
import 'posts_view_screen.dart';
import 'complaint_screen.dart';
import 'complaint_list_screen.dart';
import 'weather_forecast_screen.dart';
import '../../../utils/localization.dart';
import '../../../utils/language_prefs.dart';
import '../../../widgets/bottom_navigation.dart';

Color _withOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _currentLanguage = 'en';

  static const Color primary = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();

    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) setState(() => _currentLanguage = lang);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openCamera(BuildContext context) async {
    final image = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (context) => const ImagePickerScreen()),
    );
    if (image != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate('photo_captured')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToPosts(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PostsViewScreen()),
  );

  void _navigateToComplaint(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ComplaintScreen()),
  );

  void _navigateToComplaintManagement(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ComplaintListScreen()),
  );

  void _navigateToWeatherForecast(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const WeatherForecastScreen()),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // ── AppBar: exactly like QualityGradingDashboard ──────────────────────
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _translate('disease_detection_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0,
        onTabSelected: (index) {
          if (index != 0) Navigator.pop(context);
        },
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Info card
                  _buildInfoCard(),

                  const SizedBox(height: 24),

                  // Section title
                  _buildSectionTitle(
                    _translate('explore_features'),
                    Icons.agriculture_rounded,
                  ),

                  const SizedBox(height: 14),

                  // 4 equal-size cards in 2x2 grid
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildActionCardsGrid(context),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        Icon(icon, color: primary, size: 22),
      ],
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _withOpacity(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _withOpacity(primary, 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translate('smart_farming_tools'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _translate('disease_description'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2x2 equal-size action cards grid ──────────────────────────────────────

  Widget _buildActionCardsGrid(BuildContext context) {
    final cards = [
      _FeatureCardData(
        title: _translate('view_posts'),
        subtitle: _translate('view_posts_subtitle'),
        iconData: Icons.dynamic_feed_rounded,
        iconBgColor: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1565C0),
        onTap: () => _navigateToPosts(context),
      ),
      _FeatureCardData(
        title: _translate('detection_camera'),
        subtitle: _translate('detection_camera_subtitle'),
        iconData: Icons.camera_alt_rounded,
        iconBgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        onTap: () => _openCamera(context),
      ),
      _FeatureCardData(
        title: _translate('make_complaint'),
        subtitle: _translate('make_complaint_subtitle'),
        iconData: Icons.report_problem_rounded,
        iconBgColor: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFE65100),
        onTap: () => _navigateToComplaint(context),
      ),
      _FeatureCardData(
        title: _translate('manage_complaints'),
        subtitle: _translate('manage_complaints_subtitle'),
        iconData: Icons.admin_panel_settings_rounded,
        iconBgColor: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF6A1B9A),
        onTap: () => _navigateToComplaintManagement(context),
      ),
      _FeatureCardData(
        title: _translate('weather_forecast'),
        subtitle: _translate('weather_forecast_subtitle'),
        iconData: Icons.cloud_rounded,
        iconBgColor: const Color(0xFFE1F5FE),
        iconColor: const Color(0xFF01579B),
        onTap: () => _navigateToWeatherForecast(context),
      ),
    ];

    // GridView with fixed aspect ratio so all cards are identical in size
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0, // square cards — adjust if needed
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => _buildFeatureCard(cards[index]),
    );
  }

  Widget _buildFeatureCard(_FeatureCardData data) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF8FAF8), Color(0xFFEFF2EF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _withOpacity(Colors.black, 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: data.iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.iconData, color: data.iconColor, size: 28),
              ),

              const SizedBox(height: 10),

              // Title
              Text(
                data.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Subtitle
              Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Push arrow to the bottom
              const Spacer(),

              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _translate(String key) =>
      AppLocalizations.translate(_currentLanguage, key);
}

// ── Simple data class to keep card definitions tidy ───────────────────────

class _FeatureCardData {
  final String title;
  final String subtitle;
  final IconData iconData;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _FeatureCardData({
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });
}
