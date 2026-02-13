import 'package:CeylonPepper/features/quality_grading/screens/quality_grading_dashboard.dart';
import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import '../../market_forecast/navigation.dart';
import 'batch_details_screen.dart';
import 'how_it_works_screen.dart';

class ResultSummaryScreen extends StatefulWidget {
  const ResultSummaryScreen({super.key});

  @override
  State<ResultSummaryScreen> createState() => _ResultSummaryScreenState();
}

class _ResultSummaryScreenState extends State<ResultSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // COMPLETE IMPROVED VERSION - Replace entire build method content

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    const primary = Color(0xFF2E7D32);

    return WillPopScope(
      onWillPop: () async {
        // Navigate back to dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QualityGradingDashboard(),
                ),
              );
            },
          ),

          title: const Text(
            'Quality Report',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: 'Share report',
              onPressed: () {
                // TODO: Share functionality
              },
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.pagePadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IMPROVED GRADE CARD - More Balanced Design
                        Container(
                          width: double.infinity,
                          padding: responsive.padding(
                            mobile: const EdgeInsets.all(24),
                            tablet: const EdgeInsets.all(28),
                            desktop: const EdgeInsets.all(32),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Grade Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: responsive.padding(
                                      mobile: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      tablet: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 10,
                                      ),
                                      desktop: const EdgeInsets.symmetric(
                                        horizontal: 28,
                                        vertical: 12,
                                      ),
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade600,
                                          Colors.green.shade700,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.shade700.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.stars_rounded,
                                          color: Colors.white,
                                          size: responsive.value(
                                            mobile: 18,
                                            tablet: 20,
                                            desktop: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "PREMIUM",
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(
                                              mobile: 16,
                                              tablet: 18,
                                              desktop: 20,
                                            ),
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                              // Score Display
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Score Circle
                                  Container(
                                    width: responsive.value(
                                      mobile: 140,
                                      tablet: 160,
                                      desktop: 180,
                                    ),
                                    height: responsive.value(
                                      mobile: 140,
                                      tablet: 160,
                                      desktop: 180,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.shade50,
                                          Colors.green.shade100,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: Colors.green.shade300,
                                        width: 3,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "92",
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(
                                              mobile: 48,
                                              tablet: 56,
                                              desktop: 64,
                                            ),
                                            fontWeight: FontWeight.w800,
                                            color: Colors.green.shade700,
                                            height: 1,
                                          ),
                                        ),
                                        Text(
                                          "/ 100",
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(
                                              mobile: 16,
                                              tablet: 18,
                                              desktop: 20,
                                            ),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                              Text(
                                "Overall Quality Score",
                                style: TextStyle(
                                  fontSize: responsive.titleFontSize,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),

                        // Batch Information Section
                        _buildSectionHeader(
                          responsive,
                          primary,
                          'Batch Information',
                          Icons.info_rounded,
                        ),

                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(responsive, 'Pepper Type', 'Black Pepper', Icons.grass_rounded),
                              _buildDivider(responsive),
                              _buildInfoRow(responsive, 'Pepper Variety', 'Ceylon Pepper', Icons.local_florist_rounded),
                              _buildDivider(responsive),
                              _buildInfoRow(responsive, 'Drying Method', 'Sun Dried', Icons.wb_sunny_rounded),
                              _buildDivider(responsive),
                              _buildInfoRow(responsive, 'Harvest Date', '12 Aug 2025', Icons.calendar_today_rounded),
                              _buildDivider(responsive),
                              _buildInfoRow(responsive, 'Batch Weight', '25 kg', Icons.scale_rounded),
                              _buildDivider(responsive),
                              _buildInfoRow(responsive, 'Bulk Density', '540 g/L', Icons.science_rounded),
                              _buildDivider(responsive),
                              _buildInfoRow(responsive, 'Certificates', 'GAP, Quality Certificate', Icons.verified_rounded, isLast: true),
                            ],
                          ),
                        ),

                        ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),

                        // Quality Breakdown Section
                        _buildSectionHeader(
                          responsive,
                          primary,
                          'Quality Breakdown',
                          Icons.analytics_rounded,
                        ),

                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                        Container(
                          padding: responsive.padding(
                            mobile: const EdgeInsets.all(20),
                            tablet: const EdgeInsets.all(24),
                            desktop: const EdgeInsets.all(28),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildScoreBar(responsive, 'Size / Pinheads', 92, Colors.green),
                              _buildScoreBar(responsive, 'Color Uniformity', 88, Colors.blue),
                              _buildScoreBar(responsive, 'Surface Defects', 94, Colors.purple),
                              _buildScoreBar(responsive, 'Extraneous Matter', 98, Colors.orange),
                              _buildScoreBar(responsive, 'Adulteration', 100, Colors.teal),
                              _buildScoreBar(responsive, 'Uniformity', 90, Colors.indigo, isLast: true),
                            ],
                          ),
                        ),

                        ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),

                        // Improvement Suggestions Section
                        _buildSectionHeader(
                          responsive,
                          primary,
                          'Improvement Suggestions',
                          Icons.lightbulb_rounded,
                        ),

                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                        Container(
                          padding: responsive.padding(
                            mobile: const EdgeInsets.all(20),
                            tablet: const EdgeInsets.all(24),
                            desktop: const EdgeInsets.all(28),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSuggestionItem(
                                responsive,
                                'Ensure uniform drying to improve color score',
                                Icons.wb_sunny_rounded,
                              ),
                              ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                              _buildSuggestionItem(
                                responsive,
                                'Remove broken berries before packing',
                                Icons.cleaning_services_rounded,
                              ),
                            ],
                          ),
                        ),

                        ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                        // NEW: Quick Actions Section
                        _buildSectionHeader(
                          responsive,
                          primary,
                          'Next Steps',
                          Icons.explore_rounded,
                        ),

                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                        // Quick action cards in a grid
                        _buildQuickActionsGrid(context, responsive, primary),

                        ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                        // Action Buttons
                        Container(
                          width: double.infinity,
                          height: responsive.buttonHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Download PDF
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.download_rounded,
                                  size: responsive.smallIconSize,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Download Report (PDF)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: responsive.titleFontSize,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                        Container(
                          width: double.infinity,
                          height: responsive.buttonHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: primary, width: 2),
                          ),
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HowItWorksScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.help_outline_rounded,
                                  size: responsive.smallIconSize,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "How is Quality Calculated?",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: responsive.titleFontSize,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// NEW METHOD: Quick Actions Grid
  Widget _buildQuickActionsGrid(BuildContext context, Responsive responsive, Color primary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                responsive,
                title: 'Check Market Price',
                subtitle: 'Get current rates',
                icon: Icons.trending_up_rounded,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PriceNavigation()),
                  );
                },
              ),
            ),
            ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
            Expanded(
              child: _buildQuickActionCard(
                context,
                responsive,
                title: 'Start New Test',
                subtitle: 'Grade another batch',
                icon: Icons.add_circle_outline_rounded,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BatchDetailsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

// NEW METHOD: Quick Action Card
  Widget _buildQuickActionCard(
      BuildContext context,
      Responsive responsive, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: responsive.padding(
            mobile: const EdgeInsets.all(14),
            tablet: const EdgeInsets.all(16),
            desktop: const EdgeInsets.all(18),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(
                  responsive.value(mobile: 8, tablet: 9, desktop: 10),
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: responsive.value(mobile: 22, tablet: 24, desktop: 26),
                ),
              ),
              ResponsiveSpacing(mobile: 10, tablet: 12, desktop: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              ResponsiveSpacing(mobile: 3, tablet: 4, desktop: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: responsive.bodyFontSize - 2,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      Responsive responsive,
      Color primary,
      String title,
      IconData icon,
      ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(
            responsive.value(mobile: 8, tablet: 9, desktop: 10),
          ),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primary,
            size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: responsive.headingFontSize - 2,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      Responsive responsive,
      String label,
      String value,
      IconData icon, {
        bool isLast = false,
      }) {
    return Padding(
      padding: responsive.padding(
        mobile: EdgeInsets.fromLTRB(16, 14, 16, isLast ? 14 : 0),
        tablet: EdgeInsets.fromLTRB(18, 16, 18, isLast ? 16 : 0),
        desktop: EdgeInsets.fromLTRB(20, 18, 20, isLast ? 18 : 0),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: responsive.smallIconSize,
            color: Colors.grey[600],
          ),
          ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Responsive responsive) {
    return Divider(
      height: 1,
      indent: responsive.value(mobile: 16, tablet: 18, desktop: 20),
      endIndent: responsive.value(mobile: 16, tablet: 18, desktop: 20),
    );
  }

  Widget _buildScoreBar(
      Responsive responsive,
      String label,
      int score,
      Color color, {
        bool isLast = false,
      }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : responsive.value(mobile: 20, tablet: 22, desktop: 24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.value(mobile: 10, tablet: 11, desktop: 12),
                  vertical: responsive.value(mobile: 4, tablet: 5, desktop: 6),
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(mobile: 8, tablet: 10, desktop: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: responsive.value(mobile: 8, tablet: 9, desktop: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(Responsive responsive, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: responsive.value(mobile: 6, tablet: 7, desktop: 8),
          height: responsive.value(mobile: 6, tablet: 7, desktop: 8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionItem(
      Responsive responsive,
      String text,
      IconData icon,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(
            responsive.value(mobile: 8, tablet: 9, desktop: 10),
          ),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade700,
            size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              color: Colors.blue.shade900,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

//v2
// import 'package:flutter/material.dart';
// import '../../../utils/responsive.dart';
//
// class ResultSummaryScreen extends StatefulWidget {
//   const ResultSummaryScreen({super.key});
//
//   @override
//   State<ResultSummaryScreen> createState() => _ResultSummaryScreenState();
// }
//
// class _ResultSummaryScreenState extends State<ResultSummaryScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//     );
//
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.2),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
//     );
//
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final responsive = context.responsive;
//     const primary = Color(0xFF2E7D32);
//
//     return WillPopScope(
//       onWillPop: () async {
//         return false;
//       },
//       child: Scaffold(
//         backgroundColor: Colors.grey[50],
//         appBar: AppBar(
//           backgroundColor: primary,
//           elevation: 0,
//           automaticallyImplyLeading: false,
//           title: const Text(
//             'Quality Report',
//             style: TextStyle(
//               fontWeight: FontWeight.w700,
//               color: Colors.white,
//             ),
//           ),
//           actions: [
//             IconButton(
//               icon: const Icon(Icons.history_rounded, color: Colors.white),
//               tooltip: 'Report history',
//               onPressed: () {
//                 // TODO: Show report history
//               },
//             ),
//             IconButton(
//               icon: const Icon(Icons.share_rounded, color: Colors.white),
//               tooltip: 'Share report',
//               onPressed: () {
//                 // TODO: Share functionality
//               },
//             ),
//           ],
//         ),
//         body: FadeTransition(
//           opacity: _fadeAnimation,
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
//
//                 // Main Content
//                 SlideTransition(
//                   position: _slideAnimation,
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: responsive.pagePadding,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Report Timestamp
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 6,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade200,
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 Icons.access_time_rounded,
//                                 size: 14,
//                                 color: Colors.grey.shade700,
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 'Report generated at 2:45 PM, Dec 30, 2024',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey.shade700,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
//
//                         // Grade Card
//                         Container(
//                           width: double.infinity,
//                           padding: responsive.padding(
//                             mobile: const EdgeInsets.all(24),
//                             tablet: const EdgeInsets.all(28),
//                             desktop: const EdgeInsets.all(32),
//                           ),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 Colors.green.shade50,
//                                 Colors.green.shade100.withOpacity(0.5),
//                               ],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(24),
//                             border: Border.all(
//                               color: Colors.green.shade300,
//                               width: 2,
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.green.withOpacity(0.2),
//                                 blurRadius: 20,
//                                 offset: const Offset(0, 8),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               Container(
//                                 padding: responsive.padding(
//                                   mobile: const EdgeInsets.symmetric(
//                                     horizontal: 20,
//                                     vertical: 8,
//                                   ),
//                                   tablet: const EdgeInsets.symmetric(
//                                     horizontal: 24,
//                                     vertical: 10,
//                                   ),
//                                   desktop: const EdgeInsets.symmetric(
//                                     horizontal: 28,
//                                     vertical: 12,
//                                   ),
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.green.shade700,
//                                   borderRadius: BorderRadius.circular(50),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.green.shade700.withOpacity(
//                                           0.3),
//                                       blurRadius: 8,
//                                       offset: const Offset(0, 2),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Text(
//                                   "Premium Grade A",
//                                   style: TextStyle(
//                                     fontSize: responsive.fontSize(
//                                       mobile: 20,
//                                       tablet: 22,
//                                       desktop: 24,
//                                     ),
//                                     fontWeight: FontWeight.w800,
//                                     color: Colors.white,
//                                     letterSpacing: 2,
//                                   ),
//                                 ),
//                               ),
//                               ResponsiveSpacing(
//                                   mobile: 20, tablet: 24, desktop: 28),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 crossAxisAlignment: CrossAxisAlignment.baseline,
//                                 textBaseline: TextBaseline.alphabetic,
//                                 children: [
//                                   Text(
//                                     "92",
//                                     style: TextStyle(
//                                       fontSize: responsive.fontSize(
//                                         mobile: 56,
//                                         tablet: 64,
//                                         desktop: 72,
//                                       ),
//                                       fontWeight: FontWeight.w800,
//                                       color: Colors.green.shade700,
//                                       height: 1,
//                                     ),
//                                   ),
//                                   Text(
//                                     " / 100",
//                                     style: TextStyle(
//                                       fontSize: responsive.fontSize(
//                                         mobile: 24,
//                                         tablet: 26,
//                                         desktop: 28,
//                                       ),
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.green.shade700,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               ResponsiveSpacing(
//                                   mobile: 8, tablet: 10, desktop: 12),
//                               Text(
//                                 "Overall Quality Score",
//                                 style: TextStyle(
//                                   fontSize: responsive.bodyFontSize,
//                                   color: Colors.green.shade900,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
//
//                         // Score Comparison
//                         Container(
//                           padding: responsive.padding(
//                             mobile: const EdgeInsets.all(16),
//                             tablet: const EdgeInsets.all(18),
//                             desktop: const EdgeInsets.all(20),
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.grey.shade200),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             children: [
//                               Expanded(
//                                 child: Column(
//                                   children: [
//                                     Text(
//                                       'Your Score',
//                                       style: TextStyle(
//                                         fontSize: responsive.bodyFontSize - 2,
//                                         color: Colors.grey.shade600,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       '92',
//                                       style: TextStyle(
//                                         fontSize: responsive.headingFontSize,
//                                         fontWeight: FontWeight.w800,
//                                         color: Colors.green.shade700,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Container(
//                                 width: 1,
//                                 height: 40,
//                                 color: Colors.grey.shade300,
//                               ),
//                               Expanded(
//                                 child: Column(
//                                   children: [
//                                     Text(
//                                       'Regional Avg',
//                                       style: TextStyle(
//                                         fontSize: responsive.bodyFontSize - 2,
//                                         color: Colors.grey.shade600,
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Row(
//                                       mainAxisAlignment: MainAxisAlignment
//                                           .center,
//                                       crossAxisAlignment: CrossAxisAlignment
//                                           .baseline,
//                                       textBaseline: TextBaseline.alphabetic,
//                                       children: [
//                                         Text(
//                                           '78',
//                                           style: TextStyle(
//                                             fontSize: responsive
//                                                 .headingFontSize - 4,
//                                             fontWeight: FontWeight.w700,
//                                             color: Colors.grey.shade600,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 6),
//                                         Container(
//                                           padding: const EdgeInsets.symmetric(
//                                             horizontal: 6,
//                                             vertical: 2,
//                                           ),
//                                           decoration: BoxDecoration(
//                                             color: Colors.green.shade100,
//                                             borderRadius: BorderRadius.circular(
//                                                 4),
//                                           ),
//                                           child: Text(
//                                             '+14',
//                                             style: TextStyle(
//                                               fontSize: 11,
//                                               fontWeight: FontWeight.w700,
//                                               color: Colors.green.shade700,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
//
//                         // Buyer Notification
//                         Container(
//                           padding: responsive.padding(
//                             mobile: const EdgeInsets.all(16),
//                             tablet: const EdgeInsets.all(18),
//                             desktop: const EdgeInsets.all(20),
//                           ),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 Colors.amber.shade50,
//                                 Colors.amber.shade100.withOpacity(0.5),
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.amber.shade200),
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(10),
//                                 decoration: BoxDecoration(
//                                   color: Colors.amber.shade100,
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                                 child: Icon(
//                                   Icons.notifications_active_rounded,
//                                   color: Colors.amber.shade700,
//                                   size: 22,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   '3 exporters notified about your premium batch!',
//                                   style: TextStyle(
//                                     fontSize: responsive.bodyFontSize,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.amber.shade900,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
//
//                         // How Was This Calculated
//                         Container(
//                           padding: responsive.padding(
//                             mobile: const EdgeInsets.all(16),
//                             tablet: const EdgeInsets.all(18),
//                             desktop: const EdgeInsets.all(20),
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.blue.shade50,
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(color: Colors.blue.shade200),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(
//                                     Icons.info_outline_rounded,
//                                     color: Colors.blue.shade700,
//                                     size: 20,
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Text(
//                                     'How was this calculated?',
//                                     style: TextStyle(
//                                       fontSize: responsive.bodyFontSize,
//                                       fontWeight: FontWeight.w700,
//                                       color: Colors.blue.shade900,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               Text(
//                                 'Your score combines:',
//                                 style: TextStyle(
//                                   fontSize: responsive.bodyFontSize - 1,
//                                   color: Colors.blue.shade800,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               _buildBulletPoint(
//                                 responsive,
//                                 'IoT density measurement (20 points)',
//                                 Colors.blue.shade700,
//                               ),
//                               const SizedBox(height: 6),
//                               _buildBulletPoint(
//                                 responsive,
//                                 'AI image analysis (70 points)',
//                                 Colors.blue.shade700,
//                               ),
//                               const SizedBox(height: 6),
//                               _buildBulletPoint(
//                                 responsive,
//                                 'GAP certification bonus (4 points)',
//                                 Colors.blue.shade700,
//                               ),
//                               const SizedBox(height: 8),
//                               TextButton(
//                                 onPressed: () {
//                                   // TODO: Show detailed rubric
//                                 },
//                                 style: TextButton.styleFrom(
//                                   padding: EdgeInsets.zero,
//                                   minimumSize: Size.zero,
//                                   tapTargetSize: MaterialTapTargetSize
//                                       .shrinkWrap,
//                                 ),
//                                 child: Text(
//                                   'View detailed scoring rubric →',
//                                   style: TextStyle(
//                                     fontSize: responsive.bodyFontSize - 1,
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.blue.shade700,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),
//
//                         // Batch Information Section
//                         _buildSectionHeader(
//                           responsive,
//                           primary,
//                           'Batch Information',
//                           Icons.info_rounded,
//                         ),
//
//                         ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
//
//                         Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(color: Colors.grey.shade200),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               _buildInfoRow(
//                                   responsive, 'Pepper Type', 'Black Pepper',
//                                   Icons.grass_rounded),
//                               _buildDivider(responsive),
//                               _buildInfoRow(
//                                   responsive, 'Pepper Variety', 'Ceylon Pepper',
//                                   Icons.local_florist_rounded),
//                               _buildDivider(responsive),
//                               _buildInfoRow(
//                                   responsive, 'Est. Piperine', '11% (Ceylon)',
//                                   Icons.science_rounded),
//                               _buildDivider(responsive),
//                               _buildInfoRow(
//                                   responsive, 'Drying Method', 'Sun Dried',
//                                   Icons.wb_sunny_rounded),
//                               _buildDivider(responsive),
//                               _buildInfoRow(
//                                   responsive, 'Harvest Date', '12 Aug 2025',
//                                   Icons.calendar_today_rounded),
//                               _buildDivider(responsive),
//                               _buildInfoRow(responsive, 'Batch Weight', '25 kg',
//                                   Icons.scale_rounded),
//                               _buildDivider(responsive),
//                               _buildInfoRow(
//                                   responsive, 'Bulk Density', '540 g/L',
//                                   Icons.science_rounded),
//                               _buildDivider(responsive),
//                               _buildInfoRow(
//                                   responsive, 'Device ID', 'ESP32-A472',
//                                   Icons.router_rounded),
//                               _buildDivider(responsive),
//                               _buildInfoRow(
//                                   responsive, 'Measurement Time', '2:34 PM',
//                                   Icons.access_time_rounded),
//                               _buildDivider(responsive),
//                               _buildInfoRow(responsive, 'Certificates',
//                                   'GAP, Quality Certificate',
//                                   Icons.verified_rounded, isLast: true),
//                             ],
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),
//
//                         // Quality Breakdown Section
//                         _buildSectionHeader(
//                           responsive,
//                           primary,
//                           'Quality Breakdown',
//                           Icons.analytics_rounded,
//                         ),
//
//                         ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
//
//                         Container(
//                           padding: responsive.padding(
//                             mobile: const EdgeInsets.all(20),
//                             tablet: const EdgeInsets.all(24),
//                             desktop: const EdgeInsets.all(28),
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(color: Colors.grey.shade200),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               _buildScoreBar(
//                                   responsive, 'Bulk Density (IoT)', 95,
//                                   Colors.green, 'High'),
//                               _buildScoreBar(
//                                   responsive, 'Piperine Content (Est.)', 100,
//                                   Colors.deepPurple, 'Medium'),
//                               _buildScoreBar(
//                                   responsive, 'Color Uniformity (AI)', 88,
//                                   Colors.blue, 'High'),
//                               _buildScoreBar(
//                                   responsive, 'Size / Pinheads (AI)', 92,
//                                   Colors.teal, 'High'),
//                               _buildScoreBar(
//                                   responsive, 'Surface Texture (AI)', 94,
//                                   Colors.indigo, 'High'),
//                               _buildScoreBar(
//                                   responsive, 'Mold Presence (AI)', 98,
//                                   Colors.red, 'High'),
//                               _buildScoreBar(
//                                   responsive, 'Extraneous Matter (AI)', 98,
//                                   Colors.orange, 'High'),
//                               _buildScoreBar(
//                                   responsive, 'Adulteration (AI)', 100,
//                                   Colors.pink, 'High'),
//                               _buildScoreBar(
//                                   responsive, 'Insect Damage (AI)', 96,
//                                   Colors.brown, 'High'),
//                               _buildScoreBar(
//                                   responsive, 'GAP Certification', 100,
//                                   Colors.green, 'Verified', isLast: true),
//                             ],
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),
//
//                         // AI Detection Results
//                         _buildSectionHeader(
//                           responsive,
//                           primary,
//                           'AI Detection Results',
//                           Icons.image_search_rounded,
//                         ),
//
//                         ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
//
//                         Container(
//                           padding: responsive.padding(
//                             mobile: const EdgeInsets.all(20),
//                             tablet: const EdgeInsets.all(24),
//                             desktop: const EdgeInsets.all(28),
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(color: Colors.grey.shade200),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Sample Images Analyzed',
//                                 style: TextStyle(
//                                   fontSize: responsive.bodyFontSize,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.grey.shade800,
//                                 ),
//                               ),
//                               const SizedBox(height: 12),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: Container(
//                                       height: 80,
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey.shade200,
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: Icon(
//                                         Icons.image_rounded,
//                                         color: Colors.grey.shade400,
//                                         size: 32,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Container(
//                                       height: 80,
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey.shade200,
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: Icon(
//                                         Icons.image_rounded,
//                                         color: Colors.grey.shade400,
//                                         size: 32,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Container(
//                                       height: 80,
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey.shade200,
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: Icon(
//                                         Icons.image_rounded,
//                                         color: Colors.grey.shade400,
//                                         size: 32,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 16),
//                               _buildDetectionItem(
//                                 responsive,
//                                 'Mold detected on 2 berries (1.2%)',
//                                 Icons.warning_rounded,
//                                 Colors.orange,
//                               ),
//                               const SizedBox(height: 12),
//                               _buildDetectionItem(
//                                 responsive,
//                                 'Insect damage found on 1 berry (0.6%)',
//                                 Icons.bug_report_rounded,
//                                 Colors.red,
//                               ),
//                               const SizedBox(height: 12),
//                               _buildDetectionItem(
//                                 responsive,
//                                 'No adulteration detected',
//                                 Icons.check_circle_rounded,
//                                 Colors.green,
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),
//
//                         // Improvement Suggestions Section
//                         _buildSectionHeader(
//                           responsive,
//                           primary,
//                           'Improvement Suggestions',
//                           Icons.lightbulb_rounded,
//                         ),
//
//                         ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
//
//                         Container(
//                           padding: responsive.padding(
//                             mobile: const EdgeInsets.all(20),
//                             tablet: const EdgeInsets.all(24),
//                             desktop: const EdgeInsets.all(28),
//                           ),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 Colors.blue.shade50,
//                                 Colors.blue.shade100.withOpacity(0.5),
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(color: Colors.blue.shade200),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               _buildSuggestionItem(
//                                 responsive,
//                                 'Ensure uniform drying to improve color score',
//                                 Icons.wb_sunny_rounded,
//                                 'Watch Drying Guide',
//                               ),
//                               ResponsiveSpacing(
//                                   mobile: 16, tablet: 18, desktop: 20),
//                               _buildSuggestionItem(
//                                 responsive,
//                                 'Remove broken berries before packing',
//                                 Icons.cleaning_services_rounded,
//                                 'View Best Practices',
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),
//
//                         // Traceability QR Code
//                         _buildSectionHeader(
//                           responsive,
//                           primary,
//                           'Blockchain Traceability',
//                           Icons.qr_code_rounded,
//                         ),
//
//                         ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
//
//                         Container(
//                           padding: responsive.padding(
//                             mobile: const EdgeInsets.all(20),
//                             tablet: const EdgeInsets.all(24),
//                             desktop: const EdgeInsets.all(28),
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(color: Colors.grey.shade200),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.black.withOpacity(0.05),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 2),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             children: [
//                               Container(
//                                 width: 150,
//                                 height: 150,
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey.shade200,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Icon(
//                                   Icons.qr_code_2_rounded,
//                                   size: 80,
//                                   color: Colors.grey.shade400,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               Text(
//                                 'Scan to verify batch on blockchain',
//                                 style: TextStyle(
//                                   fontSize: responsive.bodyFontSize,
//                                   color: Colors.grey.shade700,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                                 textAlign: TextAlign.center,
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Batch ID: BP-2025-A472-001',
//                                 style: TextStyle(
//                                   fontSize: responsive.bodyFontSize - 2,
//                                   color: Colors.grey.shade600,
//                                   fontFamily: 'monospace',
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
//
//                         // Action Buttons
//                         Container(
//                           width: double.infinity,
//                           height: responsive.buttonHeight,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(28),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: primary.withOpacity(0.3),
//                                 blurRadius: 20,
//                                 offset: const Offset(0, 10),
//                               ),
//                             ],
//                           ),
//                           child: ElevatedButton(
//                             onPressed: () {
//                               // TODO: Download PDF
//                             },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: primary,
//                               foregroundColor: Colors.white,
//                               elevation: 0,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(28),
//                               ),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   Icons.download_rounded,
//                                   size: responsive.smallIconSize,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   "Download Report (PDF)",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: responsive.titleFontSize,
//                                     letterSpacing: 0.5,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
//
//                         Container(
//                           width: double.infinity,
//                           height: responsive.buttonHeight,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(28),
//                             border: Border.all(color: primary, width: 2),
//                           ),
//                           child: OutlinedButton(
//                             onPressed: () {
//                               // TODO: View grading algorithm
//                             },
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: primary,
//                               side: BorderSide.none,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(28),
//                               ),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   Icons.info_outline_rounded,
//                                   size: responsive.smallIconSize,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   "View Grading Algorithm",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: responsive.titleFontSize,
//                                     letterSpacing: 0.5,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//
//                         ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(Responsive responsive,
//       Color primary,
//       String title,
//       IconData icon,) {
//     return Row(
//       children: [
//         Container(
//           padding: EdgeInsets.all(
//             responsive.value(mobile: 8, tablet: 9, desktop: 10),
//           ),
//           decoration: BoxDecoration(
//             color: primary.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(
//             icon,
//             color: primary,
//             size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
//           ),
//         ),
//         ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: responsive.headingFontSize - 2,
//             fontWeight: FontWeight.w700,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildInfoRow(Responsive responsive,
//       String label,
//       String value,
//       IconData icon, {
//         bool isLast = false,
//       }) {
//     return Padding(
//       padding: responsive.padding(
//         mobile: EdgeInsets.fromLTRB(16, 14, 16, isLast ? 14 : 0),
//         tablet: EdgeInsets.fromLTRB(18, 16, 18, isLast ? 16 : 0),
//         desktop: EdgeInsets.fromLTRB(20, 18, 20, isLast ? 18 : 0),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             size: responsive.smallIconSize,
//             color: Colors.grey[600],
//           ),
//           ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
//           Expanded(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: responsive.bodyFontSize,
//                 color: Colors.grey[700],
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           Flexible(
//             child: Text(
//               value,
//               textAlign: TextAlign.end,
//               style: TextStyle(
//                 fontSize: responsive.bodyFontSize,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.black87,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDivider(Responsive responsive) {
//     return Divider(
//       height: 1,
//       indent: responsive.value(mobile: 16, tablet: 18, desktop: 20),
//       endIndent: responsive.value(mobile: 16, tablet: 18, desktop: 20),
//     );
//   }
//
//   Widget _buildScoreBar(Responsive responsive,
//       String label,
//       int score,
//       Color color,
//       String confidence, {
//         bool isLast = false,
//       }) {
//     return Padding(
//       padding: EdgeInsets.only(
//         bottom: isLast ? 0 : responsive.value(
//             mobile: 20, tablet: 22, desktop: 24),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Expanded(
//                 child: Text(
//                   label,
//                   style: TextStyle(
//                     fontSize: responsive.bodyFontSize,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: confidence == 'High' || confidence == 'Verified'
//                       ? Colors.green.withOpacity(0.1)
//                       : Colors.orange.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       confidence == 'High' || confidence == 'Verified'
//                           ? Icons.check_circle
//                           : Icons.info,
//                       size: 12,
//                       color: confidence == 'High' || confidence == 'Verified'
//                           ? Colors.green
//                           : Colors.orange,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       confidence,
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                         color: confidence == 'High' || confidence == 'Verified'
//                             ? Colors.green.shade700
//                             : Colors.orange.shade700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: responsive.value(
//                       mobile: 10, tablet: 11, desktop: 12),
//                   vertical: responsive.value(mobile: 4, tablet: 5, desktop: 6),
//                 ),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   '$score',
//                   style: TextStyle(
//                     fontSize: responsive.bodyFontSize,
//                     fontWeight: FontWeight.w700,
//                     color: color,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           ResponsiveSpacing(mobile: 8, tablet: 10, desktop: 12),
//           ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: LinearProgressIndicator(
//               value: score / 100,
//               backgroundColor: color.withOpacity(0.1),
//               valueColor: AlwaysStoppedAnimation<Color>(color),
//               minHeight: responsive.value(mobile: 8, tablet: 9, desktop: 10),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBulletPoint(Responsive responsive, String text, Color color) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           margin: const EdgeInsets.only(top: 6),
//           width: responsive.value(mobile: 6, tablet: 7, desktop: 8),
//           height: responsive.value(mobile: 6, tablet: 7, desktop: 8),
//           decoration: BoxDecoration(
//             color: color,
//             shape: BoxShape.circle,
//           ),
//         ),
//         ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
//         Expanded(
//           child: Text(
//             text,
//             style: TextStyle(
//               fontSize: responsive.bodyFontSize - 1,
//               color: Colors.blue.shade800,
//               height: 1.5,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSuggestionItem(Responsive responsive,
//       String text,
//       IconData icon,
//       String actionLabel,) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           padding: EdgeInsets.all(
//             responsive.value(mobile: 8, tablet: 9, desktop: 10),
//           ),
//           decoration: BoxDecoration(
//             color: Colors.blue.shade100,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(
//             icon,
//             color: Colors.blue.shade700,
//             size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
//           ),
//         ),
//         ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 text,
//                 style: TextStyle(
//                   fontSize: responsive.bodyFontSize,
//                   color: Colors.blue.shade900,
//                   fontWeight: FontWeight.w500,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               InkWell(
//                 onTap: () {
//                   // TODO: Open guide/tutorial
//                 },
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       actionLabel,
//                       style: TextStyle(
//                         fontSize: responsive.bodyFontSize - 2,
//                         color: Colors.blue.shade700,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(width: 4),
//                     Icon(
//                       Icons.arrow_forward_rounded,
//                       size: 14,
//                       color: Colors.blue.shade700,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDetectionItem(Responsive responsive,
//       String text,
//       IconData icon,
//       Color color,) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(
//             icon,
//             color: color,
//             size: 16,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Text(
//             text,
//             style: TextStyle(
//               fontSize: responsive.bodyFontSize - 1,
//               color: Colors.grey.shade700,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }