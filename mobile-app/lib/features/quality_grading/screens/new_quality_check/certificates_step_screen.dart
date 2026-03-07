import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/api.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/language_prefs.dart';
import '../../../../utils/quality_grading/certificates_step_screen_si.dart';
import '../../../certifications/models/certification_model.dart';
import '../../../certifications/screens/farmer_add_certifications_screen.dart';
import '../../../certifications/services/certification_api.dart';
import '../../services/quality_check_api.dart';
import 'image_upload_screen.dart';

Color _withOpacity(Color c, double opacity) {
  return c.withAlpha((opacity * 255).round().clamp(0, 255));
}

class CertificatesStepScreen extends StatefulWidget {
  final String qualityCheckId;
  final String batchId;

  const CertificatesStepScreen({
    super.key,
    required this.qualityCheckId,
    required this.batchId,
  });

  @override
  State<CertificatesStepScreen> createState() => _CertificatesStepScreenState();
}

class _CertificatesStepScreenState extends State<CertificatesStepScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  String _currentLanguage = 'en';
  List<Map<String, dynamic>> _certs = [];

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final CertificationApi _certApi;

  bool get _isSinhala => _currentLanguage == 'si';
  String _t(String english, String sinhala) => _isSinhala ? sinhala : english;

  static const _primary = Color(0xFF2E7D32);
  static const _primaryDark = Color(0xFF1B5E20);
  static const _primaryLight = Color(0xFF388E3C);

  @override
  void initState() {
    super.initState();
    _certApi = CertificationApi(baseUrl: ApiConfig.baseUrl);

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

    _loadCerts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCerts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = QualityCheckApi();
      final allVerified = await api.getMyVerifiedCertifications();
      final valid = allVerified.where((c) => c["isExpired"] != true).toList();
      if (!mounted) return;
      setState(() {
        _certs = valid;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmtDate(dynamic dateStr) {
    if (dateStr == null) return "-";
    final s = dateStr.toString();
    try {
      final d = DateTime.parse(s).toLocal();
      return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    } catch (_) {
      return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // ── Sticky Continue Button at bottom ──────────────────────────────
      bottomNavigationBar: _buildBottomContinueBar(responsive),
      appBar: _buildAppBar(responsive),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero header with step indicator
              _buildHeroHeader(responsive),

              const SizedBox(height: 20),

              SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.pagePadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SL-GAP Banner
                      _buildSlGapBanner(responsive),

                      const SizedBox(height: 20),

                      // Section label + Add & Refresh actions
                      _buildCertSectionHeader(responsive),

                      const SizedBox(height: 14),

                      // Cert list / states
                      _buildCertContent(responsive),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(Responsive responsive) {
    return AppBar(
      backgroundColor: _primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _t("Certificates", CertificatesStepScreenSi.certificates),
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  // ── Hero Header (gradient + step bar) ────────────────────────────────────
  Widget _buildHeroHeader(Responsive responsive) {
    return Container(
      width: double.infinity,
      padding: responsive.padding(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(20),
        desktop: const EdgeInsets.all(24),
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStepBubble(1, true, responsive),
              _buildStepConnector(true),
              _buildStepBubble(2, true, responsive),
              _buildStepConnector(true),
              _buildStepBubble(3, true, responsive),
              _buildStepConnector(false),
              _buildStepBubble(4, false, responsive),
            ],
          ),
          ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
          Text(
            _t(
              "Verified Certificates",
              CertificatesStepScreenSi.verifiedCertificates,
            ),
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 22,
                tablet: 24,
                desktop: 26,
              ),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          ResponsiveSpacing(mobile: 4, tablet: 6, desktop: 8),
          Text(
            _t(
              "Only verified and not expired certificates will be used for grading.",
              CertificatesStepScreenSi.headerSubtitle,
            ),
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBubble(int step, bool isActive, Responsive responsive) {
    final isCompleted = step < 3;
    final size = responsive.value(mobile: 34.0, tablet: 38.0, desktop: 42.0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isActive || isCompleted ? _primary : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: responsive.value(
                  mobile: 18.0,
                  tablet: 20.0,
                  desktop: 22.0,
                ),
              )
            : Text(
                '$step',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: responsive.bodyFontSize,
                ),
              ),
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? _primary : Colors.grey[300],
      ),
    );
  }

  // ── Section header (label + actions) ─────────────────────────────────────
  Widget _buildCertSectionHeader(Responsive responsive) {
    return Row(
      children: [
        // Accent bar + label
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _t("My Certificates", "මගේ සහතික"),
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 17,
                tablet: 19,
                desktop: 21,
              ),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        // Refresh icon button
        Tooltip(
          message: _t("Refresh", CertificatesStepScreenSi.refresh),
          child: InkWell(
            onTap: _loadCerts,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: responsive.smallIconSize,
                color: Colors.grey[700],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Add certificate button
        InkWell(
          onTap: () async {
            await Navigator.push<CertificationModel>(
              context,
              MaterialPageRoute(
                builder: (_) => FarmerAddCertificationScreen(api: _certApi),
              ),
            );
            _loadCerts();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _withOpacity(const Color(0xFF1565C0), 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 5),
                Text(
                  _t("Add", CertificatesStepScreenSi.addCertificate),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: responsive.fontSize(
                      mobile: 13,
                      tablet: 14,
                      desktop: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Cert list / loading / error / empty states ────────────────────────────
  Widget _buildCertContent(Responsive responsive) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade700,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  color: Colors.red.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_certs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: Colors.orange.shade800,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t("No Certificates Found", "සහතික හමු නොවීය"),
                    style: TextStyle(
                      fontSize: responsive.bodyFontSize,
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _t(
                      "You can still continue, but certificate bonus will be 0.",
                      CertificatesStepScreenSi.noCertificatesFound,
                    ),
                    style: TextStyle(
                      fontSize: responsive.bodyFontSize - 1,
                      color: Colors.orange.shade800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _certs.map((c) {
        final type = (c["certificationType"] ?? "-").toString();
        final num = (c["certificateNumber"] ?? "-").toString();
        final body = (c["issuingBody"] ?? "-").toString();
        final issue = _fmtDate(c["issueDate"]);
        final exp = _fmtDate(c["expiryDate"]);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Card header accent bar
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryDark, _primaryLight],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
              ),
              Padding(
                padding: responsive.padding(
                  mobile: const EdgeInsets.all(16),
                  tablet: const EdgeInsets.all(18),
                  desktop: const EdgeInsets.all(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.verified_rounded,
                            color: _primary,
                            size: responsive.mediumIconSize,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: responsive.titleFontSize,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        // Verified chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _withOpacity(_primary, 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _t("Verified", "සත්‍යාපිතයි"),
                            style: TextStyle(
                              fontSize: 11,
                              color: _primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Divider
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 12),
                    // Details grid
                    _certDetailRow(
                      Icons.tag_rounded,
                      _t("Cert No.", CertificatesStepScreenSi.certificateNo),
                      num,
                      responsive,
                      bold: true,
                    ),
                    const SizedBox(height: 8),
                    _certDetailRow(
                      Icons.account_balance_rounded,
                      _t("Issuing Body", CertificatesStepScreenSi.issuingBody),
                      body,
                      responsive,
                    ),
                    const SizedBox(height: 10),
                    // Date row
                    Row(
                      children: [
                        Expanded(
                          child: _certDateChip(
                            Icons.calendar_today_rounded,
                            _t("Issued", CertificatesStepScreenSi.issue),
                            issue,
                            Colors.blue.shade50,
                            Colors.blue.shade700,
                            responsive,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _certDateChip(
                            Icons.event_busy_rounded,
                            _t("Expires", CertificatesStepScreenSi.expiry),
                            exp,
                            Colors.red.shade50,
                            Colors.red.shade700,
                            responsive,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _certDetailRow(
    IconData icon,
    String label,
    String value,
    Responsive responsive, {
    bool bold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: responsive.bodyFontSize - 1,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: responsive.bodyFontSize - 1,
              color: Colors.black87,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _certDateChip(
    IconData icon,
    String label,
    String value,
    Color bg,
    Color fg,
    Responsive responsive,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize - 2,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SL-GAP Promotional Banner ─────────────────────────────────────────────
  Widget _buildSlGapBanner(Responsive responsive) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryDark, _primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _withOpacity(_primary, 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: responsive.padding(
              mobile: const EdgeInsets.all(18),
              tablet: const EdgeInsets.all(22),
              desktop: const EdgeInsets.all(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _t(
                          "Sri Lanka Good Agricultural Practices",
                          "ශ්‍රී ලංකා හොඳ කෘෂිකාර්මික භාවිතයන්",
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _t(
                    "Boost Your Pepper's Market Value",
                    "ඔබේ ගම්මිරිස් වල වෙළඳ වටිනාකම වැඩි කරන්න",
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.fontSize(
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t(
                    "Get SL-GAP certified and earn a higher quality grade. Certified farms receive better prices, export market access, and a grading bonus.",
                    "SL-GAP සහතිකය ලබාගෙන ඉහළ ශ්‍රේණිගත කිරීමක් ලබාගන්න. සහතිකලාභී ගොවීන්ට වඩා හොඳ මිල, අපනයන ප්‍රවේශය සහ ශ්‍රේණිගත ප්‍රසාදය ලැබේ.",
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.88),
                    fontSize: responsive.fontSize(
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _benefitChip(
                      Icons.trending_up_rounded,
                      _t("Better Prices", "වඩා හොඳ මිල"),
                    ),
                    _benefitChip(
                      Icons.public_rounded,
                      _t("Export Ready", "අපනයනයට සූදානම්"),
                    ),
                    _benefitChip(
                      Icons.star_rounded,
                      _t("Quality Bonus", "ගුණාත්මකතා ප්‍රසාදය"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => launchUrl(
                    Uri.parse('https://doa.gov.lk/scs-gap-certification/'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.open_in_new_rounded,
                          color: _primaryDark,
                          size: 15,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _t(
                            "Learn how to apply for SL-GAP",
                            "SL-GAP සඳහා ඉල්ලුම් කරන ආකාරය",
                          ),
                          style: TextStyle(
                            color: _primaryDark,
                            fontWeight: FontWeight.w700,
                            fontSize: responsive.fontSize(
                              mobile: 12,
                              tablet: 13,
                              desktop: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky bottom continue bar ────────────────────────────────────────────
  Widget _buildBottomContinueBar(Responsive responsive) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        responsive.pagePadding,
        12,
        responsive.pagePadding,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // cert count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_certs.length}',
                  style: TextStyle(
                    fontSize: responsive.fontSize(
                      mobile: 16,
                      tablet: 18,
                      desktop: 20,
                    ),
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                ),
                Text(
                  _t("certs", "සහතික"),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Continue button
          Expanded(
            child: SizedBox(
              height: responsive.buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageUploadScreen(
                        qualityCheckId: widget.qualityCheckId,
                        batchId: widget.batchId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: _withOpacity(_primary, 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _t(
                        "Continue to Image Upload",
                        CertificatesStepScreenSi.continueToImageUpload,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: responsive.titleFontSize,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: responsive.smallIconSize,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
