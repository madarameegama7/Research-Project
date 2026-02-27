import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';

class DetailedReportScreen extends StatefulWidget {
  const DetailedReportScreen({super.key});

  @override
  State<DetailedReportScreen> createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends State<DetailedReportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
          'Report Details',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing report...')),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grade Header Card
                    _buildGradeCard(responsive, primary),

                    ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                    // Batch Information
                    _buildSectionHeader(
                      responsive,
                      primary,
                      'Batch Information',
                      Icons.info_rounded,
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                    _buildInfoCard(responsive, [
                      _buildInfoRow(
                        responsive,
                        'Pepper Type',
                        'Black Pepper',
                        Icons.grass_rounded,
                      ),
                      _buildDivider(responsive),
                      _buildInfoRow(
                        responsive,
                        'Variety',
                        'Ceylon Pepper',
                        Icons.local_florist_rounded,
                      ),
                      _buildDivider(responsive),
                      _buildInfoRow(
                        responsive,
                        'Drying Method',
                        'Sun Dried',
                        Icons.wb_sunny_rounded,
                      ),
                      _buildDivider(responsive),
                      _buildInfoRow(
                        responsive,
                        'Batch Weight',
                        '25 kg',
                        Icons.scale_rounded,
                      ),
                      _buildDivider(responsive),
                      _buildInfoRow(
                        responsive,
                        'Certificates',
                        'GAP, Quality Certificate',
                        Icons.verified_rounded,
                        isLast: true,
                      ),
                    ]),

                    ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                    // Quality Metrics
                    _buildSectionHeader(
                      responsive,
                      primary,
                      'Quality Metrics',
                      Icons.analytics_rounded,
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),

                    // Bulk Density Card
                    _buildMetricCard(
                      responsive,
                      'Bulk Density',
                      '640 g/L',
                      'Excellent for export quality',
                      Icons.science_rounded,
                      Colors.green,
                    ),

                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),

                    // Visual Quality Card
                    _buildMetricCard(
                      responsive,
                      'Visual Quality',
                      'Excellent',
                      'Minimal defects detected',
                      Icons.visibility_rounded,
                      Colors.blue,
                    ),

                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),

                    // AI Confidence Card
                    _buildMetricCard(
                      responsive,
                      'Model Confidence',
                      '94%',
                      'High accuracy prediction',
                      Icons.psychology_rounded,
                      Colors.purple,
                    ),

                    ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                    // Score Breakdown
                    _buildSectionHeader(
                      responsive,
                      primary,
                      'Score Breakdown',
                      Icons.calculate_rounded,
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                    _buildScoreCard(responsive, primary),

                    ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                    // Action Buttons
                    _buildActionButtons(context, responsive, primary),

                    ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeCard(Responsive responsive, Color primary) {
    return Container(
      width: double.infinity,
      padding: responsive.padding(
        mobile: const EdgeInsets.all(24),
        tablet: const EdgeInsets.all(28),
        desktop: const EdgeInsets.all(32),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade200, width: 2),
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
          // Premium Badge
          Container(
            padding: responsive.padding(
              mobile: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              desktop: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade600, Colors.green.shade700],
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
                  size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
                ),
                const SizedBox(width: 8),
                Text(
                  "PREMIUM GRADE",
                  style: TextStyle(
                    fontSize: responsive.fontSize(mobile: 14, tablet: 16, desktop: 18),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

          // Score Circle
          Container(
            width: responsive.value(mobile: 120, tablet: 140, desktop: 160),
            height: responsive.value(mobile: 120, tablet: 140, desktop: 160),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Colors.green.shade300, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "92",
                  style: TextStyle(
                    fontSize: responsive.fontSize(mobile: 42, tablet: 50, desktop: 58),
                    fontWeight: FontWeight.w800,
                    color: Colors.green.shade700,
                    height: 1,
                  ),
                ),
                Text(
                  "/ 100",
                  style: TextStyle(
                    fontSize: responsive.fontSize(mobile: 14, tablet: 16, desktop: 18),
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),

          ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),

          Text(
            "Overall Quality Score",
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),

          ResponsiveSpacing(mobile: 6, tablet: 8, desktop: 10),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.value(mobile: 12, tablet: 14, desktop: 16),
              vertical: responsive.value(mobile: 6, tablet: 7, desktop: 8),
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              "Excellent export-quality batch",
              style: TextStyle(
                fontSize: responsive.bodyFontSize - 2,
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

  Widget _buildInfoCard(Responsive responsive, List<Widget> children) {
    return Container(
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
      child: Column(children: children),
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
          Icon(icon, size: responsive.smallIconSize, color: Colors.grey[600]),
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

  Widget _buildMetricCard(
      Responsive responsive,
      String title,
      String value,
      String description,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(18),
        desktop: const EdgeInsets.all(20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              responsive.value(mobile: 10, tablet: 11, desktop: 12),
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: responsive.value(mobile: 24, tablet: 26, desktop: 28),
            ),
          ),
          ResponsiveSpacing.horizontal(mobile: 14, tablet: 16, desktop: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize - 1,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                ResponsiveSpacing(mobile: 4, tablet: 5, desktop: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                ResponsiveSpacing(mobile: 2, tablet: 3, desktop: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize - 2,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(Responsive responsive, Color primary) {
    return Container(
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
          _buildScoreRow(responsive, 'Bulk Density Score', '30', '30', false),
          ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
          _buildScoreRow(responsive, 'Visual Quality Score', '35', '40', false),
          ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
          _buildScoreRow(responsive, 'Defect Penalty', '-3', null, false),
          ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
          _buildScoreRow(responsive, 'Certification Bonus', '+5', null, false),
          ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
          Divider(color: Colors.grey.shade300, thickness: 1),
          ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
          _buildScoreRow(responsive, 'Final Score', '92', '100', true),
        ],
      ),
    );
  }

  Widget _buildScoreRow(
      Responsive responsive,
      String label,
      String value,
      String? maxValue,
      bool isFinal,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.bodyFontSize,
            fontWeight: isFinal ? FontWeight.w700 : FontWeight.w500,
            color: isFinal ? Colors.black87 : Colors.grey[700],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.value(mobile: 10, tablet: 11, desktop: 12),
            vertical: responsive.value(mobile: 4, tablet: 5, desktop: 6),
          ),
          decoration: BoxDecoration(
            color: isFinal
                ? Colors.green.shade50
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFinal
                  ? Colors.green.shade200
                  : Colors.grey.shade200,
            ),
          ),
          child: Text(
            maxValue != null ? '$value / $maxValue' : value,
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              fontWeight: FontWeight.w700,
              color: isFinal
                  ? Colors.green.shade700
                  : Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Responsive responsive, Color primary) {
    return Column(
      children: [
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading report...')),
              );
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
                Icon(Icons.download_rounded, size: responsive.smallIconSize),
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

        ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),

        Container(
          width: double.infinity,
          height: responsive.buttonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: primary, width: 2),
          ),
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening grading details...')),
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
                Icon(Icons.help_outline_rounded, size: responsive.smallIconSize),
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
      ],
    );
  }
}