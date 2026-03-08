import 'package:flutter/material.dart';
import 'package:CeylonPepper/features/market_forecast/screens/navigation.dart';
import '../auth/login_page.dart';
import '../disease_detection/screens/home_screen.dart';
import '../disease_detection/services/weather_service.dart';
import '../disease_detection/services/location_service.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../../utils/localization.dart';
import '../../utils/language_prefs.dart';
import '../../utils/farmer_dashboard_si.dart';
import '../quality_grading/screens/quality_grading_dashboard.dart';
import '../chatbot/chatbot_screen.dart';
import '../yield_prediction/screens/harvest_prediction_dashboard.dart';
import 'package:flutter/services.dart';
import '../quality_grading/services/quality_check_api.dart';
import '../../services/farmer_service.dart';

// Helper to create a Color from an existing Color with a custom opacity (0.0-1.0)
Color colorWithOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

class FarmerDashboard extends StatefulWidget {
  final Function(int)? onTabSelected;

  const FarmerDashboard({super.key, this.onTabSelected});

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
  final QualityCheckApi _qualityCheckApi = QualityCheckApi();
  final FarmerService _farmerService = FarmerService();

  bool _isLoadingWeather = true;
  String _locationName = 'Loading...';
  String _temperature = '--°C';
  String _weatherCondition = 'clear';
  String _currentLanguage = 'en';
  String _userName = "Farmer";

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

    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) {
        setState(() {
          _currentLanguage = lang;
        });
      }
    });

    _verifyAssets();

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
    return parts
        .map((p) {
          if (p.isEmpty) return '';
          final lower = p.toLowerCase();
          return lower.length == 1
              ? lower.toUpperCase()
              : '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .where((p) => p.isNotEmpty)
        .join(' ');
  }

  Future<void> _loadUserName() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final firstRaw =
            (user['firstName'] ?? user['first_name'] ?? user['name'] ?? '')
                .toString();
        final lastRaw = (user['lastName'] ?? user['last_name'] ?? '')
            .toString();
        final first = _titleCase(firstRaw);
        final last = _titleCase(lastRaw);
        final name = (first + (last.isNotEmpty ? ' $last' : '')).trim();
        if (mounted && name.isNotEmpty) {
          setState(() => _userName = name);
          return;
        }
      }

      final fb = _authService.currentUser;
      if (fb != null &&
          fb.displayName != null &&
          fb.displayName!.trim().isNotEmpty) {
        if (mounted) setState(() => _userName = _titleCase(fb.displayName!));
      }
    } catch (e) {
      print("Failed to load user name: $e");
    }
  }

  Future<void> _loadDashboardStats() async {
    double fetchedAvg = 0.0;
    int fetchedTotalCrops = 0;
    
    try {
      final plots = await _farmerService.fetchPlots();
      fetchedTotalCrops = plots.length;
    } catch (e) {
      debugPrint("Failed to load plots: $e");
    }

    try {
      final rawList = await _qualityCheckApi.getMyQualityChecks();
      final List<Map<String, dynamic>> enriched = [];
      for (final item in rawList) {
        try {
          final id = item['_id']?.toString() ?? '';
          if (id.isEmpty) continue;
          final full = await _qualityCheckApi.getQualityCheckById(qualityCheckId: id);
          if (full['status'] == 'completed') enriched.add(full);
        } catch (_) {}
      }
      
      if (enriched.isNotEmpty) {
        int totalScore = 0;
        for (final r in enriched) {
          totalScore += ((r['results']?['overallScore'] as num?)?.round()) ?? 0;
        }
        fetchedAvg = totalScore / enriched.length;
      }
    } catch (e) {
      debugPrint("Failed to load quality stats: $e");
    }

    if (mounted) {
      setState(() {
        _totalCrops = fetchedTotalCrops;
        _activeAlerts = 2;
        _avgQuality = fetchedAvg > 0 ? fetchedAvg : 0.0;
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

      double lat = 6.9271;
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
      // ── Floating AI Assistant Button ─────────────────────────────
      floatingActionButton: _buildAIFab(context, responsive, primary),
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
                  // Header with Weather
                  _buildHeader(responsive, primary),

                  ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                  // Quick Stats Cards
                  _buildQuickStats(responsive, primary),

                  ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                  // Section: Smart Farming Tools
                  _buildSectionTitle(
                    responsive,
                    primary,
                    _currentLanguage == 'si'
                        ? FarmerDashboardSi.smartFarmingTools
                        : _translate('smart_farming_tools'),
                    Icons.agriculture_rounded,
                  ),

                  ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                  // Main Feature Grid
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildMainFeatureGrid(context, responsive, primary),
                  ),

                  ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                  // Tips Section
                  _buildSectionTitle(
                    responsive,
                    primary,
                    _currentLanguage == 'si'
                        ? FarmerDashboardSi.farmingTipsInsights
                        : _translate('farming_tips_insights'),
                    Icons.lightbulb_rounded,
                    iconColor: Colors.amber[700],
                  ),

                  ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                  _buildTipsSection(responsive),

                  // Extra bottom padding so FAB doesn't overlap last tip card
                  ResponsiveSpacing(mobile: 88, tablet: 96, desktop: 104),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Pulsing Floating AI Assistant Button ─────────────────────────────────
  Widget _buildAIFab(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    return _PulsingFAB(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        );
      },
      primary: primary,
      label: _currentLanguage == 'si'
          ? FarmerDashboardSi.aiAssistant
          : _translate('ai_assistant'),
    );
  }

  // ── Logout Confirmation Dialog ────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context, Color primary) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar + name
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorWithOpacity(primary, 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded, color: primary, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _currentLanguage == 'si'
                    ? 'ඔබට ඇත්තටම පිටවීමට අවශ්‍යද?'
                    : 'Are you sure you want to log out?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Log out button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _authService.logout();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    _currentLanguage == 'si'
                        ? FarmerDashboardSi.logout
                        : _translate('logout'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _currentLanguage == 'si' ? 'අවලංගු කරන්න' : 'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
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
                      "Welcome 👋",
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
                      _currentLanguage == 'si'
                          ? FarmerDashboardSi.ceylonPepper
                          : _translate('ceylon_pepper'),
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
                      ],
                    ),
                  ),
                  ResponsiveSpacing(mobile: 10, tablet: 12, desktop: 14),
                  // Tap avatar → logout confirmation dialog
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context, primary),
                    child: Container(
                      padding: EdgeInsets.all(
                        responsive.value(mobile: 2, tablet: 3, desktop: 4),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
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
                    size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
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
                              ? (_currentLanguage == 'si'
                                    ? FarmerDashboardSi.fetchingLocation
                                    : _translate('fetching_location'))
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
                            _currentLanguage == 'si'
                                ? FarmerDashboardSi.tapToRefresh
                                : _translate('tap_to_refresh'),
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
        horizontal: responsive.value(mobile: 16, tablet: 24, desktop: 32),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              responsive,
              _currentLanguage == 'si'
                  ? FarmerDashboardSi.totalCrops
                  : _translate('total_crops'),
              _totalCrops.toString(),
              iconPath: "assets/images/icons/crops.png",
            ),
          ),
          ResponsiveSpacing.horizontal(mobile: 10, tablet: 14, desktop: 18),
          Expanded(
            child: _buildStatCard(
              responsive,
              _currentLanguage == 'si'
                  ? FarmerDashboardSi.activeAlerts
                  : _translate('active_alerts'),
              _activeAlerts.toString(),
              iconPath: "assets/images/icons/notification.png",
            ),
          ),
          ResponsiveSpacing.horizontal(mobile: 10, tablet: 14, desktop: 18),
          Expanded(
            child: _buildStatCard(
              responsive,
              _currentLanguage == 'si'
                  ? FarmerDashboardSi.avgQuality
                  : _translate('avg_quality'),
              "${_avgQuality.toStringAsFixed(1)}%",
              iconPath: "assets/images/icons/quality.png",
            ),
          ),
        ],
      ),
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
        horizontal: responsive.value(mobile: 16, tablet: 24, desktop: 32),
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
            size: responsive.value(mobile: 22, tablet: 24, desktop: 26),
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
        horizontal: responsive.value(mobile: 16, tablet: 24, desktop: 32),
      ),
      child: ResponsiveBuilder(
        mobile: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: responsive.value(
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
          mainAxisSpacing: responsive.value(
            mobile: 12,
            tablet: 16,
            desktop: 20,
          ),
          childAspectRatio: responsive.value(
            mobile: 1.05,
            tablet: 1.1,
            desktop: 1.15,
          ),
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
        title: _currentLanguage == 'si'
            ? FarmerDashboardSi.yieldPrediction
            : _translate('yield_prediction'),
        subtitle: _currentLanguage == 'si'
            ? FarmerDashboardSi.forecastHarvest
            : _translate('forecast_harvest'),
        iconPath: "assets/images/icons/analysis.png",
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 248, 250, 248),
            Color.fromARGB(255, 239, 242, 239),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  HarvestPredictionDashboard(language: _currentLanguage),
            ),
          );
        },
      ),
      _featureCard(
        context,
        responsive,
        title: _currentLanguage == 'si'
            ? FarmerDashboardSi.diseaseDetection
            : _translate('disease_detection'),
        subtitle: _currentLanguage == 'si'
            ? FarmerDashboardSi.aiDiagnosis
            : _translate('ai_diagnosis'),
        iconPath: "assets/images/icons/test.png",
        gradient: const LinearGradient(
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
        title: _currentLanguage == 'si'
            ? FarmerDashboardSi.qualityGrading
            : _translate('quality_grading'),
        subtitle: _currentLanguage == 'si'
            ? FarmerDashboardSi.gradeYourHarvest
            : _translate('grade_your_harvest'),
        iconPath: "assets/images/icons/check.png",
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 248, 250, 248),
            Color.fromARGB(255, 239, 242, 239),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QualityGradingDashboard(
                onTabSelected: widget.onTabSelected,
                currentIndex: 0,
              ),
            ),
          );
        },
      ),
      _featureCard(
        context,
        responsive,
        title: _currentLanguage == 'si'
            ? FarmerDashboardSi.marketForecast
            : _translate('market_forecast'),
        subtitle: _currentLanguage == 'si'
            ? FarmerDashboardSi.priceTrends
            : _translate('price_trends'),
        iconPath: "assets/images/icons/trend.png",
        gradient: const LinearGradient(
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
                        width: responsive.value(
                          mobile: 32,
                          tablet: 42,
                          desktop: 48,
                        ),
                        height: responsive.value(
                          mobile: 32,
                          tablet: 42,
                          desktop: 48,
                        ),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
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
                      height: responsive.value(
                        mobile: 8,
                        tablet: 10,
                        desktop: 12,
                      ),
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
                      height: responsive.value(
                        mobile: 3,
                        tablet: 4,
                        desktop: 5,
                      ),
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
          horizontal: responsive.value(mobile: 16, tablet: 24, desktop: 32),
        ),
        children: [
          _tipCard(
            _currentLanguage == 'si'
                ? FarmerDashboardSi.monitorSoilMoisture
                : _translate('monitor_soil_moisture'),
            Icons.water_drop_rounded,
            Colors.blue.shade50,
            Colors.blue.shade700,
            responsive,
          ),
          _tipCard(
            _currentLanguage == 'si'
                ? FarmerDashboardSi.applyOrganicFertilizers
                : _translate('apply_organic_fertilizers'),
            Icons.eco_rounded,
            Colors.green.shade50,
            Colors.green.shade700,
            responsive,
          ),
          _tipCard(
            _currentLanguage == 'si'
                ? FarmerDashboardSi.checkPestDamage
                : _translate('check_pest_damage'),
            Icons.bug_report_rounded,
            Colors.red.shade50,
            Colors.red.shade700,
            responsive,
          ),
          _tipCard(
            _currentLanguage == 'si'
                ? FarmerDashboardSi.maintainPlantSpacing
                : _translate('maintain_plant_spacing'),
            Icons.space_dashboard_rounded,
            Colors.purple.shade50,
            Colors.purple.shade700,
            responsive,
          ),
          _tipCard(
            _currentLanguage == 'si'
                ? FarmerDashboardSi.harvestOptimalMaturity
                : _translate('harvest_optimal_maturity'),
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
              size: responsive.value(mobile: 22, tablet: 24, desktop: 26),
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

// ── Pulsing FAB Widget ────────────────────────────────────────────────────────
class _PulsingFAB extends StatefulWidget {
  final VoidCallback onTap;
  final Color primary;
  final String label;

  const _PulsingFAB({
    required this.onTap,
    required this.primary,
    required this.label,
  });

  @override
  State<_PulsingFAB> createState() => _PulsingFABState();
}

class _PulsingFABState extends State<_PulsingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift it above the bottom nav bar
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorWithOpacity(widget.primary, 0.18),
                    ),
                  ),
                ),
                // Main FAB button
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [const Color(0xFF1B5E20), widget.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorWithOpacity(widget.primary, 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                // Small "AI" badge on top-right of the button
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber[400],
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: colorWithOpacity(Colors.black, 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
