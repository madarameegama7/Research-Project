import 'package:flutter/material.dart';
import 'package:CeylonPepper/features/market_forecast/navigation.dart';
import '../disease_detection/screens/home_screen.dart';
import '../disease_detection/services/weather_service.dart';
import '../disease_detection/services/location_service.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../../utils/localization.dart';
import '../../utils/language_prefs.dart';
import '../auth/login_page.dart';
import '../marketplace/marketplace_screen.dart';
import '../quality_grading/screens/quality_grading_dashboard.dart';
import '../chatbot/chatbot_screen.dart';
import '../yield_prediction/screens/harvest_prediction_dashboard.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

// Helper to create a Color from an existing Color with a custom opacity (0.0-1.0)
Color colorWithOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AuthService _authService = AuthService();
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();

  bool _isLoadingWeather = true;
  String _locationName = 'Loading...';
  String _temperature = '--°C';
  String _weatherCondition = 'clear';
  String _currentLanguage = 'en';
  String _userName = "Farmer";

  // Mock data for dashboard statistics
  int _totalCrops = 0;
  int _activeAlerts = 0;
  double _avgQuality = 0.0;

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

    _loadUserName();

    // Load saved language preference
    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) {
        setState(() {
          _currentLanguage = lang;
        });
      }
    });

    // verify assets exist in the bundle (helpful for debugging missing icons)
    _verifyAssets();

    // Load initial data
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fetchWeatherData();
        _loadDashboardStats();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _switchLanguage(String languageCode) {
    setState(() {
      _currentLanguage = languageCode;
    });
    LanguagePrefs.setLanguage(languageCode);
  }

  String _translate(String key) {
    return AppLocalizations.translate(_currentLanguage, key);
  }

  String _titleCase(String s) {
  final parts = s.trim().split(RegExp(r'\s+'));
  return parts.map((p) {
    if (p.isEmpty) return '';
    final lower = p.toLowerCase();
    return lower.length == 1 ? lower.toUpperCase() : '${lower[0].toUpperCase()}${lower.substring(1)}';
  }).where((p) => p.isNotEmpty).join(' ');
}

Future<void> _loadUserName() async {
  try {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      final firstRaw = (user['firstName'] ?? user['first_name'] ?? user['name'] ?? '').toString();
      final lastRaw = (user['lastName'] ?? user['last_name'] ?? '').toString();
      final first = _titleCase(firstRaw);
      final last = _titleCase(lastRaw);
      final name = (first + (last.isNotEmpty ? ' $last' : '')).trim();
      if (mounted && name.isNotEmpty) {
        setState(() => _userName = name);
        return;
      }
    }

    final fb = _authService.currentUser;
    if (fb != null && fb.displayName != null && fb.displayName!.trim().isNotEmpty) {
      if (mounted) setState(() => _userName = _titleCase(fb.displayName!));
    }
  } catch (e) {
    print("Failed to load user name: $e");
  }
}

  Future<void> _loadDashboardStats() async {
    // Simulate loading dashboard statistics
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _totalCrops = 5; // Mock data - replace with actual data
        _activeAlerts = 2;
        _avgQuality = 87.5;
      });
    }
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoadingWeather = true;
      _locationName = 'Loading...';
      _temperature = '--°C';
    });

    try {
      final locationData = await _locationService.getCurrentLocation().timeout(
        const Duration(seconds: 30),
        onTimeout: () => null,
      );

      double lat = 6.9271; // Colombo fallback
      double lon = 79.8612;

      if (locationData != null) {
        lat = locationData.latitude;
        lon = locationData.longitude;
      }

      if (!mounted) return;

      final weatherData = await _weatherService
          .getWeatherData(lat, lon)
          .timeout(const Duration(seconds: 15), onTimeout: () => null);

      if (weatherData != null && mounted) {
        final parsedData = _weatherService.parseWeatherData(weatherData);
        if (parsedData != null) {
          setState(() {
            _locationName = locationData == null
                ? '${parsedData['location']} (Default)'
                : parsedData['location'] ?? 'Unknown';
            _temperature = '${parsedData['temperature']}°C';
            _weatherCondition =
                parsedData['condition']?.toLowerCase() ?? 'clear';
            _isLoadingWeather = false;
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoadingWeather = false;
        _locationName = locationData == null ? 'Enable GPS' : 'Weather Error';
        _temperature = '--°C';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingWeather = false;
        _locationName = 'Error';
        _temperature = '--°C';
      });
    }
  }

  // Debug helper: try to load expected icon assets and log failures.
  Future<void> _verifyAssets() async {
    final paths = <String>[
      'assets/images/icons/analysis.png',
      'assets/images/icons/test.png',
      'assets/images/icons/check.png',
      'assets/images/icons/trend.png',
      'assets/images/icons/crops.png',
      'assets/images/icons/notification.png',
      'assets/images/icons/quality.png',
    ];

    for (final p in paths) {
      try {
        await rootBundle.load(p);
        debugPrint('Asset found: $p');
      } catch (e) {
        debugPrint('Missing asset: $p -> $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final primary = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              await _fetchWeatherData();
              await _loadDashboardStats();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Header with Weather
                  _buildHeader(responsive, primary),

                  ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                  // Quick Stats Cards
                  _buildQuickStats(responsive, primary),

                  ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                  // Section: Main Features
                  _buildSectionTitle(
                    responsive,
                    primary,
                    _translate('smart_farming_tools'),
                    Icons.agriculture_rounded,
                  ),

                  ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                  // Main Feature Grid
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildMainFeatureGrid(context, responsive, primary),
                  ),

                  ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                  // Section: Additional Features
                  _buildSectionTitle(
                    responsive,
                    primary,
                    _translate('more_services'),
                    Icons.dashboard_customize_rounded,
                  ),

                  ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                  // Additional Features
                  _buildAdditionalFeatures(context, responsive, primary),

                  ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                  // Recommended Tips Section
                  _buildSectionTitle(
                    responsive,
                    primary,
                    _translate('farming_tips_insights'),
                    Icons.lightbulb_rounded,
                    iconColor: Colors.amber[700],
                  ),

                  ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                  _buildTipsSection(responsive),

                  ResponsiveSpacing(mobile: 24, tablet: 32, desktop: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Responsive responsive, Color primary) {
    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        tablet: const EdgeInsets.fromLTRB(32, 24, 32, 36),
        desktop: const EdgeInsets.fromLTRB(40, 28, 40, 42),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, colorWithOpacity(primary, 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            responsive.value(mobile: 28, tablet: 36, desktop: 40),
          ),
          bottomRight: Radius.circular(
            responsive.value(mobile: 28, tablet: 36, desktop: 40),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(primary, 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $_userName 👋",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: responsive.fontSize(
                          mobile: 13,
                          tablet: 15,
                          desktop: 16,
                        ),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    ResponsiveSpacing(mobile: 4, tablet: 6, desktop: 8),
                    Text(
                      _translate('ceylon_pepper'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.fontSize(
                          mobile: 22,
                          tablet: 26,
                          desktop: 30,
                        ),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Language Switcher
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorWithOpacity(Colors.white, 0.3),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _languageButton('EN', 'en', responsive, primary),
                        Container(
                          width: 1,
                          height: responsive.value(
                            mobile: 20,
                            tablet: 22,
                            desktop: 24,
                          ),
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _languageButton('සි', 'si', responsive, primary),
                        Container(
                          width: 1,
                          height: responsive.value(
                            mobile: 20,
                            tablet: 22,
                            desktop: 24,
                          ),
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _languageButton('தமிழ்', 'ta', responsive, primary),
                      ],
                    ),
                  ),
                  ResponsiveSpacing(mobile: 10, tablet: 12, desktop: 14),
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: EdgeInsets.all(
                        responsive.value(mobile: 2, tablet: 3, desktop: 4),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: responsive.value(
                          mobile: 18,
                          tablet: 22,
                          desktop: 26,
                        ),
                        backgroundColor: colorWithOpacity(primary, 0.1),
                        child: Icon(
                          Icons.person_rounded,
                          color: primary,
                          size: responsive.value(
                            mobile: 20,
                            tablet: 24,
                            desktop: 28,
                          ),
                        ),
                      ),
                    ),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await _authService.logout();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 20),
                            SizedBox(width: 12),
                            Text(_translate('profile')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, size: 20),
                            SizedBox(width: 12),
                            Text(_translate('settings')),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Text(
                              _translate('logout'),
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),
          // Weather Widget
          GestureDetector(
            onTap: _fetchWeatherData,
            child: Container(
              padding: responsive.padding(
                mobile: const EdgeInsets.all(14),
                tablet: const EdgeInsets.all(18),
                desktop: const EdgeInsets.all(20),
              ),
              decoration: BoxDecoration(
                color: colorWithOpacity(Colors.white, 0.15),
                borderRadius: BorderRadius.circular(
                  responsive.value(mobile: 14, tablet: 18, desktop: 20),
                ),
                border: Border.all(
                  color: colorWithOpacity(Colors.white, 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorWithOpacity(Colors.black, 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: responsive.value(
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                  ),
                  ResponsiveSpacing.horizontal(
                    mobile: 8,
                    tablet: 10,
                    desktop: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLoadingWeather
                              ? _translate('fetching_location')
                              : _locationName,
                          style: TextStyle(
                            color: colorWithOpacity(Colors.white, 0.95),
                            fontSize: responsive.fontSize(
                              mobile: 13,
                              tablet: 14,
                              desktop: 15,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!_isLoadingWeather)
                          Text(
                            _translate('tap_to_refresh'),
                            style: TextStyle(
                              color: colorWithOpacity(Colors.white, 0.7),
                              fontSize: responsive.fontSize(
                                mobile: 11,
                                tablet: 12,
                                desktop: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isLoadingWeather)
                    SizedBox(
                      width: responsive.value(
                        mobile: 18,
                        tablet: 20,
                        desktop: 22,
                      ),
                      height: responsive.value(
                        mobile: 18,
                        tablet: 20,
                        desktop: 22,
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          _getWeatherIcon(),
                          color: Colors.white,
                          size: responsive.value(
                            mobile: 22,
                            tablet: 24,
                            desktop: 26,
                          ),
                        ),
                        ResponsiveSpacing.horizontal(
                          mobile: 6,
                          tablet: 8,
                          desktop: 10,
                        ),
                        Text(
                          _temperature,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.fontSize(
                              mobile: 16,
                              tablet: 17,
                              desktop: 18,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon() {
    if (_weatherCondition.contains('rain')) return Icons.water_drop_rounded;
    if (_weatherCondition.contains('cloud')) return Icons.cloud_rounded;
    if (_weatherCondition.contains('sun') ||
        _weatherCondition.contains('clear')) {
      return Icons.wb_sunny_rounded;
    }
    return Icons.cloud_outlined;
  }

  Widget _languageButton(
    String label,
    String languageCode,
    Responsive responsive,
    Color primary,
  ) {
    final isSelected = _currentLanguage == languageCode;

    return GestureDetector(
      onTap: () => _switchLanguage(languageCode),
      child: Container(
        padding: responsive.padding(
          mobile: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          tablet: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          desktop: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        ),
        color: isSelected
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: responsive.fontSize(mobile: 11, tablet: 12, desktop: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Responsive responsive, Color primary) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(
          mobile: 16,
          tablet: 24,
          desktop: 32,
        ),
      ),
      child: ResponsiveBuilder(
        mobile: _buildStatsRow(responsive, primary),
        tablet: _buildStatsRow(responsive, primary),
        desktop: _buildStatsRow(responsive, primary),
      ),
    );
  }

  Widget _buildStatsRow(Responsive responsive, Color primary) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            responsive,
            _translate('total_crops'),
            _totalCrops.toString(),
            iconPath: "assets/images/icons/crops.png",
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 10, tablet: 14, desktop: 18),
        Expanded(
          child: _buildStatCard(
            responsive,
            _translate('active_alerts'),
            _activeAlerts.toString(),
            iconPath: "assets/images/icons/notification.png",
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 10, tablet: 14, desktop: 18),
        Expanded(
          child: _buildStatCard(
            responsive,
            _translate('avg_quality'),
            "${_avgQuality.toStringAsFixed(1)}%",
            iconPath: "assets/images/icons/quality.png",
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    Responsive responsive,
    String label,
    String value, {
    required String iconPath,
  }) {
    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        tablet: const EdgeInsets.all(18),
        desktop: const EdgeInsets.all(20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 14, tablet: 18, desktop: 20),
        ),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(
              responsive.value(mobile: 6, tablet: 8, desktop: 10),
            ),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Image.asset(
              iconPath,
              width: responsive.value(mobile: 38, tablet: 44, desktop: 48),
              height: responsive.value(mobile: 38, tablet: 44, desktop: 48),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Failed to load asset: $iconPath — $error');
                return Icon(
                  Icons.broken_image,
                  size: responsive.value(mobile: 38, tablet: 44, desktop: 48),
                  color: Colors.grey[400],
                );
              },
            ),
          ),
          ResponsiveSpacing(mobile: 6, tablet: 8, desktop: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 16,
                tablet: 17,
                desktop: 18,
              ),
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          ResponsiveSpacing(mobile: 2, tablet: 3, desktop: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 11,
                tablet: 12,
                desktop: 13,
              ),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    Responsive responsive,
    Color primary,
    String title,
    IconData icon, {
    Color? iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(
          mobile: 16,
          tablet: 24,
          desktop: 32,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: responsive.value(mobile: 4, tablet: 5, desktop: 6),
            height: responsive.value(mobile: 20, tablet: 22, desktop: 24),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ResponsiveSpacing.horizontal(mobile: 10, tablet: 12, desktop: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: responsive.fontSize(
                  mobile: 17,
                  tablet: 20,
                  desktop: 22,
                ),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          Icon(
            icon,
            color: iconColor ?? primary,
            size: responsive.value(
              mobile: 22,
              tablet: 24,
              desktop: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainFeatureGrid(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(
          mobile: 16,
          tablet: 24,
          desktop: 32,
        ),
      ),
      child: ResponsiveBuilder(
        mobile: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: responsive.value(mobile: 12, tablet: 16, desktop: 20),
          mainAxisSpacing: responsive.value(mobile: 12, tablet: 16, desktop: 20),
          childAspectRatio: responsive.value(mobile: 1.05, tablet: 1.1, desktop: 1.15),
          physics: const NeverScrollableScrollPhysics(),
          children: _buildMainFeatureCards(context, responsive),
        ),
        tablet: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.2,
          physics: const NeverScrollableScrollPhysics(),
          children: _buildMainFeatureCards(context, responsive),
        ),
        desktop: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          crossAxisSpacing: 22,
          mainAxisSpacing: 22,
          childAspectRatio: 1.1,
          physics: const NeverScrollableScrollPhysics(),
          children: _buildMainFeatureCards(context, responsive),
        ),
      ),
    );
  }

  List<Widget> _buildMainFeatureCards(
    BuildContext context,
    Responsive responsive,
  ) {
    return [
      _featureCard(
        context,
        responsive,
        title: _translate('yield_prediction'),
        subtitle: _translate('forecast_harvest'),
        iconPath: "assets/images/icons/analysis.png",
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 248, 250, 248),
            Color.fromARGB(255, 239, 242, 239),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const HarvestPredictionDashboard(),
            ),
          );
        },
      ),
      _featureCard(
        context,
        responsive,
        title: _translate('disease_detection'),
        subtitle: _translate('ai_diagnosis'),
        iconPath: "assets/images/icons/test.png",
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 248, 250, 248),
            Color.fromARGB(255, 239, 242, 239),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HomeScreen()),
          );
        },
      ),
      _featureCard(
        context,
        responsive,
        title: _translate('quality_grading'),
        subtitle: _translate('iso_standards'),
        iconPath: "assets/images/icons/check.png",

        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 248, 250, 248),
            Color.fromARGB(255, 239, 242, 239),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QualityGradingDashboard()),
          );
        },
      ),
      _featureCard(
        context,
        responsive,
        title: _translate('market_forecast'),
        subtitle: _translate('price_trends'),
        iconPath: "assets/images/icons/trend.png",
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 248, 250, 248),
            Color.fromARGB(255, 239, 242, 239),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PriceNavigation()),
          );
        },
      ),
    ];
  }

  Widget _buildAdditionalFeatures(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(
          mobile: 16,
          tablet: 24,
          desktop: 32,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                flex: 1,
                child: _secondaryFeatureCard(
                  context,
                  responsive,
                  _translate('ai_assistant'),
                  Icons.smart_toy_rounded,
                  Color(0xFF43A047),
                  Color(0xFFE8F5E9),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                    );
                  },
                ),
              ),
              ResponsiveSpacing.horizontal(mobile: 12, tablet: 16, desktop: 20),
              Flexible(
                flex: 1,
                child: _secondaryFeatureCard(
                  context,
                  responsive,
                  _translate('marketplace'),
                  Icons.store_rounded,
                  Color(0xFF2E7D32),
                  Color(0xFFE8F5E9),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MarketplaceScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _secondaryFeatureCard(
    BuildContext context,
    Responsive responsive,
    String title,
    IconData icon,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 14, tablet: 18, desktop: 20),
        ),
        child: Container(
          padding: responsive.padding(
            mobile: const EdgeInsets.all(14),
            tablet: const EdgeInsets.all(20),
            desktop: const EdgeInsets.all(24),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              responsive.value(mobile: 14, tablet: 18, desktop: 20),
            ),
            border: Border.all(color: bgColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: colorWithOpacity(Colors.black, 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  responsive.value(mobile: 10, tablet: 12, desktop: 14),
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: responsive.value(
                    mobile: 22,
                    tablet: 24,
                    desktop: 26,
                  ),
                ),
              ),
              ResponsiveSpacing.horizontal(mobile: 10, tablet: 12, desktop: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ResponsiveSpacing(mobile: 2, tablet: 3, desktop: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _translate('explore'),
                            style: TextStyle(
                              fontSize: responsive.fontSize(
                                mobile: 11,
                                tablet: 12,
                                desktop: 13,
                              ),
                              color: iconColor,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ResponsiveSpacing.horizontal(
                          mobile: 4,
                          tablet: 5,
                          desktop: 6,
                        ),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: iconColor,
                          size: responsive.value(
                            mobile: 13,
                            tablet: 14,
                            desktop: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard(
    BuildContext context,
    Responsive responsive, {
    required String title,
    required String subtitle,
    required String iconPath,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 20, desktop: 24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(
              responsive.value(mobile: 16, tablet: 20, desktop: 24),
            ),
            boxShadow: [
              BoxShadow(
                color: colorWithOpacity(Colors.black, 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: responsive.padding(
              mobile: const EdgeInsets.all(12),
              tablet: const EdgeInsets.all(16),
              desktop: const EdgeInsets.all(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: responsive.padding(
                        mobile: const EdgeInsets.all(8),
                        tablet: const EdgeInsets.all(10),
                        desktop: const EdgeInsets.all(12),
                      ),
                      decoration: BoxDecoration(
                        color: colorWithOpacity(Colors.white, 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        iconPath,
                        width: responsive.value(mobile: 32, tablet: 42, desktop: 48),
                        height: responsive.value(mobile: 32, tablet: 42, desktop: 48),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Failed to load asset: $iconPath — $error');
                          return Icon(
                            Icons.broken_image,
                            size: responsive.value(
                              mobile: 28,
                              tablet: 36,
                              desktop: 40,
                            ),
                            color: Colors.grey[300],
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      height: responsive.value(mobile: 8, tablet: 10, desktop: 12),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                          mobile: 13,
                          tablet: 15,
                          desktop: 16,
                        ),
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: responsive.value(mobile: 3, tablet: 4, desktop: 5),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                          mobile: 10,
                          tablet: 11,
                          desktop: 12,
                        ),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: responsive.value(mobile: 16, tablet: 18, desktop: 20),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsSection(Responsive responsive) {
    return SizedBox(
      height: responsive.value(mobile: 135, tablet: 155, desktop: 175),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.value(
            mobile: 16,
            tablet: 24,
            desktop: 32,
          ),
        ),
        children: [
          _tipCard(
            _translate('monitor_soil_moisture'),
            Icons.water_drop_rounded,
            Colors.blue.shade50,
            Colors.blue.shade700,
            responsive,
          ),
          _tipCard(
            _translate('apply_organic_fertilizers'),
            Icons.eco_rounded,
            Colors.green.shade50,
            Colors.green.shade700,
            responsive,
          ),
          _tipCard(
            _translate('check_pest_damage'),
            Icons.bug_report_rounded,
            Colors.red.shade50,
            Colors.red.shade700,
            responsive,
          ),
          _tipCard(
            _translate('maintain_plant_spacing'),
            Icons.space_dashboard_rounded,
            Colors.purple.shade50,
            Colors.purple.shade700,
            responsive,
          ),
          _tipCard(
            _translate('harvest_optimal_maturity'),
            Icons.calendar_today_rounded,
            Colors.orange.shade50,
            Colors.orange.shade700,
            responsive,
          ),
        ],
      ),
    );
  }

  Widget _tipCard(
    String text,
    IconData icon,
    Color bgColor,
    Color iconColor,
    Responsive responsive,
  ) {
    return Container(
      margin: EdgeInsets.only(
        right: responsive.value(mobile: 12, tablet: 14, desktop: 16),
      ),
      padding: responsive.padding(
        mobile: const EdgeInsets.all(14),
        tablet: const EdgeInsets.all(18),
        desktop: const EdgeInsets.all(22),
      ),
      width: responsive.value(mobile: 190, tablet: 220, desktop: 240),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        border: Border.all(color: colorWithOpacity(iconColor, 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: responsive.padding(
              mobile: const EdgeInsets.all(9),
              tablet: const EdgeInsets.all(10),
              desktop: const EdgeInsets.all(11),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorWithOpacity(iconColor, 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: responsive.value(
                mobile: 22,
                tablet: 24,
                desktop: 26,
              ),
            ),
          ),
          ResponsiveSpacing(mobile: 10, tablet: 12, desktop: 14),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: responsive.fontSize(
                mobile: 13,
                tablet: 14,
                desktop: 15,
              ),
              color: Colors.grey[800],
              height: 1.35,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}