import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/language_prefs.dart';
import '../../../../../utils/quality_grading/review_and_confirm_screen_si.dart';
import '../../services/quality_check_api.dart';
import 'processing_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ImageStore
// ─────────────────────────────────────────────────────────────────────────────
class ImageStore {
  ImageStore._();
  static final ImageStore instance = ImageStore._();

  Map<String, File?> images = {
    'bottom_full': null,
    'bottom_half': null,
    'bottom_close': null,
    'middle_full': null,
    'middle_half': null,
    'middle_close': null,
    'top_full': null,
    'top_half': null,
    'top_close': null,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
String _formatPepperType(String? v, {bool sinhala = false}) {
  switch (v?.toLowerCase()) {
    case 'black':
      return sinhala ? ReviewAndConfirmScreenSi.blackPepper : 'Black Pepper';
    case 'white':
      return sinhala ? ReviewAndConfirmScreenSi.whitePepper : 'White Pepper';
    default:
      return v ?? '—';
  }
}

String _formatVariety(String? v) {
  // Variety names are proper names — kept in English regardless of language.
  switch (v?.toLowerCase()) {
    case 'ceylon_pepper':
      return 'Ceylon Pepper';
    case 'panniyur_1':
      return 'Panniyur 1';
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
    default:
      return v?.replaceAll('_', ' ') ?? '—';
  }
}

String _formatDryingMethod(String? v, {bool sinhala = false}) {
  switch (v?.toLowerCase()) {
    case 'sun_dried':
      return sinhala ? ReviewAndConfirmScreenSi.sunDried : 'Sun Dried';
    case 'machine_dried':
      return sinhala ? ReviewAndConfirmScreenSi.machineDried : 'Machine Dried';
    default:
      return v?.replaceAll('_', ' ') ?? '—';
  }
}

String _formatWeight(dynamic grams) {
  if (grams == null) return '—';
  final g = (grams as num).toInt();
  final kg = g ~/ 1000;
  final rem = g % 1000;
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

String _formatDate(dynamic raw) {
  if (raw == null) return '';
  try {
    final dt = DateTime.parse(raw.toString()).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  } catch (_) {
    return '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SummaryConfirmationScreen
// ─────────────────────────────────────────────────────────────────────────────
class SummaryConfirmationScreen extends StatefulWidget {
  final Map<String, File?> images;
  final String qualityCheckId;
  final String batchId;

  const SummaryConfirmationScreen({
    super.key,
    required this.images,
    required this.qualityCheckId,
    required this.batchId,
  });

  @override
  State<SummaryConfirmationScreen> createState() =>
      _SummaryConfirmationScreenState();
}

class _SummaryConfirmationScreenState extends State<SummaryConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _qcData;
  List<Map<String, dynamic>> _liveCerts = [];
  String _currentLanguage = 'en';

  bool get _isSinhala => _currentLanguage == 'si';
  String _t(String english, String sinhala) => _isSinhala ? sinhala : english;

  @override
  void initState() {
    super.initState();
    ImageStore.instance.images = Map.from(widget.images);

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

    _loadAll();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── Data loading ─────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = QualityCheckApi();

      final results = await Future.wait([
        api.getQualityCheckById(qualityCheckId: widget.qualityCheckId),
        api.getMyVerifiedCertifications(),
      ]);

      final allVerified = (results[1] as List<dynamic>).cast<Map<String, dynamic>>();
      final validCerts = allVerified.where((c) {
        final isExpired = c["isExpired"] == true;
        return !isExpired;
      }).toList();

      if (!mounted) return;
      setState(() {
        _qcData = results[0] as Map<String, dynamic>;
        _liveCerts = validCerts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    const primary = Color(0xFF2E7D32);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: primary,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            _t('Review & Confirm', ReviewAndConfirmScreenSi.reviewAndConfirm),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: _isLoading
            ? _buildLoader(primary)
            : _errorMessage != null
            ? _buildError(responsive, primary)
            : _buildContent(responsive, primary),
      ),
    );
  }

  // ── Loading ──────────────────────────────────────────────────────────────

  Widget _buildLoader(Color primary) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: primary),
        const SizedBox(height: 16),
        Text(
          _t(
            'Loading review data…',
            ReviewAndConfirmScreenSi.loadingReviewData,
          ),
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );

  // ── Error ────────────────────────────────────────────────────────────────

  Widget _buildError(Responsive responsive, Color primary) => Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.red.shade400,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            _t(
              'Failed to load review data',
              ReviewAndConfirmScreenSi.failedToLoad,
            ),
            style: TextStyle(
              fontSize: responsive.titleFontSize,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? '',
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(_t('Retry', ReviewAndConfirmScreenSi.retry)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Content ──────────────────────────────────────────────────────────────

  Widget _buildContent(Responsive responsive, Color primary) {
    final batch = _qcData?['batch'] as Map<String, dynamic>? ?? {};
    final density = _qcData?['density'] as Map<String, dynamic>? ?? {};

    final pepperType = _formatPepperType(
      batch['pepperType'] as String?,
      sinhala: _isSinhala,
    );
    final pepperVariety = _formatVariety(batch['pepperVariety'] as String?);
    final dryingMethod = _formatDryingMethod(
      batch['dryingMethod'] as String?,
      sinhala: _isSinhala,
    );
    final batchWeight = _formatWeight(batch['batchWeightGrams']);
    final densityValue = density['value'];
    final densityDisplay = densityValue != null
        ? '${densityValue.toString()} g/L'
        : '—';

    return FadeTransition(
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
                    // ── Batch Information ──────────────────────────────
                    _buildSectionHeader(
                      responsive,
                      primary,
                      _t(
                        'Batch Information',
                        ReviewAndConfirmScreenSi.batchInformation,
                      ),
                      Icons.info_rounded,
                    ),
                    ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                    _buildCard(
                      responsive,
                      children: [
                        _buildInfoRow(
                          responsive,
                          _t(
                            'Pepper Type',
                            ReviewAndConfirmScreenSi.pepperType,
                          ),
                          pepperType,
                          Icons.grass_rounded,
                        ),
                        _buildDivider(responsive),
                        _buildInfoRow(
                          responsive,
                          _t(
                            'Pepper Variety',
                            ReviewAndConfirmScreenSi.pepperVariety,
                          ),
                          pepperVariety,
                          Icons.local_florist_rounded,
                        ),
                        _buildDivider(responsive),
                        _buildInfoRow(
                          responsive,
                          _t(
                            'Drying Method',
                            ReviewAndConfirmScreenSi.dryingMethod,
                          ),
                          dryingMethod,
                          Icons.wb_sunny_rounded,
                        ),
                        _buildDivider(responsive),
                        _buildInfoRow(
                          responsive,
                          _t(
                            'Batch Weight',
                            ReviewAndConfirmScreenSi.batchWeight,
                          ),
                          batchWeight,
                          Icons.scale_rounded,
                          isLast: true,
                        ),
                      ],
                    ),

                    ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                    // ── Bulk Density ───────────────────────────────────
                    _buildSectionHeader(
                      responsive,
                      primary,
                      _t('Bulk Density', ReviewAndConfirmScreenSi.bulkDensity),
                      Icons.science_rounded,
                    ),
                    ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                    _buildCard(
                      responsive,
                      children: [
                        _buildInfoRow(
                          responsive,
                          _t(
                            'Measured Density',
                            ReviewAndConfirmScreenSi.measuredDensity,
                          ),
                          densityDisplay,
                          Icons.analytics_rounded,
                        ),
                        _buildDivider(responsive),
                        _buildInfoRow(
                          responsive,
                          _t('Status', ReviewAndConfirmScreenSi.status),
                          densityValue != null
                              ? _t(
                                  'Verified',
                                  ReviewAndConfirmScreenSi.verified,
                                )
                              : _t(
                                  'Not recorded',
                                  ReviewAndConfirmScreenSi.notRecorded,
                                ),
                          Icons.check_circle_rounded,
                          valueColor: densityValue != null
                              ? Colors.green.shade700
                              : Colors.red.shade600,
                          isLast: true,
                        ),
                      ],
                    ),

                    ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                    // ── Certificates ───────────────────────────────────
                    _buildSectionHeader(
                      responsive,
                      primary,
                      _t('Certificates', ReviewAndConfirmScreenSi.certificates),
                      Icons.verified_rounded,
                    ),
                    ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                    _buildCertificatesSection(responsive),

                    ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                    // ── Captured Images ────────────────────────────────
                    _buildSectionHeader(
                      responsive,
                      primary,
                      _t(
                        'Captured Images',
                        ReviewAndConfirmScreenSi.capturedImages,
                      ),
                      Icons.photo_library_rounded,
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                    _buildImagesCard(responsive),

                    ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                    _buildActionButtons(responsive, primary),

                    ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Certificates section ─────────────────────────────────────────────────

  Widget _buildCertificatesSection(Responsive responsive) {
    if (_liveCerts.isEmpty) {
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
                  'No verified certificates found. You can still proceed — certificates are optional.',
                  ReviewAndConfirmScreenSi.noCertificatesFound,
                ),
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final count = _liveCerts.length;
    final certCountLabel = _isSinhala
        ? '$count ${count == 1 ? ReviewAndConfirmScreenSi.verifiedCertificate : ReviewAndConfirmScreenSi.verifiedCertificates}'
        : '$count verified certificate${count == 1 ? '' : 's'} will be included';

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
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade600,
                size: responsive.smallIconSize,
              ),
              const SizedBox(width: 8),
              Text(
                certCountLabel,
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...List.generate(_liveCerts.length, (i) {
            final cert = _liveCerts[i];
            final type = _formatCertType(cert['certificationType'] as String?);
            final number = (cert['certificateNumber'] as String? ?? '').trim();
            final issuer = (cert['issuingBody'] as String? ?? '').trim();
            final expiry = _formatDate(cert['expiryDate']);
            final isLast = i == _liveCerts.length - 1;

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
                                '${_t('No:', ReviewAndConfirmScreenSi.certNo)} $number',
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
                      if (expiry.isNotEmpty)
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
                            '${_t('Exp:', ReviewAndConfirmScreenSi.expLabel)} $expiry',
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
        ],
      ),
    );
  }

  // ── Action buttons ───────────────────────────────────────────────────────

  Widget _buildActionButtons(Responsive responsive, Color primary) {
    final isNarrow =
        responsive.isMobile && MediaQuery.of(context).size.width < 380;

    final backBtn = Container(
      height: responsive.value(mobile: 60, tablet: 64, desktop: 68),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade700,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _buttonContent(
          responsive: responsive,
          text: _t('Back to Edit', ReviewAndConfirmScreenSi.backToEdit),
          leadingIcon: Icons.edit_rounded,
          textColor: Colors.grey.shade700,
        ),
      ),
    );

    final confirmBtn = Container(
      height: responsive.value(mobile: 60, tablet: 64, desktop: 68),
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
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProcessingScreen(
              images: widget.images,
              qualityCheckId: widget.qualityCheckId,
              batchId: widget.batchId,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _buttonContent(
          responsive: responsive,
          text: _t('Confirm', ReviewAndConfirmScreenSi.confirm),
          leadingIcon: Icons.check_circle_rounded,
          trailingIcon: Icons.arrow_forward_rounded,
          textColor: Colors.white,
        ),
      ),
    );

    if (isNarrow) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: confirmBtn),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: backBtn),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: backBtn),
        ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
        Expanded(child: confirmBtn),
      ],
    );
  }

  Widget _buttonContent({
    required Responsive responsive,
    required String text,
    required IconData leadingIcon,
    IconData? trailingIcon,
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(leadingIcon, size: responsive.smallIconSize, color: textColor),
        const SizedBox(width: 8),

        // IMPORTANT: allow wrapping/shrinking
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
          Icon(trailingIcon, size: responsive.smallIconSize, color: textColor),
        ],
      ],
    );
  }

  // ── Images card ──────────────────────────────────────────────────────────

  Widget _buildImagesCard(Responsive responsive) {
    final capturedCount = widget.images.values.whereType<File>().length;

    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.all(12),
        tablet: const EdgeInsets.all(14),
        desktop: const EdgeInsets.all(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade600,
                size: responsive.smallIconSize,
              ),
              ResponsiveSpacing.horizontal(mobile: 8, tablet: 10, desktop: 12),
              Text(
                _isSinhala
                    ? 'රූප $capturedCount ${ReviewAndConfirmScreenSi.imagesCaptured}'
                    : '$capturedCount images captured',
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
          _buildImageGrid(responsive),
        ],
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  Widget _buildCard(Responsive responsive, {required List<Widget> children}) {
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
    Color? valueColor,
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
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
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

  Widget _buildImageGrid(Responsive responsive) {
    final imageFiles = widget.images.values.whereType<File>().toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsive.isDesktop
            ? 5
            : (responsive.isTablet ? 4 : 3),
        crossAxisSpacing: responsive.value(mobile: 8, tablet: 10, desktop: 12),
        mainAxisSpacing: responsive.value(mobile: 8, tablet: 10, desktop: 12),
      ),
      itemCount: imageFiles.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFiles[index],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.shade500,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: responsive.value(mobile: 12, tablet: 13, desktop: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
