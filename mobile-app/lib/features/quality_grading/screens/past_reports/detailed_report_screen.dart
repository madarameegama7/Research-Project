import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

import '../../../../utils/responsive.dart';
import '../../../../utils/language_prefs.dart';
import '../../../../utils/web_download_stub.dart'
    if (dart.library.html) '../../../../utils/web_download.dart';
import '../../../quality_grading/services/quality_check_api.dart';
import '../how_it_works_screen.dart';
import '../../../../utils/quality_grading/detailed_report_screen_si.dart';

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
  if (g.contains('premium') || g.contains('grade 1')) {
    return _GradeTheme(
      primary: const Color(0xFFB8860B),
      light: const Color(0xFFFFF8E1),
      border: const Color(0xFFFFD54F),
      onLight: const Color(0xFF7B5800),
      icon: Icons.workspace_premium_rounded,
    );
  }
  if (g.contains('gold') || g.contains('grade 2')) {
    return _GradeTheme(
      primary: const Color(0xFFF9A825),
      light: const Color(0xFFFFFDE7),
      border: const Color(0xFFFFEE58),
      onLight: const Color(0xFF5D4037),
      icon: Icons.military_tech_rounded,
    );
  }
  if (g.contains('silver') || g.contains('grade 3')) {
    return _GradeTheme(
      primary: const Color(0xFF546E7A),
      light: const Color(0xFFECEFF1),
      border: const Color(0xFFB0BEC5),
      onLight: const Color(0xFF263238),
      icon: Icons.star_half_rounded,
    );
  }
  if (g.contains('basic') || g.contains('grade 4')) {
    return _GradeTheme(
      primary: const Color(0xFF795548),
      light: const Color(0xFFEFEBE9),
      border: const Color(0xFFBCAAA4),
      onLight: const Color(0xFF4E342E),
      icon: Icons.star_border_rounded,
    );
  }
  if (g.contains('reject')) {
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
// Formatting helpers
// ─────────────────────────────────────────────────────────────────────────────
String _str(dynamic v, {String fallback = '—'}) {
  if (v == null) return fallback;
  final s = v.toString().trim();
  return s.isEmpty ? fallback : s;
}

String _mapPepperType(String v) {
  switch (v) {
    case 'black':
      return 'Black Pepper';
    case 'white':
      return 'White Pepper';
    default:
      return v.isEmpty ? '—' : v;
  }
}

String _mapVariety(String v) {
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

String _mapDrying(String v) {
  switch (v) {
    case 'sun_dried':
      return 'Sun Dried';
    case 'machine_dried':
      return 'Machine Dried';
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

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.round();
  return int.tryParse(v.toString()) ?? 0;
}

double _asDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class DetailedReportScreen extends StatefulWidget {
  final String qualityCheckId;
  final Map<String, dynamic>? reportData;

  const DetailedReportScreen({
    super.key,
    required this.qualityCheckId,
    this.reportData,
  });

  @override
  State<DetailedReportScreen> createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends State<DetailedReportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _qc;

  bool _downloading = false;
  String? _lastPdfPath;

  String _currentLanguage = 'en';

  // ── Language helper ────────────────────────────────────────────────────────

  bool get _isSi => _currentLanguage == 'si';

  String _t(String en, String si) => _isSi ? si : en;

  // ── Convenient getters ─────────────────────────────────────────────────────

  Map<String, dynamic> get _batch =>
      (_qc?['batch'] as Map<String, dynamic>?) ?? {};

  Map<String, dynamic> get _density =>
      (_qc?['density'] as Map<String, dynamic>?) ?? {};

  Map<String, dynamic> get _results =>
      (_qc?['results'] as Map<String, dynamic>?) ?? {};

  Map<String, dynamic> get _factorScores =>
      (_results['factorScores'] as Map<String, dynamic>?) ?? {};

  Map<String, dynamic> get _factors =>
      (_results['factors'] as Map<String, dynamic>?) ?? {};

  List<Map<String, dynamic>> get _certItems {
    final snap = _qc?['certificatesSnapshot'] as Map<String, dynamic>?;
    if (snap == null) return [];
    return ((snap['items'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>();
  }

  List<String> get _improvements =>
      ((_results['improvements'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList();

  bool get _hardReject => _results['hardReject'] == true;

  List<String> get _hardRejectReasons =>
      ((_results['hardRejectReasons'] as List<dynamic>?) ?? [])
          .map((e) => e.toString())
          .toList();

  String get _grade => _str(_results['grade'], fallback: '—');

  String get _scoreDisplay {
    final v = _results['overallScore'];
    if (v == null) return '—';
    return (v as num).toStringAsFixed(1);
  }

  String get _pepperTypeUi => _mapPepperType(_str(_batch['pepperType']));
  String get _varietyUi => _mapVariety(_str(_batch['pepperVariety']));
  String get _dryingUi => _mapDrying(_str(_batch['dryingMethod']));
  String get _harvestDateUi => _formatDateIso(_batch['harvestDate']);
  String get _weightUi => _formatGrams(_batch['batchWeightGrams']);
  String get _densityUi {
    final v = _density['value'];
    return v != null ? '${v.toString()} g/L' : '—';
  }

  String get _batchId => _str(_qc?['batchId'], fallback: '—');

  // ── Lifecycle ──────────────────────────────────────────────────────────────

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

    // Load saved language preference
    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) setState(() => _currentLanguage = lang);
    });

    if (widget.reportData != null) {
      _qc = widget.reportData;
      _loading = false;
      _animationController.forward();
    } else {
      _fetchReport();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await QualityCheckApi().getQualityCheckById(
        qualityCheckId: widget.qualityCheckId,
      );
      if (!mounted) return;
      setState(() {
        _qc = data;
        _loading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
        title: Text(
          _loading
              ? _t('Report Details', DetailedReportScreenSi.reportDetails)
              : _batchId,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: _t('Share report', DetailedReportScreenSi.shareReport),
            onPressed: (_loading || _error != null || _downloading)
                ? null
                : _sharePdf,
          ),
        ],
      ),
      body: _loading
          ? _loadingState()
          : _error != null
          ? _errorState(responsive, primary)
          : FadeTransition(
              opacity: _fadeAnimation,
              child: _buildBody(responsive, primary),
            ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────

  Widget _loadingState() => const Center(
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
    ),
  );

  Widget _errorState(Responsive responsive, Color primary) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                responsive.value(mobile: 24, tablet: 28, desktop: 32),
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: responsive.value(mobile: 56, tablet: 64, desktop: 72),
                color: Colors.red.shade400,
              ),
            ),
            ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),
            Text(
              _t('Failed to Load Report', DetailedReportScreenSi.failedToLoad),
              style: TextStyle(
                fontSize: responsive.headingFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            ResponsiveSpacing(mobile: 8, tablet: 10, desktop: 12),
            Text(
              _error ??
                  _t(
                    'An unexpected error occurred.',
                    DetailedReportScreenSi.unexpectedError,
                  ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
            ElevatedButton.icon(
              onPressed: _fetchReport,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_t('Try Again', DetailedReportScreenSi.tryAgain)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Main body
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildBody(Responsive responsive, Color primary) {
    final theme = _gradeTheme(_grade);

    return SingleChildScrollView(
      child: Column(
        children: [
          ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Grade / Score card ───────────────────────────────────────
                _buildGradeCard(responsive, theme),

                if (_hardReject) ...[
                  ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                  _buildHardRejectBanner(responsive),
                ],

                ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),

                // ── Batch Information ────────────────────────────────────────
                _buildSectionHeader(
                  responsive,
                  primary,
                  _t(
                    'Batch Information',
                    DetailedReportScreenSi.batchInformation,
                  ),
                  Icons.info_rounded,
                ),
                ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                _buildBatchCard(responsive),

                ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),

                // ── Bulk Density ─────────────────────────────────────────────
                _buildSectionHeader(
                  responsive,
                  primary,
                  _t('Bulk Density (IoT)', DetailedReportScreenSi.bulkDensity),
                  Icons.science_rounded,
                ),
                ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                _buildDensityCard(responsive),

                ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),

                // ── Certificates ─────────────────────────────────────────────
                _buildSectionHeader(
                  responsive,
                  primary,
                  _t(
                    'Certificates at Grading',
                    DetailedReportScreenSi.certificatesAtGrading,
                  ),
                  Icons.verified_rounded,
                ),
                ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                _buildCertificatesCard(responsive),

                ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),

                // ── Raw AI Measurements ──────────────────────────────────────
                _buildSectionHeader(
                  responsive,
                  primary,
                  _t(
                    'Raw AI Measurements',
                    DetailedReportScreenSi.rawAiMeasurements,
                  ),
                  Icons.biotech_rounded,
                ),
                ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                _buildRawFactorsCard(responsive),

                if (_improvements.isNotEmpty) ...[
                  ResponsiveSpacing(mobile: 28, tablet: 32, desktop: 36),
                  _buildSectionHeader(
                    responsive,
                    primary,
                    _t(
                      'Improvement Suggestions',
                      DetailedReportScreenSi.improvementSuggestions,
                    ),
                    Icons.lightbulb_rounded,
                  ),
                  ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                  _buildImprovementsCard(responsive),
                ],

                ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                // ── Actions ──────────────────────────────────────────────────
                _buildActionButtons(context, responsive, primary),

                ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Grade card
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildGradeCard(Responsive responsive, _GradeTheme theme) {
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
          // Grade badge
          Container(
            padding: responsive.padding(
              mobile: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              tablet: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              desktop: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
                  size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
                ),
                const SizedBox(width: 8),
                Text(
                  _grade.toUpperCase(),
                  style: TextStyle(
                    fontSize: responsive.fontSize(
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

          // Score circle
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
                  _scoreDisplay,
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
              DetailedReportScreenSi.overallQualityScore,
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

  // ───────────────────────────────────────────────────────────────────────────
  // Hard reject banner
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHardRejectBanner(Responsive responsive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
              ),
              const SizedBox(width: 8),
              Text(
                _t(
                  'HARD REJECT',
                  DetailedReportScreenSi.hardReject,
                ).toUpperCase(),
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.red.shade700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (_hardRejectReasons.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._hardRejectReasons.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.red.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: responsive.bodyFontSize - 1,
                          color: Colors.red.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Batch info card
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildBatchCard(Responsive responsive) {
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
            _t('Pepper Type', DetailedReportScreenSi.pepperType),
            _pepperTypeUi,
            Icons.grass_rounded,
          ),
          _buildDivider(responsive),
          _buildInfoRow(
            responsive,
            _t('Pepper Variety', DetailedReportScreenSi.pepperVariety),
            _varietyUi,
            Icons.local_florist_rounded,
          ),
          _buildDivider(responsive),
          _buildInfoRow(
            responsive,
            _t('Drying Method', DetailedReportScreenSi.dryingMethod),
            _dryingUi,
            Icons.wb_sunny_rounded,
          ),
          _buildDivider(responsive),
          _buildInfoRow(
            responsive,
            _t('Harvest Date', DetailedReportScreenSi.harvestDate),
            _harvestDateUi,
            Icons.calendar_today_rounded,
          ),
          _buildDivider(responsive),
          _buildInfoRow(
            responsive,
            _t('Batch Weight', DetailedReportScreenSi.batchWeight),
            _weightUi,
            Icons.scale_rounded,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Density card
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildDensityCard(Responsive responsive) {
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
            _t('Measured Density', DetailedReportScreenSi.measuredDensity),
            _densityUi,
            Icons.compress_rounded,
          ),
          _buildDivider(responsive),
          _buildInfoRow(
            responsive,
            _t('Density Score', DetailedReportScreenSi.densityScore),
            '${_asInt(_factorScores['density'])} / 100',
            Icons.speed_rounded,
          ),
          _buildDivider(responsive),
          _buildInfoRow(
            responsive,
            _t('Measured At', DetailedReportScreenSi.measuredAt),
            _formatDateIso(_density['measuredAt']),
            Icons.access_time_rounded,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Certificates card
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildCertificatesCard(Responsive responsive) {
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
                  DetailedReportScreenSi.noCertificates,
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
                              '${_t('No', DetailedReportScreenSi.certNo)}: $number',
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
                          '${_t('Exp', DetailedReportScreenSi.certExp)}: ${_formatDateIso(cert["expiryDate"])}',
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

  // ───────────────────────────────────────────────────────────────────────────
  // Raw AI measurements
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildRawFactorsCard(Responsive responsive) {
    Widget pctRow(
      String label,
      dynamic value,
      IconData icon, {
      bool isLast = false,
    }) {
      final pct = _asDouble(value);
      return Column(
        children: [
          Padding(
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
                ResponsiveSpacing.horizontal(
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
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
                Text(
                  '${pct.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) _buildDivider(responsive),
        ],
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
          pctRow(
            _t('Adulterant Seeds', DetailedReportScreenSi.adulterantSeeds),
            _factors['adulterantPct'],
            Icons.warning_amber_rounded,
          ),
          pctRow(
            _t('Extraneous Matter', DetailedReportScreenSi.extraneousMatter),
            _factors['extraneousPct'],
            Icons.grass_rounded,
          ),
          pctRow(
            _t('Mold', DetailedReportScreenSi.mold),
            _factors['moldPct'],
            Icons.blur_on_rounded,
          ),
          pctRow(
            _t(
              'Broken / Abnormal Texture',
              DetailedReportScreenSi.brokenAbnormal,
            ),
            _factors['abnormalTexturePct'],
            Icons.broken_image_rounded,
          ),
          pctRow(
            _t('Healthy Visual', DetailedReportScreenSi.healthyVisual),
            _factors['healthyVisualPct'],
            Icons.check_circle_rounded,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Improvement suggestions
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildImprovementsCard(Responsive responsive) {
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
      child: Column(
        children: _improvements
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
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
                        Icons.lightbulb_rounded,
                        color: Colors.blue.shade700,
                        size: responsive.value(
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                      ),
                    ),
                    ResponsiveSpacing.horizontal(
                      mobile: 12,
                      tablet: 14,
                      desktop: 16,
                    ),
                    Expanded(
                      child: Text(
                        t,
                        style: TextStyle(
                          fontSize: responsive.bodyFontSize,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Action buttons
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildActionButtons(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    return Column(
      children: [
        // Download PDF
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
            child: _downloading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.download_rounded,
                        size: responsive.smallIconSize,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _t(
                            'Download Report (PDF)',
                            DetailedReportScreenSi.downloadPdf,
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: responsive.titleFontSize,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),

        // How it works
        Container(
          width: double.infinity,
          height: responsive.buttonHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: primary, width: 2),
          ),
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
            ),
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
                Expanded(
                  child: Text(
                    _t(
                      'How is Quality Calculated?',
                      DetailedReportScreenSi.howQualityCalculated,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: responsive.titleFontSize,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Shared widget helpers
  // ───────────────────────────────────────────────────────────────────────────

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

  // ───────────────────────────────────────────────────────────────────────────
  // PDF helpers
  // ───────────────────────────────────────────────────────────────────────────

  String _pdfFileName() => 'pepper_report_$_batchId.pdf';

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
                _t('PDF downloaded', DetailedReportScreenSi.pdfDownloaded),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_t('Saved', DetailedReportScreenSi.saved)}: $fileName',
            ),
          ),
        );
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
        ], text: 'Ceylon Pepper Quality Report ($_batchId)');
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
      ], text: 'Ceylon Pepper Quality Report ($_batchId)');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }
}
