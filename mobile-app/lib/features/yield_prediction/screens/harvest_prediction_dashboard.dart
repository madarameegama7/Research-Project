import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import '../../../utils/yield_prediction/yield_prediction_si.dart';
import '../screens/new_prediction_screen.dart';
import '../screens/prediction_history_screen.dart';
import '../screens/how_prediction_works_screen.dart';
import '../screens/image_capture_guide_screen.dart';
import '../screens/iot_sensor_setup_screen.dart';
import '../screens/weather_impact_screen.dart';
import '../screens/yield_tips_screen.dart';

Color _withOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

class HarvestPredictionDashboard extends StatefulWidget {
  final String language;

  const HarvestPredictionDashboard({super.key, this.language = 'en'});

  @override
  State<HarvestPredictionDashboard> createState() =>
      _HarvestPredictionDashboardState();
}

class _HarvestPredictionDashboardState extends State<HarvestPredictionDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get _isSi => widget.language == 'si';

  String _t(String english, String sinhala) => _isSi ? sinhala : english;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

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
        title: Text(
          _t("Harvest Prediction", YieldPredictionSi.harvestPrediction),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PredictionHistoryScreen(language: widget.language),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: responsive.value(
                      mobile: 16,
                      tablet: 20,
                      desktop: 24,
                    ),
                  ),

                  // ── Status banner ──────────────────────────────────────
                  _buildStatusBanner(responsive),

                  SizedBox(
                    height: responsive.value(
                      mobile: 16,
                      tablet: 20,
                      desktop: 24,
                    ),
                  ),

                  // ── Summary grid ───────────────────────────────────────
                  _buildSummaryGrid(responsive),

                  SizedBox(
                    height: responsive.value(
                      mobile: 24,
                      tablet: 28,
                      desktop: 32,
                    ),
                  ),

                  // ── Actions section ────────────────────────────────────
                  _buildSectionTitle(
                    responsive,
                    primary,
                    _t(
                      "Prediction Actions",
                      YieldPredictionSi.whatWouldYouLikeToDo,
                    ),
                    Icons.agriculture_rounded,
                  ),

                  SizedBox(
                    height: responsive.value(
                      mobile: 14,
                      tablet: 18,
                      desktop: 22,
                    ),
                  ),

                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildActionCardsGrid(responsive, primary),
                  ),

                  SizedBox(
                    height: responsive.value(
                      mobile: 24,
                      tablet: 28,
                      desktop: 32,
                    ),
                  ),

                  // ── Resources section ──────────────────────────────────
                  _buildSectionTitle(
                    responsive,
                    primary,
                    _t(
                      "Resources & Support",
                      YieldPredictionSi.resourcesSupport,
                    ),
                    Icons.dashboard_customize_rounded,
                  ),

                  SizedBox(
                    height: responsive.value(
                      mobile: 14,
                      tablet: 18,
                      desktop: 22,
                    ),
                  ),

                  _buildResourceCards(responsive),

                  SizedBox(
                    height: responsive.value(
                      mobile: 32,
                      tablet: 40,
                      desktop: 48,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Section title ────────────────────────────────────────────────────────

  Widget _buildSectionTitle(
    Responsive responsive,
    Color primary,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: responsive.value(mobile: 4, tablet: 5, desktop: 6),
          height: responsive.value(mobile: 20, tablet: 22, desktop: 24),
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: responsive.value(mobile: 10, tablet: 12, desktop: 14)),
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
          color: primary,
          size: responsive.value(mobile: 22, tablet: 24, desktop: 26),
        ),
      ],
    );
  }

  // ── Status banner ────────────────────────────────────────────────────────

  Widget _buildStatusBanner(Responsive responsive) {
    return Container(
      padding: EdgeInsets.all(
        responsive.value(mobile: 12, tablet: 14, desktop: 16),
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: _withOpacity(Colors.black, 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _t(
                "Latest prediction: Yield prediction successful.",
                YieldPredictionSi.cropConditionHealthy,
              ),
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: Colors.green.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary grid ─────────────────────────────────────────────────────────

  Widget _buildSummaryGrid(Responsive responsive) {
    final crossAxisCount = responsive
        .value(mobile: 2, tablet: 4, desktop: 4)
        .toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = responsive.value(mobile: 10, tablet: 12, desktop: 14);
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;


        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
        );
      },
    );
  }

  Widget _summaryCard(
    Responsive responsive, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
      padding: EdgeInsets.all(
        responsive.value(mobile: 10, tablet: 12, desktop: 14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(
              responsive.value(mobile: 7, tablet: 8, desktop: 9),
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
            ),
          ),
          SizedBox(height: responsive.value(mobile: 5, tablet: 6, desktop: 8)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: responsive.value(mobile: 15, tablet: 16, desktop: 18),
                fontWeight: FontWeight.w800,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          SizedBox(height: responsive.value(mobile: 2, tablet: 3, desktop: 4)),
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.value(mobile: 10, tablet: 11, desktop: 12),
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

  // ── Action cards grid ────────────────────────────────────────────────────

  Widget _buildActionCardsGrid(Responsive responsive, Color primary) {
    final crossAxisCount = responsive
        .value(mobile: 2, tablet: 2, desktop: 4)
        .toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = responsive.value(mobile: 12, tablet: 16, desktop: 20);
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;

        final cards = _buildActionCards(responsive);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(width: itemWidth, child: card);
          }).toList(),
        );
      },
    );
  }

  List<Widget> _buildActionCards(Responsive responsive) {
    return [
      _featureCard(
        responsive,
        title: _t("New\nPrediction", YieldPredictionSi.newPrediction),
        subtitle: _t("Estimate yield", YieldPredictionSi.estimateYield),
        iconData: Icons.add_chart_rounded,
        iconBgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewPredictionScreen(language: widget.language),
          ),
        ),
      ),
      _featureCard(
        responsive,
        title: _t("Past\nPredictions", YieldPredictionSi.pastPredictions),
        subtitle: _t("View history", YieldPredictionSi.viewHistory),
        iconData: Icons.history_rounded,
        iconBgColor: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1565C0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PredictionHistoryScreen(language: widget.language),
          ),
        ),
      ),
      _featureCard(
        responsive,
        title: _t("Weather\nImpact", YieldPredictionSi.weatherImpactCard),
        subtitle: _t("View factors", YieldPredictionSi.viewFactors),
        iconData: Icons.cloud_rounded,
        iconBgColor: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFE65100),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WeatherImpactScreen(language: widget.language),
          ),
        ),
      ),
      _featureCard(
        responsive,
        title: _t("Yield\nTips", YieldPredictionSi.yieldTipsCard),
        subtitle: _t("Improve output", YieldPredictionSi.improveOutput),
        iconData: Icons.lightbulb_outline_rounded,
        iconBgColor: const Color(0xFFFCE4EC),
        iconColor: const Color(0xFFC62828),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => YieldTipsScreen(language: widget.language),
          ),
        ),
      ),
    ];
  }

  Widget _featureCard(
    Responsive responsive, {
    required String title,
    required String subtitle,
    required IconData iconData,
    required Color iconBgColor,
    required Color iconColor,
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
            gradient: const LinearGradient(
              colors: [Color(0xFFF8FAF8), Color(0xFFEFF2EF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              responsive.value(mobile: 16, tablet: 20, desktop: 24),
            ),
            boxShadow: [
              BoxShadow(
                color: _withOpacity(Colors.black, 0.15),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: responsive.padding(
                    mobile: const EdgeInsets.all(8),
                    tablet: const EdgeInsets.all(10),
                    desktop: const EdgeInsets.all(12),
                  ),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: responsive.value(mobile: 28, tablet: 36, desktop: 40),
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
                    color: Colors.black87,
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
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: responsive.value(mobile: 8, tablet: 10, desktop: 12),
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

  // ── Resource cards ───────────────────────────────────────────────────────

  Widget _buildResourceCards(Responsive responsive) {
    return Column(
      children: [
        _resourceCard(
          responsive,
          title: _t(
            "How Yield Prediction Works",
            YieldPredictionSi.howYieldPredictionWorksTitle,
          ),
          description: _t(
            "Understand the AI model",
            YieldPredictionSi.understandAiModel,
          ),
          icon: Icons.school_rounded,
          color: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  HowPredictionWorksScreen(language: widget.language),
            ),
          ),
        ),
        SizedBox(height: responsive.value(mobile: 8, tablet: 10, desktop: 12)),
        _resourceCard(
          responsive,
          title: _t(
            "Image Capture Guide",
            YieldPredictionSi.imageCaptureGuideTitle,
          ),
          description: _t(
            "Improve image quality",
            YieldPredictionSi.improveImageQuality,
          ),
          icon: Icons.camera_alt_rounded,
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ImageCaptureGuideScreen(language: widget.language),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resourceCard(
    Responsive responsive, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
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
          padding: EdgeInsets.all(
            responsive.value(mobile: 12, tablet: 14, desktop: 16),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  responsive.value(mobile: 9, tablet: 10, desktop: 11),
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
                ),
              ),
              SizedBox(
                width: responsive.value(mobile: 10, tablet: 12, desktop: 14),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: responsive.value(
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: responsive.value(
                        mobile: 2,
                        tablet: 3,
                        desktop: 4,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: responsive.value(
                          mobile: 11,
                          tablet: 12,
                          desktop: 13,
                        ),
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[400],
                size: responsive.value(mobile: 15, tablet: 17, desktop: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
