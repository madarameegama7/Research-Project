import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import '../../../widgets/bottom_navigation.dart';
import 'batch_details_screen.dart';
import 'how_it_works_screen.dart';
import 'image_capture_guide_screen.dart';
import 'iot_device_setup_screen.dart';
import 'past_reports_screen.dart';
import 'quality_tips_main_screen.dart';

class QualityGradingDashboard extends StatefulWidget {
  const QualityGradingDashboard({super.key});

  @override
  State<QualityGradingDashboard> createState() => _QualityGradingDashboardState();
}

class _QualityGradingDashboardState extends State<QualityGradingDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final int totalReports = 24;
  final int premiumGrades = 8;

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),

                    // Summary Statistics Cards
                    _buildSummaryGrid(context, responsive),

                    SizedBox(height: responsive.value(mobile: 20, tablet: 24, desktop: 28)),

                    // Main Action Cards
                    Text(
                      "Grading Actions",
                      style: TextStyle(
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: responsive.value(mobile: 10, tablet: 12, desktop: 16)),
                    _buildActionCardsGrid(context, responsive, primary),

                    SizedBox(height: responsive.value(mobile: 20, tablet: 24, desktop: 28)),

                    // Educational Resources Section
                    Text(
                      "Resources & Support",
                      style: TextStyle(
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: responsive.value(mobile: 10, tablet: 12, desktop: 16)),
                    _buildResourceCards(context, responsive, primary),

                    SizedBox(height: responsive.value(mobile: 24, tablet: 32, desktop: 40)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 2, // Quality tab is index 2
        onTabSelected: (index) {
          // Handle navigation based on index
          if (index != 2) { // If not already on Quality tab
            Navigator.pop(context); // Go back and let NavigationWrapper handle it
          }
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final responsive = context.responsive;
    const primary = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: responsive.value(mobile: 16, tablet: 20, desktop: 24)),

                    // Summary Statistics Cards - NOW WITH ALL 4 CARDS
                    _buildSummaryGrid(context, responsive),

                    SizedBox(height: responsive.value(mobile: 20, tablet: 24, desktop: 28)),

                    // Main Action Cards
                    Text(
                      "Grading Actions",
                      style: TextStyle(
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: responsive.value(mobile: 10, tablet: 12, desktop: 16)),
                    _buildActionCardsGrid(context, responsive, primary),

                    SizedBox(height: responsive.value(mobile: 20, tablet: 24, desktop: 28)),

                    // Educational Resources Section
                    Text(
                      "Resources & Support",
                      style: TextStyle(
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: responsive.value(mobile: 10, tablet: 12, desktop: 16)),
                    _buildResourceCards(context, responsive, primary),

                    SizedBox(height: responsive.value(mobile: 24, tablet: 32, desktop: 40)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, Responsive responsive) {
    final crossAxisCount = responsive.value(mobile: 2, tablet: 4, desktop: 4).toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = responsive.value(mobile: 10, tablet: 12, desktop: 14);
        final itemWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final itemHeight = responsive.value(mobile: 100, tablet: 115, desktop: 125);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _summaryCard(
                responsive,
                title: "Total Reports",
                value: totalReports.toString(),
                icon: Icons.assignment_rounded,
                color: Colors.blue,
              ),
            ),
            SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _summaryCard(
                responsive,
                title: "Premium Grades",
                value: premiumGrades.toString(),
                icon: Icons.star_rounded,
                color: Colors.amber,
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
      }) {
    return Container(
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
      padding: EdgeInsets.all(responsive.value(mobile: 10, tablet: 12, desktop: 14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(responsive.value(mobile: 7, tablet: 8, desktop: 9)),
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

  Widget _buildActionCardsGrid(BuildContext context, Responsive responsive, Color primary) {
    final crossAxisCount = responsive.value(mobile: 2, tablet: 2, desktop: 4).toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = responsive.value(mobile: 10, tablet: 12, desktop: 16);
        final itemWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final itemHeight = responsive.value(mobile: 140, tablet: 155, desktop: 150);

        final actionCards = _buildActionCards(context, responsive, primary);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actionCards.map((card) {
            return SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: card,
            );
          }).toList(),
        );
      },
    );
  }

  List<Widget> _buildActionCards(BuildContext context, Responsive responsive, Color primary) {
    return [
      _actionCard(
        context,
        responsive,
        title: "New Quality\nCheck",
        subtitle: "Start grading",
        icon: Icons.add_circle_outline,
        gradient: LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BatchDetailsScreen()),
          );
        },
      ),
      _actionCard(
        context,
        responsive,
        title: "Past\nReports",
        subtitle: "View history",
        icon: Icons.history_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PastReportsScreen(),
            ),
          );
        },
      ),
      _actionCard(
        context,
        responsive,
        title: "How It\nWorks",
        subtitle: "Learn process",
        icon: Icons.school_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF81C784), Color(0xFF66BB6A)],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const HowItWorksScreen(),
            ),
          );
        },
      ),
      _actionCard(
        context,
        responsive,
        title: "Quality\nTips",
        subtitle: "Improve grade",
        icon: Icons.lightbulb_outline_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF388E3C), Color(0xFF2E7D32)],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QualityTipsMainScreen()),
          );
        },
      ),
    ];
  }

  Widget _actionCard(
      BuildContext context,
      Responsive responsive, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Gradient gradient,
        required Function onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(
              responsive.value(mobile: 16, tablet: 18, desktop: 20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                bottom: -12,
                child: Icon(
                  icon,
                  size: responsive.value(mobile: 65, tablet: 75, desktop: 85),
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(responsive.value(mobile: 12, tablet: 14, desktop: 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(responsive.value(mobile: 7, tablet: 8, desktop: 9)),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: responsive.value(mobile: 20, tablet: 24, desktop: 28),
                        color: Colors.white,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: responsive.value(mobile: 14, tablet: 15, desktop: 16),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: responsive.value(mobile: 3, tablet: 4, desktop: 5)),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: responsive.value(mobile: 11, tablet: 12, desktop: 13),
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white.withOpacity(0.95),
                              size: responsive.value(mobile: 13, tablet: 15, desktop: 17),
                            ),
                          ],
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

  Widget _buildResourceCards(BuildContext context, Responsive responsive, Color primary) {
    return Column(
      children: [
        _resourceCard(
          responsive,
          title: "IoT Device Setup",
          description: "Connect your ESP32 bulk density device",
          icon: Icons.bluetooth_rounded,
          color: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IotDeviceSetupScreen()),
              );
            }
        ),
        SizedBox(height: responsive.value(mobile: 8, tablet: 10, desktop: 12)),
        _resourceCard(
          responsive,
          title: "Image Capture Guide",
          description: "Learn how to capture quality images",
          icon: Icons.camera_alt_rounded,
          color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImageCaptureGuideScreen()),
              );
            }
        ),
        SizedBox(height: responsive.value(mobile: 8, tablet: 10, desktop: 12)),
        _resourceCard(
          responsive,
          title: "Certification",
          description: "Upload and verify your certificates",
          icon: Icons.verified_rounded,
          color: Colors.green,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Opening certification...")),
            );
          },
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(responsive.value(mobile: 12, tablet: 14, desktop: 16)),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsive.value(mobile: 9, tablet: 10, desktop: 11)),
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
              SizedBox(width: responsive.value(mobile: 10, tablet: 12, desktop: 14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: responsive.value(mobile: 14, tablet: 15, desktop: 16),
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: responsive.value(mobile: 2, tablet: 3, desktop: 4)),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: responsive.value(mobile: 11, tablet: 12, desktop: 13),
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6),
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

  // Dialog methods remain the same but I'll include them for completeness
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
            child: const Text("Got it", style: TextStyle(color: Color(0xFF43A047))),
          ),
        ],
      ),
    );
  }

  void _showHowItWorksDialog(BuildContext context, Responsive responsive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.school_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            const Text("How It Works"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Our AI-powered system evaluates pepper quality using:",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _featureItem(Icons.scale_rounded, "Bulk Density", "IoT device measures density (g/L)"),
              _featureItem(Icons.visibility_rounded, "Visual Analysis", "AI detects mold, defects, adulteration"),
              _featureItem(Icons.science_rounded, "Piperine Estimation", "Variety-based quality indicator"),
              _featureItem(Icons.verified_rounded, "GAP Validation", "Certificate verification for buyers"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showQualityTipsDialog(BuildContext context, Responsive responsive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: Colors.purple.shade600),
            const SizedBox(width: 12),
            const Text("Quality Tips"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tipItem("Ensure proper sun drying (3-4 days)"),
              _tipItem("Remove light berries and pinheads"),
              _tipItem("Store in cool, dry place to prevent mold"),
              _tipItem("Avoid mixing varieties during drying"),
              _tipItem("Sort by size before packaging"),
              _tipItem("Get GAP certification for premium prices"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  // Helper widgets
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
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.purple.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              number.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}