import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/bottom_navigation.dart';
import '../../certifications/screens/farmer_certifications_dashboard_screen.dart';
import '../services/quality_check_api.dart';
import 'new_quality_check/batch_details_screen.dart';
import 'how_it_works_screen.dart';
import 'image_capture_guide_screen.dart';
import 'iot_device_setup_screen.dart';
import 'past_reports/past_reports_screen.dart';
import 'quality_tips_main_screen.dart';

Color _withOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

class QualityGradingDashboard extends StatefulWidget {
  const QualityGradingDashboard({super.key});

  @override
  State<QualityGradingDashboard> createState() =>
      _QualityGradingDashboardState();
}

class _QualityGradingDashboardState extends State<QualityGradingDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _totalReports = 0;
  int _premiumGrades = 0;
  bool _statsLoading = true;
  String? _statsError;

  final _api = QualityCheckApi();

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
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _api.getDashboardStats();
      if (mounted) {
        setState(() {
          _totalReports = stats["totalReports"]!;
          _premiumGrades = stats["premiumGrades"]!;
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statsError = e.toString();
          _statsLoading = false;
        });
      }
    }
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Quality Grading",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            onPressed: () => _showQuickGuideDialog(context, responsive),
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

                  _buildSummaryGrid(context, responsive),

                  SizedBox(
                    height: responsive.value(
                      mobile: 24,
                      tablet: 28,
                      desktop: 32,
                    ),
                  ),

                  _buildSectionTitle(
                    responsive,
                    primary,
                    "Grading Actions",
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
                    child: _buildActionCardsGrid(context, responsive, primary),
                  ),

                  SizedBox(
                    height: responsive.value(
                      mobile: 24,
                      tablet: 28,
                      desktop: 32,
                    ),
                  ),

                  _buildSectionTitle(
                    responsive,
                    primary,
                    "Resources & Support",
                    Icons.dashboard_customize_rounded,
                  ),

                  SizedBox(
                    height: responsive.value(
                      mobile: 14,
                      tablet: 18,
                      desktop: 22,
                    ),
                  ),

                  _buildResourceCards(context, responsive, primary),

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
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0,
        onTabSelected: (index) {
          if (index != 0) Navigator.pop(context);
        },
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

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

  // ── Summary stats ──────────────────────────────────────────────────────────

  Widget _buildSummaryGrid(BuildContext context, Responsive responsive) {
    final crossAxisCount = responsive
        .value(mobile: 2, tablet: 4, desktop: 4)
        .toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = responsive.value(mobile: 10, tablet: 12, desktop: 14);
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;

        // Show shimmer-style placeholder while loading
        final totalValue = _statsLoading ? "—" : _totalReports.toString();
        final premiumValue = _statsLoading ? "—" : _premiumGrades.toString();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _summaryCard(
                responsive,
                title: "Total Reports",
                value: totalValue,
                icon: Icons.assignment_rounded,
                color: Colors.blue,
                isLoading: _statsLoading,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _summaryCard(
                responsive,
                title: "Premium Grades",
                value: premiumValue,
                icon: Icons.star_rounded,
                color: Colors.amber,
                isLoading: _statsLoading,
              ),
            ),
          ],
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
    bool isLoading = false,
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
          isLoading
              ? SizedBox(
                  width: 32,
                  height: responsive.value(mobile: 15, tablet: 16, desktop: 18),
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(4),
                    color: color,
                    backgroundColor: color.withOpacity(0.15),
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: responsive.value(
                        mobile: 15,
                        tablet: 16,
                        desktop: 18,
                      ),
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

  // ── Action cards grid ──────────────────────────────────────────────────────

  Widget _buildActionCardsGrid(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    final crossAxisCount = responsive
        .value(mobile: 2, tablet: 2, desktop: 4)
        .toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = responsive.value(mobile: 12, tablet: 16, desktop: 20);
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) /
            crossAxisCount;

        final cards = _buildActionCards(context, responsive, primary);

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

  List<Widget> _buildActionCards(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    return [
      _featureCard(
        context,
        responsive,
        title: "New Quality\nCheck",
        subtitle: "Start grading",
        iconData: Icons.add_circle_outline_rounded,
        iconBgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BatchDetailsScreen()),
        ),
      ),
      _featureCard(
        context,
        responsive,
        title: "Past\nReports",
        subtitle: "View history",
        iconData: Icons.history_rounded,
        iconBgColor: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1565C0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PastReportsScreen()),
        ),
      ),
      _featureCard(
        context,
        responsive,
        title: "How It\nWorks",
        subtitle: "Learn process",
        iconData: Icons.school_rounded,
        iconBgColor: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFE65100),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
        ),
      ),
      _featureCard(
        context,
        responsive,
        title: "Quality\nTips",
        subtitle: "Improve grade",
        iconData: Icons.lightbulb_outline_rounded,
        iconBgColor: const Color(0xFFFCE4EC),
        iconColor: const Color(0xFFC62828),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QualityTipsMainScreen()),
        ),
      ),
    ];
  }

  Widget _featureCard(
    BuildContext context,
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
                // Icon container
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

                // Title
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

                // Subtitle
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

                // Arrow
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

  // ── Resource cards ─────────────────────────────────────────────────────────

  Widget _buildResourceCards(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    return Column(
      children: [
        _resourceCard(
          responsive,
          title: "IoT Device Setup",
          description: "Connect your ESP32 bulk density device",
          icon: Icons.bluetooth_rounded,
          color: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const IotDeviceSetupScreen()),
          ),
        ),
        SizedBox(height: responsive.value(mobile: 8, tablet: 10, desktop: 12)),
        _resourceCard(
          responsive,
          title: "Image Capture Guide",
          description: "Learn how to capture quality images",
          icon: Icons.camera_alt_rounded,
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ImageCaptureGuideScreen()),
          ),
        ),
        SizedBox(height: responsive.value(mobile: 8, tablet: 10, desktop: 12)),
        _resourceCard(
          responsive,
          title: "Certification",
          description: "Upload and verify your certificates",
          icon: Icons.verified_rounded,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FarmerCertificationsDashboardScreen(),
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

  // ── Dialog ─────────────────────────────────────────────────────────────────

  void _showQuickGuideDialog(BuildContext context, Responsive responsive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Colors.green.shade600),
            const SizedBox(width: 12),
            const Text("Quick Guide"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _guideStep("1", "Connect IoT device via Bluetooth"),
            _guideStep("2", "Capture 9 images of pepper samples"),
            _guideStep("3", "Upload certificates (if available)"),
            _guideStep("4", "Receive AI-powered quality report"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Got it",
              style: TextStyle(color: Color(0xFF43A047)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.green.shade100,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
