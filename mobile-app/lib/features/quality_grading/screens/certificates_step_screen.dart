import 'package:flutter/material.dart';
import '../../../config/api.dart';
import '../../../utils/responsive.dart';
import '../../certifications/models/certification_model.dart';
import '../../certifications/screens/farmer_add_certifications_screen.dart';
import '../../certifications/services/certification_api.dart';
import '../services/quality_check_api.dart';
import 'image_upload_screen.dart';

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

  List<Map<String, dynamic>> _certs = [];

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  late final CertificationApi _certApi;

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

      // backend provides isExpired + effectiveStatus
      final valid = allVerified.where((c) {
        final isExpired = c["isExpired"] == true;
        return !isExpired;
      }).toList();

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
    // expects ISO string
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
          "Certificates",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
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
                    // Step indicator (4 steps) step3 active
                    Row(
                      children: [
                        _buildStepIndicator(1, true, primary, responsive),
                        _buildStepLine(true, primary, responsive),
                        _buildStepIndicator(2, true, primary, responsive),
                        _buildStepLine(true, primary, responsive),
                        _buildStepIndicator(3, true, primary, responsive),
                        _buildStepLine(false, primary, responsive),
                        _buildStepIndicator(4, false, primary, responsive),
                      ],
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                    Text(
                      "Verified Certificates",
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
                      "Only verified and not expired certificates will be used for grading.",
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

              SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.pagePadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Actions row
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              responsive: responsive,
                              color: Colors.blue.shade600,
                              icon: Icons.add_rounded,
                              label: "Add Certificate",
                              onPressed: () async {
                                final created =
                                    await Navigator.push<CertificationModel>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            FarmerAddCertificationScreen(
                                              api: _certApi,
                                            ),
                                      ),
                                    );

                                _loadCerts();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _loadCerts,
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: "Refresh",
                          ),
                        ],
                      ),

                      ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                      if (_loading)
                        const Center(child: CircularProgressIndicator())
                      else if (_error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              fontSize: responsive.bodyFontSize,
                              color: Colors.red.shade800,
                            ),
                          ),
                        )
                      else if (_certs.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "No verified certificates found. You can still continue, but certificate bonus will be 0.",
                                  style: TextStyle(
                                    fontSize: responsive.bodyFontSize,
                                    color: Colors.orange.shade900,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _certs.map((c) {
                            final type = (c["certificationType"] ?? "-")
                                .toString();
                            final num = (c["certificateNumber"] ?? "-")
                                .toString();
                            final body = (c["issuingBody"] ?? "-").toString();
                            final issue = _fmtDate(c["issueDate"]);
                            final exp = _fmtDate(c["expiryDate"]);

                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: responsive.padding(
                                mobile: const EdgeInsets.all(16),
                                tablet: const EdgeInsets.all(18),
                                desktop: const EdgeInsets.all(20),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
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
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.verified_rounded,
                                          color: Colors.green.shade700,
                                          size: responsive.mediumIconSize,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          type,
                                          style: TextStyle(
                                            fontSize: responsive.titleFontSize,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Certificate No: $num",
                                    style: TextStyle(
                                      fontSize: responsive.bodyFontSize,
                                      color: Colors.grey[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Issuing body: $body",
                                    style: TextStyle(
                                      fontSize: responsive.bodyFontSize - 1,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Issue: $issue",
                                          style: TextStyle(
                                            fontSize:
                                                responsive.bodyFontSize - 1,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "Expiry: $exp",
                                          textAlign: TextAlign.end,
                                          style: TextStyle(
                                            fontSize:
                                                responsive.bodyFontSize - 1,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                      ResponsiveSpacing(mobile: 18, tablet: 20, desktop: 22),

                      // Continue button to Step 4
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
                              Text(
                                "Continue to Image Upload",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: responsive.titleFontSize,
                                  letterSpacing: 0.5,
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

                      ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
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

  Widget _buildActionButton({
    required Responsive responsive,
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: responsive.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: responsive.smallIconSize),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: responsive.titleFontSize,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(
    int step,
    bool isActive,
    Color primary,
    Responsive responsive,
  ) {
    final isCompleted = step < 3;
    return Container(
      width: responsive.value(mobile: 32, tablet: 36, desktop: 40),
      height: responsive.value(mobile: 32, tablet: 36, desktop: 40),
      decoration: BoxDecoration(
        color: isActive || isCompleted ? primary : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
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

  Widget _buildStepLine(bool isActive, Color primary, Responsive responsive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: EdgeInsets.symmetric(
          horizontal: responsive.value(mobile: 8, tablet: 10, desktop: 12),
        ),
        color: isActive ? primary : Colors.grey[300],
      ),
    );
  }
}
