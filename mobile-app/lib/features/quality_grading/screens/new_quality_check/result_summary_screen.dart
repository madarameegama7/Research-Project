import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../../../market_forecast/screens/weekly_price_forecast.dart';
import '../../services/quality_check_api.dart';
import 'package:CeylonPepper/features/quality_grading/screens/quality_grading_dashboard.dart';
import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/language_prefs.dart';
import '../../../../utils/quality_grading/result_summary_screen_si.dart';
import 'batch_details_screen.dart';
import '../how_it_works_screen.dart';
import '../../../../utils/web_download_stub.dart'
    if (dart.library.html) '../../../../utils/web_download.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Grade colour theme
// ─────────────────────────────────────────────────────────────────────────────
class _GradeTheme {
  final Color primary;
  final Color light;
  final Color border;
  final Color onLight;
  final IconData icon;
  const _GradeTheme({
    required this.primary,
    required this.light,
    required this.border,
    required this.onLight,
    required this.icon,
  });
}

_GradeTheme _gradeTheme(String grade) {
  final g = grade.toLowerCase();
  if (g.contains('premium')) {
    return _GradeTheme(
      primary: const Color(0xFFB8860B),
      light: const Color(0xFFFFF8E1),
      border: const Color(0xFFFFD54F),
      onLight: const Color(0xFF7B5800),
      icon: Icons.workspace_premium_rounded,
    );
  }
  if (g.contains('gold')) {
    return _GradeTheme(
      primary: const Color(0xFFF9A825),
      light: const Color(0xFFFFFDE7),
      border: const Color(0xFFFFEE58),
      onLight: const Color(0xFF5D4037),
      icon: Icons.military_tech_rounded,
    );
  }
  if (g.contains('silver')) {
    return _GradeTheme(
      primary: const Color(0xFF546E7A),
      light: const Color(0xFFECEFF1),
      border: const Color(0xFFB0BEC5),
      onLight: const Color(0xFF263238),
      icon: Icons.star_half_rounded,
    );
  }
  if (g.contains('basic') || g.contains('bronze')) {
    return _GradeTheme(
      primary: const Color(0xFF795548),
      light: const Color(0xFFEFEBE9),
      border: const Color(0xFFBCAAA4),
      onLight: const Color(0xFF4E342E),
      icon: Icons.star_border_rounded,
    );
  }
  if (g.contains('reject') || g.contains('fail')) {
    return _GradeTheme(
      primary: const Color(0xFFC62828),
      light: const Color(0xFFFFEBEE),
      border: const Color(0xFFEF9A9A),
      onLight: const Color(0xFFB71C1C),
      icon: Icons.cancel_rounded,
    );
  }
  return _GradeTheme(
    primary: const Color(0xFF2E7D32),
    light: const Color(0xFFE8F5E9),
    border: const Color(0xFFA5D6A7),
    onLight: const Color(0xFF1B5E20),
    icon: Icons.verified_rounded,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
String _str(dynamic v, {String fallback = '—'}) {
  if (v == null) return fallback;
  final s = v.toString().trim();
  return s.isEmpty ? fallback : s;
}

String _mapPepperType(String v, {bool sinhala = false}) {
  switch (v) {
    case 'black':
      return sinhala ? ResultSummaryScreenSi.blackPepper : 'Black Pepper';
    case 'white':
      return sinhala ? ResultSummaryScreenSi.whitePepper : 'White Pepper';
    default:
      return v.isEmpty ? '—' : v;
  }
}

String _mapVariety(String v) {
  // Proper names — kept in English.
  switch (v) {
    case 'ceylon_pepper':
      return 'Ceylon Pepper';
    case 'panniyur_1':
      return 'Panniyur-1';
    case 'kuching':
      return 'Kuching';
    case 'dingi_rala':
      return 'Dingi Rala';
    case 'kohukumbure_rala':
      return 'Kohukumbure Rala';
    case 'bootawe_rala':
      return 'Bootawe Rala';
    case 'malabar':
      return 'Malabar';
    case 'unknown':
      return 'Unknown';
    default:
      return v.isEmpty ? '—' : v.replaceAll('_', ' ');
  }
}

String _mapDrying(String v, {bool sinhala = false}) {
  switch (v) {
    case 'sun_dried':
      return sinhala ? ResultSummaryScreenSi.sunDried : 'Sun Dried';
    case 'machine_dried':
      return sinhala ? ResultSummaryScreenSi.machineDried : 'Machine Dried';
    default:
      return v.isEmpty ? '—' : v.replaceAll('_', ' ');
  }
}

String _formatDateIso(dynamic iso) {
  if (iso == null) return '—';
  try {
    final d = DateTime.parse(iso.toString()).toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  } catch (_) {
    return iso.toString();
  }
}

String _formatGrams(dynamic totalGrams) {
  if (totalGrams == null) return '—';
  final g = (totalGrams as num).toInt();
  if (g <= 0) return '—';
  final kg = g ~/ 1000;
  final rem = g % 1000;
  if (kg == 0) return '$rem g';
  if (rem == 0) return '$kg kg';
  return '$kg kg $rem g';
}

String _formatCertType(String? v) {
  if (v == null || v.isEmpty) return '—';
  return v
      .split(RegExp(r'[_\-]'))
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
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
  String _currentLanguage = 'en';

  bool _downloading = false;
  String? _lastPdfPath;

  bool get _isSinhala => _currentLanguage == 'si';
  String _t(String english, String sinhala) => _isSinhala ? sinhala : english;

  // ── Derived values ─────────────────────────────────────────────────────────

  Map<String, dynamic> get _batch =>
      (_qc?['batch'] as Map<String, dynamic>?) ?? {};

  Map<String, dynamic> get _density =>
      (_qc?['density'] as Map<String, dynamic>?) ?? {};

  List<Map<String, dynamic>> get _certItems {
    final snap = _qc?['certificatesSnapshot'] as Map<String, dynamic>?;
    if (snap == null) return [];
    return ((snap['items'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>();
  }

  String get _pepperTypeUi =>
      _mapPepperType(_str(_batch['pepperType']), sinhala: _isSinhala);
  String get _varietyUi => _mapVariety(_str(_batch['pepperVariety']));
  String get _dryingUi =>
      _mapDrying(_str(_batch['dryingMethod']), sinhala: _isSinhala);
  String get _harvestDateUi => _formatDateIso(_batch['harvestDate']);
  String get _weightUi => _formatGrams(_batch['batchWeightGrams']);
  String get _densityUi {
    final v = _density['value'];
    return v != null ? '${v.toString()} g/L' : '—';
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

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

    _loadQualityCheck();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadQualityCheck() async {
    setState(() {
      _loadingBatch = true;
      _batchError = null;
    });
    try {
      final qc = await QualityCheckApi().getQualityCheckById(
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    const primary = Color(0xFF2E7D32);

    final grade = widget.result['grade']?.toString() ?? '—';
    final score = widget.result['overallScore'];
    final scoreDisplay = score is num
        ? score.toStringAsFixed(1)
        : _str(score, fallback: '—');

    final improvements = (widget.result['improvements'] is List)
        ? (widget.result['improvements'] as List)
              .map((e) => e.toString())
              .toList()
        : <String>[];

    final factorScores = (widget.result['factorScores'] is Map)
        ? (widget.result['factorScores'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    final theme = _gradeTheme(grade);

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
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const QualityGradingDashboard(),
              ),
              (route) => false,
            ),
          ),
          title: Text(
            _t('Quality Report', ResultSummaryScreenSi.qualityReport),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              tooltip: _t('Share report', ResultSummaryScreenSi.shareReport),
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
                        // ── Grade / Score card ─────────────────────────
                        _buildGradeCard(responsive, grade, scoreDisplay, theme),

                        ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),

                        // ── Batch Info ─────────────────────────────────
                        _buildSectionHeader(
                          responsive,
                          primary,
                          _t(
                            'Batch Information',
                            ResultSummaryScreenSi.batchInformation,
                          ),
                          Icons.info_rounded,
                        ),
                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                        _buildBatchCard(responsive),

                        ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),

                        // ── Certificates ───────────────────────────────
                        _buildSectionHeader(
                          responsive,
                          primary,
                          _t(
                            'Certificates',
                            ResultSummaryScreenSi.certificates,
                          ),
                          Icons.verified_rounded,
                        ),
                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                        _buildCertificatesCard(responsive),

                        ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),

                        // ── Quality Breakdown ──────────────────────────
                        _buildSectionHeader(
                          responsive,
                          primary,
                          _t(
                            'Quality Breakdown',
                            ResultSummaryScreenSi.qualityBreakdown,
                          ),
                          Icons.analytics_rounded,
                        ),
                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                        _buildBreakdownCard(responsive, factorScores),

                        ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),

                        // ── Improvements ───────────────────────────────
                        _buildSectionHeader(
                          responsive,
                          primary,
                          _t(
                            'Improvement Suggestions',
                            ResultSummaryScreenSi.improvementSuggestions,
                          ),
                          Icons.lightbulb_rounded,
                        ),
                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                        _buildImprovementsCard(responsive, improvements),

                        ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                        // ── Next Steps ─────────────────────────────────
                        _buildSectionHeader(
                          responsive,
                          primary,
                          _t('Next Steps', ResultSummaryScreenSi.nextSteps),
                          Icons.explore_rounded,
                        ),
                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                        _buildQuickActionsGrid(context, responsive, primary),

                        ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                        // ── Download PDF ───────────────────────────────
                        Container(
                          width: double.infinity,
                          height: responsive.value(
                            mobile: 60,
                            tablet: 64,
                            desktop: 68,
                          ),
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
                            child: _downloading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : _responsiveButtonRow(
                                    responsive: responsive,
                                    icon: Icons.download_rounded,
                                    text: _t(
                                      'Download Report (PDF)',
                                      ResultSummaryScreenSi.downloadReportPdf,
                                    ),
                                    textColor: Colors.white,
                                  ),
                          ),
                        ),

                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                        Container(
                          width: double.infinity,
                          height: responsive.value(
                            mobile: 60,
                            tablet: 64,
                            desktop: 68,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: primary, width: 2),
                          ),
                          child: OutlinedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HowItWorksScreen(),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: _responsiveButtonRow(
                              responsive: responsive,
                              icon: Icons.help_outline_rounded,
                              text: _t(
                                'How is Quality Calculated?',
                                ResultSummaryScreenSi.howIsQualityCalculated,
                              ),
                              textColor: primary,
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

  // ── Grade card ─────────────────────────────────────────────────────────────

  Widget _buildGradeCard(
    Responsive responsive,
    String grade,
    String scoreDisplay,
    _GradeTheme theme,
  ) {
    return Container(
      width: double.infinity,
      padding: responsive.padding(
        mobile: const EdgeInsets.all(24),
        tablet: const EdgeInsets.all(28),
        desktop: const EdgeInsets.all(32),
      ),
      decoration: BoxDecoration(
        color: theme.light,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primary.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      theme.icon,
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
          ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
          Container(
            width: responsive.value(mobile: 140, tablet: 160, desktop: 180),
            height: responsive.value(mobile: 140, tablet: 160, desktop: 180),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: theme.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withOpacity(0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  scoreDisplay,
                  style: TextStyle(
                    fontSize: responsive.fontSize(
                      mobile: 46,
                      tablet: 54,
                      desktop: 62,
                    ),
                    fontWeight: FontWeight.w800,
                    color: theme.primary,
                    height: 1,
                  ),
                ),
                Text(
                  '/ 100',
                  style: TextStyle(
                    fontSize: responsive.fontSize(
                      mobile: 15,
                      tablet: 17,
                      desktop: 19,
                    ),
                    fontWeight: FontWeight.w600,
                    color: theme.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
          Text(
            _t(
              'Overall Quality Score',
              ResultSummaryScreenSi.overallQualityScore,
            ),
            style: TextStyle(
              fontSize: responsive.titleFontSize,
              color: theme.onLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Batch card ─────────────────────────────────────────────────────────────

  Widget _buildBatchCard(Responsive responsive) {
    if (_loadingBatch) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_batchError != null) {
      return Container(
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
              child: Text(_t('Retry', ResultSummaryScreenSi.retry)),
            ),
          ],
        ),
      );
    }

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
      child: Column(
        children: [
          _buildInfoRow(
            responsive,
            _t('Pepper Type', ResultSummaryScreenSi.pepperType),
            _pepperTypeUi,
            Icons.grass_rounded,
          ),
          _buildDivider(responsive),
          _buildInfoRow(
            responsive,
            _t('Pepper Variety', ResultSummaryScreenSi.pepperVariety),
            _varietyUi,
            Icons.local_florist_rounded,
          ),
          _buildDivider(responsive),
          _buildInfoRow(
            responsive,
            _t('Drying Method', ResultSummaryScreenSi.dryingMethod),
            _dryingUi,
            Icons.wb_sunny_rounded,
          ),
          _buildDivider(responsive),
          _buildInfoRow(
            responsive,
            _t('Harvest Date', ResultSummaryScreenSi.harvestDate),
            _harvestDateUi,
            Icons.calendar_today_rounded,
          ),
          _buildDivider(responsive),
          _buildInfoRow(
            responsive,
            _t('Batch Weight', ResultSummaryScreenSi.batchWeight),
            _weightUi,
            Icons.scale_rounded,
          ),
          _buildDivider(responsive),
          _buildInfoRow(
            responsive,
            _t('Bulk Density', ResultSummaryScreenSi.bulkDensity),
            _densityUi,
            Icons.science_rounded,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ── Certificates card ──────────────────────────────────────────────────────

  Widget _buildCertificatesCard(Responsive responsive) {
    if (_loadingBatch) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final items = _certItems;

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: responsive.padding(
          mobile: const EdgeInsets.all(16),
          tablet: const EdgeInsets.all(18),
          desktop: const EdgeInsets.all(20),
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Colors.grey.shade500,
              size: responsive.smallIconSize,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _t(
                  'No certificates were attached at grading time.',
                  ResultSummaryScreenSi.noCertificatesAttached,
                ),
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: responsive.padding(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(18),
        desktop: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(items.length, (i) {
          final cert = items[i];
          final type = _formatCertType(cert['certificationType'] as String?);
          final number = (cert['certificateNumber'] as String? ?? '').trim();
          final issuer = (cert['issuingBody'] as String? ?? '').trim();
          final isLast = i == items.length - 1;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: responsive.value(
                    mobile: 10,
                    tablet: 12,
                    desktop: 14,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.verified_rounded,
                        color: Colors.blue.shade700,
                        size: responsive.value(
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: responsive.bodyFontSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          if (number.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${_t('No:', ResultSummaryScreenSi.certNo)} $number',
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize - 1,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          if (issuer.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              issuer,
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize - 1,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (cert['expiryDate'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          '${_t('Exp:', ResultSummaryScreenSi.expLabel)} ${_formatDateIso(cert["expiryDate"])}',
                          style: TextStyle(
                            fontSize: responsive.bodyFontSize - 2,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!isLast) _buildDivider(responsive),
            ],
          );
        }),
      ),
    );
  }

  // ── Breakdown card ─────────────────────────────────────────────────────────

  Widget _buildBreakdownCard(
    Responsive responsive,
    Map<String, dynamic> factorScores,
  ) {
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
          _buildScoreBar(
            responsive,
            _t('Density', ResultSummaryScreenSi.density),
            _asInt(factorScores['density']),
            Colors.green,
          ),
          _buildScoreBar(
            responsive,
            _t('Adulteration', ResultSummaryScreenSi.adulteration),
            _asInt(factorScores['adulteration']),
            Colors.teal,
          ),
          _buildScoreBar(
            responsive,
            _t('Mold', ResultSummaryScreenSi.mold),
            _asInt(factorScores['mold']),
            Colors.purple,
          ),
          _buildScoreBar(
            responsive,
            _t('Extraneous', ResultSummaryScreenSi.extraneous),
            _asInt(factorScores['extraneous']),
            Colors.orange,
          ),
          _buildScoreBar(
            responsive,
            _t('Broken', ResultSummaryScreenSi.broken),
            _asInt(factorScores['broken']),
            Colors.blue,
          ),
          _buildScoreBar(
            responsive,
            _t('Healthy Visual', ResultSummaryScreenSi.healthyVisual),
            _asInt(factorScores['healthyVisual']),
            Colors.indigo,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ── Improvements card ──────────────────────────────────────────────────────

  Widget _buildImprovementsCard(
    Responsive responsive,
    List<String> improvements,
  ) {
    return Container(
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
                Icon(Icons.check_circle_rounded, color: Colors.green.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t(
                      'No improvements suggested. Your batch looks great!',
                      ResultSummaryScreenSi.noImprovements,
                    ),
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
              children: improvements
                  .map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildSuggestionItem(
                        responsive,
                        t,
                        Icons.lightbulb_rounded,
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────

  Widget _buildQuickActionsGrid(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            context,
            responsive,
            title: _t(
              'Check Market Price',
              ResultSummaryScreenSi.checkMarketPrice,
            ),
            subtitle: _t(
              'Get current rates',
              ResultSummaryScreenSi.getCurrentRates,
            ),
            icon: Icons.trending_up_rounded,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WeeklyPriceForecast()),
            ),
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
        Expanded(
          child: _buildQuickActionCard(
            context,
            responsive,
            title: _t('Start New Test', ResultSummaryScreenSi.startNewTest),
            subtitle: _t(
              'Grade another batch',
              ResultSummaryScreenSi.gradeAnotherBatch,
            ),
            icon: Icons.add_circle_outline_rounded,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BatchDetailsScreen()),
            ),
          ),
        ),
      ],
    );
  }

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

  // ── Shared helpers ─────────────────────────────────────────────────────────

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
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontSize: responsive.headingFontSize - 2,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
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
          const SizedBox(width: 8),
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

  Widget _buildDivider(Responsive responsive) => Divider(
    height: 1,
    indent: responsive.value(mobile: 16, tablet: 18, desktop: 20),
    endIndent: responsive.value(mobile: 16, tablet: 18, desktop: 20),
  );

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

  Widget _responsiveButtonRow({
    required Responsive responsive,
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
    IconData? trailingIcon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: responsive.smallIconSize,
          color: iconColor ?? textColor,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: responsive.titleFontSize,
              height: 1.1,
              color: textColor,
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(
            trailingIcon,
            size: responsive.smallIconSize,
            color: iconColor ?? textColor,
          ),
        ],
      ],
    );
  }

  // ── PDF helpers ────────────────────────────────────────────────────────────

  String _pdfFileName() => 'pepper_report_${widget.batchId}.pdf';

  Future<void> _downloadPdf({bool openAfter = true}) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await QualityCheckApi().downloadPdfBytes(
        qualityCheckId: widget.qualityCheckId,
      );
      final fileName = _pdfFileName();
      if (kIsWeb) {
        downloadBytesOnWeb(bytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _t('PDF downloaded', ResultSummaryScreenSi.pdfDownloaded),
              ),
            ),
          );
        }
        return;
      }
      final path = await QualityCheckApi().savePdfToFile(
        bytes: bytes,
        fileName: fileName,
      );
      _lastPdfPath = path;
      if (openAfter) await OpenFilex.open(path);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved: $fileName')));
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
      if (kIsWeb) {
        await _downloadPdf(openAfter: false);
        return;
      }
      if (_lastPdfPath != null && File(_lastPdfPath!).existsSync()) {
        await Share.shareXFiles([
          XFile(_lastPdfPath!),
        ], text: 'Ceylon Pepper Quality Report (${widget.batchId})');
        return;
      }
      final bytes = await QualityCheckApi().downloadPdfBytes(
        qualityCheckId: widget.qualityCheckId,
      );
      final path = await QualityCheckApi().savePdfToFile(
        bytes: bytes,
        fileName: _pdfFileName(),
      );
      _lastPdfPath = path;
      await Share.shareXFiles([
        XFile(path),
      ], text: 'Ceylon Pepper Quality Report (${widget.batchId})');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }
}
