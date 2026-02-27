import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../services/quality_check_api.dart';
import 'package:CeylonPepper/features/quality_grading/screens/quality_grading_dashboard.dart';
import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import '../../market_forecast/screens/navigation.dart';
import 'batch_details_screen.dart';
import 'how_it_works_screen.dart';
import '../../../utils/web_download.dart'
    if (dart.library.io) '../../../utils/web_download_stub.dart';

class ResultSummaryScreen extends StatefulWidget {
  final String qualityCheckId;
  final String batchId;
  final Map<String, dynamic> result;

  const ResultSummaryScreen({
    super.key,
    required this.qualityCheckId,
    required this.batchId,
    required this.result,
  });

  @override
  State<ResultSummaryScreen> createState() => _ResultSummaryScreenState();
}

class _ResultSummaryScreenState extends State<ResultSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _loadingBatch = true;
  String? _batchError;
  Map<String, dynamic>? _qc;

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
    _loadQualityCheck();
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
    final grade = widget.result["grade"]?.toString() ?? "-";
    final score = widget.result["overallScore"]?.toString() ?? "-";
    final improvements = (widget.result["improvements"] is List)
        ? (widget.result["improvements"] as List)
              .map((e) => e.toString())
              .toList()
        : <String>[];
    final factorScores = (widget.result["factorScores"] is Map)
        ? (widget.result["factorScores"] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    String pepperTypeUi = "-";
    String varietyUi = "-";
    String dryingUi = "-";
    String harvestDateUi = "-";
    String weightUi = "-";
    String densityUi = "-";
    String certsUi = "-";

    if (_qc != null) {
      // Adjust keys based on your backend response shape.
      // Here I assume qc has fields similar to your createQualityCheck body + density.
      final pepperType = _qc!["pepperType"];
      final pepperVariety = _qc!["pepperVariety"];
      final dryingMethod = _qc!["dryingMethod"];
      final harvestDate = _qc!["harvestDate"];
      final bwKg = _qc!["batchWeightKg"];
      final bwG = _qc!["batchWeightG"];

      pepperTypeUi = _mapPepperTypeToUi(_asString(pepperType));
      varietyUi = _mapVarietyToUi(_asString(pepperVariety));
      dryingUi = _mapDryingToUi(_asString(dryingMethod));
      harvestDateUi = _formatDate(harvestDate);
      weightUi = _formatWeight(bwKg, bwG);

      final densityObj = _qc!["density"];
      if (densityObj is Map) {
        final v = densityObj["value"];
        if (v != null) densityUi = "${_asString(v)} g/L";
      } else if (_qc!["densityValue"] != null) {
        densityUi = "${_asString(_qc!["densityValue"])} g/L";
      }

      final certs = _qc!["certificatesUsed"];
      if (certs is List) {
        certsUi = certs.map((e) => e.toString()).join(", ");
        if (certsUi.trim().isEmpty) certsUi = "-";
      } else {
        // fallback
        certsUi = "-";
      }
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const QualityGradingDashboard()),
          (route) => false,
        );
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const QualityGradingDashboard(),
                ),
                (route) => false,
              );
            },
          ),

          title: const Text(
            'Quality Report',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: 'Share report',
              onPressed: _downloading ? null : _sharePdf,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                          color: Colors.green.shade700
                                              .withOpacity(0.3),
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
                                          grade.toUpperCase(),
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
                              ResponsiveSpacing(
                                mobile: 24,
                                tablet: 28,
                                desktop: 32,
                              ),

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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          score,
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
                              ResponsiveSpacing(
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
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

                        if (_loadingBatch)
                          const Center(child: CircularProgressIndicator())
                        else if (_batchError != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _batchError!,
                                    style: TextStyle(
                                      fontSize: responsive.bodyFontSize,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: _loadQualityCheck,
                                  child: const Text("Retry"),
                                ),
                              ],
                            ),
                          )
                        else
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
                                _buildInfoRow(
                                  responsive,
                                  'Pepper Type',
                                  pepperTypeUi,
                                  Icons.grass_rounded,
                                ),
                                _buildDivider(responsive),
                                _buildInfoRow(
                                  responsive,
                                  'Pepper Variety',
                                  varietyUi,
                                  Icons.local_florist_rounded,
                                ),
                                _buildDivider(responsive),
                                _buildInfoRow(
                                  responsive,
                                  'Drying Method',
                                  dryingUi,
                                  Icons.wb_sunny_rounded,
                                ),
                                _buildDivider(responsive),
                                _buildInfoRow(
                                  responsive,
                                  'Harvest Date',
                                  harvestDateUi,
                                  Icons.calendar_today_rounded,
                                ),
                                _buildDivider(responsive),
                                _buildInfoRow(
                                  responsive,
                                  'Batch Weight',
                                  weightUi,
                                  Icons.scale_rounded,
                                ),
                                _buildDivider(responsive),
                                _buildInfoRow(
                                  responsive,
                                  'Bulk Density',
                                  densityUi,
                                  Icons.science_rounded,
                                ),
                                _buildDivider(responsive),
                                _buildInfoRow(
                                  responsive,
                                  'Certificates',
                                  certsUi,
                                  Icons.verified_rounded,
                                  isLast: true,
                                ),
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
                              _buildScoreBar(
                                responsive,
                                'Density',
                                _asIntScore(factorScores["density"]),
                                Colors.green,
                              ),
                              _buildScoreBar(
                                responsive,
                                'Adulteration',
                                _asIntScore(factorScores["adulteration"]),
                                Colors.teal,
                              ),
                              _buildScoreBar(
                                responsive,
                                'Mold',
                                _asIntScore(factorScores["mold"]),
                                Colors.purple,
                              ),
                              _buildScoreBar(
                                responsive,
                                'Extraneous',
                                _asIntScore(factorScores["extraneous"]),
                                Colors.orange,
                              ),
                              _buildScoreBar(
                                responsive,
                                'Broken',
                                _asIntScore(factorScores["broken"]),
                                Colors.blue,
                              ),
                              _buildScoreBar(
                                responsive,
                                'Healthy Visual',
                                _asIntScore(factorScores["healthyVisual"]),
                                Colors.indigo,
                                isLast: true,
                              ),
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
                          child: improvements.isEmpty
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green.shade700,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "No improvements suggested. Your batch looks good.",
                                        style: TextStyle(
                                          fontSize: responsive.bodyFontSize,
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: improvements.map((t) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: _buildSuggestionItem(
                                        responsive,
                                        t,
                                        Icons.lightbulb_rounded,
                                      ),
                                    );
                                  }).toList(),
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
                            onPressed: _downloading
                                ? null
                                : () => _downloadPdf(openAfter: true),
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
                                  builder: (context) =>
                                      const HowItWorksScreen(),
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
  Widget _buildQuickActionsGrid(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
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

  Widget _buildScoreBar(
    Responsive responsive,
    String label,
    int score,
    Color color, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast
            ? 0
            : responsive.value(mobile: 20, tablet: 22, desktop: 24),
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
                  horizontal: responsive.value(
                    mobile: 10,
                    tablet: 11,
                    desktop: 12,
                  ),
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

  bool _downloading = false;
  String? _lastPdfPath; // cached file for share

  String _pdfFileName() => "pepper_report_${widget.batchId}.pdf";

  Future<void> _downloadPdf({bool openAfter = true}) async {
    if (_downloading) return;

    setState(() => _downloading = true);

    try {
      final api = QualityCheckApi();
      final bytes = await api.downloadPdfBytes(
        qualityCheckId: widget.qualityCheckId,
      );

      final fileName = _pdfFileName();

      if (kIsWeb) {
        downloadBytesOnWeb(bytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("PDF downloaded")));
        }
        return;
      }

      // mobile/desktop
      final path = await api.savePdfToFile(bytes: bytes, fileName: fileName);
      _lastPdfPath = path;

      if (openAfter) {
        await OpenFilex.open(path);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Saved: $fileName")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _sharePdf() async {
    try {
      // Web share of files is inconsistent. We will fallback to download.
      if (kIsWeb) {
        await _downloadPdf(openAfter: false);
        return;
      }

      // If already downloaded, share directly
      if (_lastPdfPath != null && File(_lastPdfPath!).existsSync()) {
        await Share.shareXFiles([
          XFile(_lastPdfPath!),
        ], text: "Ceylon Pepper Quality Report (${widget.batchId})");
        return;
      }

      // Download then share
      final api = QualityCheckApi();
      final bytes = await api.downloadPdfBytes(
        qualityCheckId: widget.qualityCheckId,
      );
      final path = await api.savePdfToFile(
        bytes: bytes,
        fileName: _pdfFileName(),
      );
      _lastPdfPath = path;

      await Share.shareXFiles([
        XFile(path),
      ], text: "Ceylon Pepper Quality Report (${widget.batchId})");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadQualityCheck() async {
    setState(() {
      _loadingBatch = true;
      _batchError = null;
    });

    try {
      final api = QualityCheckApi();
      final qc = await api.getQualityCheckById(
        qualityCheckId: widget.qualityCheckId,
      );

      if (!mounted) return;
      setState(() {
        _qc = qc;
        _loadingBatch = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _batchError = e.toString();
        _loadingBatch = false;
      });
    }
  }

  int _asIntScore(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  String _asString(dynamic v, {String fallback = "-"}) {
    if (v == null) return fallback;
    final s = v.toString();
    return s.isEmpty ? fallback : s;
  }

  String _formatDate(dynamic iso) {
    if (iso == null) return "-";
    try {
      final d = DateTime.parse(iso.toString()).toLocal();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yyyy = d.year.toString();
      return "$dd/$mm/$yyyy";
    } catch (_) {
      return iso.toString();
    }
  }

  String _mapPepperTypeToUi(String v) {
    switch (v) {
      case "black":
        return "Black Pepper";
      case "white":
        return "White Pepper";
      default:
        return v;
    }
  }

  String _mapVarietyToUi(String v) {
    switch (v) {
      case "ceylon_pepper":
        return "Ceylon Pepper";
      case "panniyur_1":
        return "Panniyur-1";
      case "kuching":
        return "Kuching";
      case "dingi_rala":
        return "Dingi Rala";
      case "kohukumbure_rala":
        return "Kohukumbure Rala";
      case "bootawe_rala":
        return "Bootawe Rala";
      case "malabar":
        return "Malabar";
      default:
        return v;
    }
  }

  String _mapDryingToUi(String v) {
    switch (v) {
      case "sun_dried":
        return "Sun Dried";
      case "machine_dried":
        return "Machine Dried";
      default:
        return v;
    }
  }

  String _formatWeight(dynamic kg, dynamic g) {
    final k = (kg is num)
        ? kg.toInt()
        : int.tryParse(kg?.toString() ?? "") ?? 0;
    final gg = (g is num) ? g.toInt() : int.tryParse(g?.toString() ?? "") ?? 0;
    if (k == 0 && gg == 0) return "-";
    if (gg == 0) return "$k kg";
    if (k == 0) return "$gg g";
    return "$k kg $gg g";
  }
}
