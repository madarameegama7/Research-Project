import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/certification_model.dart';
import '../services/certification_api.dart';
import '../../../utils/responsive.dart';
import 'farmer_edit_certification_screen.dart';

// Helper to create a Color from an existing Color with a custom opacity (0.0-1.0)
Color colorWithOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

class FarmerCertificationDetailsScreen extends StatefulWidget {
  final String certId;
  final CertificationApi api;

  const FarmerCertificationDetailsScreen({
    super.key,
    required this.certId,
    required this.api,
  });

  @override
  State<FarmerCertificationDetailsScreen> createState() =>
      _FarmerCertificationDetailsScreenState();
}

class _FarmerCertificationDetailsScreenState
    extends State<FarmerCertificationDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF2E7D32);

  bool _loading = true;
  String? _error;
  CertificationModel? _cert;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _load();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final c = await widget.api.getById(widget.certId);
      setState(() {
        _cert = c;
        _loading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool get _canEdit {
    final c = _cert;
    if (c == null) return false;
    return c.status == 'pending' && c.isExpired == false;
  }

  Future<void> _openEdit() async {
    final c = _cert;
    if (c == null) return;

    if (!_canEdit) {
      _toast('This certificate cannot be edited.');
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FarmerEditCertificationScreen(api: widget.api, initial: c),
      ),
    );

    if (changed == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Updated successfully'),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final c = _cert;
    if (c == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Certificate',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this certificate? This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await widget.api.deleteCertification(c.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Certificate deleted'),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _openAttachment() async {
    final c = _cert;
    if (c == null) return;
    if (!c.attachment.hasFile) {
      _toast('No attachment');
      return;
    }

    final url = Uri.tryParse(c.attachment.url!.trim());
    if (url == null) {
      _toast('Invalid attachment URL');
      return;
    }

    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) _toast('Cannot open attachment');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(responsive),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_primary),
                      ),
                    )
                  : _error != null
                  ? _errorState(responsive)
                  : _cert == null
                  ? _notFoundState(responsive)
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(
                            responsive.value(
                              mobile: 16,
                              tablet: 24,
                              desktop: 32,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailsCard(responsive),
                              ResponsiveSpacing(
                                mobile: 16,
                                tablet: 20,
                                desktop: 24,
                              ),

                              if (_cert!.attachment.hasFile) ...[
                                _buildAttachmentCard(responsive),
                                ResponsiveSpacing(
                                  mobile: 16,
                                  tablet: 20,
                                  desktop: 24,
                                ),
                              ],

                              if (_hasExtraInfo()) ...[
                                _buildExtraInfoCard(responsive),
                                ResponsiveSpacing(
                                  mobile: 16,
                                  tablet: 20,
                                  desktop: 24,
                                ),
                              ],

                              _buildActionButtons(responsive),
                              ResponsiveSpacing(
                                mobile: 24,
                                tablet: 32,
                                desktop: 40,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasExtraInfo() {
    final c = _cert;
    if (c == null) return false;
    return c.verifiedBy != null ||
        c.verificationDate != null ||
        (c.status == 'rejected' && (c.rejectionReason ?? '').trim().isNotEmpty);
  }

  Widget _buildHeader(Responsive responsive) {
    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        tablet: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        desktop: const EdgeInsets.fromLTRB(40, 28, 40, 36),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, colorWithOpacity(_primary, 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            responsive.value(mobile: 28, tablet: 36, desktop: 40),
          ),
          bottomRight: Radius.circular(
            responsive.value(mobile: 28, tablet: 36, desktop: 40),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(_primary, 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(
                responsive.value(mobile: 8, tablet: 10, desktop: 12),
              ),
              decoration: BoxDecoration(
                color: colorWithOpacity(Colors.white, 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
              ),
            ),
          ),
          ResponsiveSpacing.horizontal(mobile: 14, tablet: 16, desktop: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certificate Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.fontSize(
                      mobile: 20,
                      tablet: 24,
                      desktop: 28,
                    ),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_cert != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _cert!.certificationType,
                    style: TextStyle(
                      color: colorWithOpacity(Colors.white, 0.8),
                      fontSize: responsive.fontSize(
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: EdgeInsets.all(
                responsive.value(mobile: 8, tablet: 10, desktop: 12),
              ),
              decoration: BoxDecoration(
                color: colorWithOpacity(Colors.white, 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(Responsive responsive) {
    final c = _cert!;

    return Container(
      width: double.infinity,
      padding: responsive.padding(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(20),
        desktop: const EdgeInsets.all(24),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        border: Border.all(color: colorWithOpacity(_primary, 0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(
                  responsive.value(mobile: 10, tablet: 12, desktop: 14),
                ),
                decoration: BoxDecoration(
                  color: colorWithOpacity(_primary, 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified_outlined,
                  color: _primary,
                  size: responsive.value(mobile: 24, tablet: 26, desktop: 28),
                ),
              ),
              ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.certificationType,
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                          mobile: 17,
                          tablet: 19,
                          desktop: 21,
                        ),
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _statusChip(c.effectiveStatus, responsive),
                  ],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(mobile: 18, tablet: 20, desktop: 22),
          Divider(height: 1, color: colorWithOpacity(_primary, 0.08)),
          ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

          _buildSectionLabel(responsive, 'Certificate Information'),
          ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),

          _infoRow(
            responsive,
            Icons.confirmation_number_outlined,
            'Certificate No.',
            c.certificateNumber,
          ),
          _infoRow(
            responsive,
            Icons.account_balance_outlined,
            'Issuing Body',
            c.issuingBody,
          ),
          _infoRow(
            responsive,
            Icons.event_outlined,
            'Issue Date',
            _formatDate(c.issueDate),
          ),
          _infoRow(
            responsive,
            Icons.event_available_outlined,
            'Expiry Date',
            _formatDate(c.expiryDate),
            isLast: true,
          ),

          ResponsiveSpacing(mobile: 14, tablet: 16, desktop: 18),
          Divider(height: 1, color: colorWithOpacity(_primary, 0.08)),
          ResponsiveSpacing(mobile: 14, tablet: 16, desktop: 18),

          _buildSectionLabel(responsive, 'Submission Timeline'),
          ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),

          _infoRow(
            responsive,
            Icons.schedule_outlined,
            'Submitted On',
            _formatDate(c.createdAt),
          ),
          _infoRow(
            responsive,
            Icons.update_outlined,
            'Last Updated',
            _formatDate(c.updatedAt),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(Responsive responsive) {
    final c = _cert!;

    final rawName = (c.attachment.originalName ?? '').trim();
    final name = rawName.isNotEmpty
        ? rawName
        : (c.attachment.isPdf ? 'Document' : 'Image');

    final typeText = c.attachment.isPdf ? 'PDF document' : 'Image file';

    return Container(
      width: double.infinity,
      padding: responsive.padding(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(20),
        desktop: const EdgeInsets.all(24),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        border: Border.all(color: colorWithOpacity(_primary, 0.12), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorWithOpacity(_primary, 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              c.attachment.isPdf
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              color: _primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attachment',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: responsive.fontSize(
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: responsive.fontSize(
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  typeText,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: responsive.fontSize(
                      mobile: 11,
                      tablet: 12,
                      desktop: 13,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _openAttachment,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraInfoCard(Responsive responsive) {
    final c = _cert!;
    final isRejected = c.status == 'rejected';

    return Container(
      width: double.infinity,
      padding: responsive.padding(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(20),
        desktop: const EdgeInsets.all(24),
      ),
      decoration: BoxDecoration(
        color: isRejected
            ? Colors.red.shade50
            : colorWithOpacity(_primary, 0.04),
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        border: Border.all(
          color: isRejected
              ? colorWithOpacity(Colors.red, 0.2)
              : colorWithOpacity(_primary, 0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRejected
                    ? Icons.cancel_outlined
                    : Icons.verified_user_outlined,
                color: isRejected ? Colors.red.shade600 : _primary,
                size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
              ),
              const SizedBox(width: 8),
              Text(
                isRejected ? 'Rejection Details' : 'Verification Details',
                style: TextStyle(
                  fontSize: responsive.fontSize(
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                  fontWeight: FontWeight.w700,
                  color: isRejected ? Colors.red.shade700 : _primary,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
          if (c.verifiedBy != null)
            _infoRow(
              responsive,
              Icons.person_outline,
              'Verified By',
              c.verifiedBy!.toUpperCase(),
            ),
          if (c.verificationDate != null)
            _infoRow(
              responsive,
              Icons.event_outlined,
              'Verification Date',
              _formatDate(c.verificationDate!),
            ),
          if (isRejected && (c.rejectionReason ?? '').trim().isNotEmpty)
            _infoRow(
              responsive,
              Icons.info_outline,
              'Rejection Reason',
              c.rejectionReason!.trim(),
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(Responsive responsive, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: responsive.fontSize(mobile: 12, tablet: 13, desktop: 14),
        fontWeight: FontWeight.w700,
        color: colorWithOpacity(_primary, 0.7),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _infoRow(
    Responsive responsive,
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast
            ? 0
            : responsive.value(mobile: 12, tablet: 14, desktop: 16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: responsive.value(mobile: 16, tablet: 17, desktop: 18),
            color: colorWithOpacity(_primary, 0.6),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: responsive.value(mobile: 120, tablet: 140, desktop: 160),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: responsive.fontSize(
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: responsive.fontSize(
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Responsive responsive) {
    return Row(
      children: [
        if (_canEdit) ...[
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openEdit,
                borderRadius: BorderRadius.circular(
                  responsive.value(mobile: 14, tablet: 16, desktop: 18),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.value(
                      mobile: 15,
                      tablet: 17,
                      desktop: 19,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(
                      responsive.value(mobile: 14, tablet: 16, desktop: 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorWithOpacity(_primary, 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: responsive.value(
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsive.fontSize(
                            mobile: 14,
                            tablet: 15,
                            desktop: 16,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
        ],

        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _delete,
              borderRadius: BorderRadius.circular(
                responsive.value(mobile: 14, tablet: 16, desktop: 18),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: responsive.value(
                    mobile: 15,
                    tablet: 17,
                    desktop: 19,
                  ),
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(
                    responsive.value(mobile: 14, tablet: 16, desktop: 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorWithOpacity(Colors.redAccent, 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: responsive.value(
                        mobile: 18,
                        tablet: 20,
                        desktop: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.fontSize(
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorState(Responsive responsive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          responsive.value(mobile: 24, tablet: 32, desktop: 40),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(
                responsive.value(mobile: 20, tablet: 24, desktop: 28),
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: responsive.value(mobile: 48, tablet: 56, desktop: 64),
                color: Colors.red.shade400,
              ),
            ),
            ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),
            Text(
              'Failed to load',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: responsive.fontSize(
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: responsive.fontSize(
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
              ),
            ),
            ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.value(
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                  vertical: responsive.value(
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
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

  Widget _notFoundState(Responsive responsive) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(
              responsive.value(mobile: 20, tablet: 24, desktop: 28),
            ),
            decoration: BoxDecoration(
              color: colorWithOpacity(_primary, 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: responsive.value(mobile: 48, tablet: 56, desktop: 64),
              color: colorWithOpacity(_primary, 0.4),
            ),
          ),
          ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),
          Text(
            'Certificate not found',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: responsive.fontSize(
                mobile: 17,
                tablet: 19,
                desktop: 21,
              ),
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, Responsive responsive) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;

    if (s.contains('pending')) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    } else if (s.contains('verified')) {
      bg = colorWithOpacity(_primary, 0.08);
      fg = _primary;
    } else if (s.contains('expired')) {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
    } else {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(mobile: 10, tablet: 12, desktop: 14),
        vertical: responsive.value(mobile: 4, tablet: 5, desktop: 6),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorWithOpacity(fg, 0.3)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: fg,
          fontSize: responsive.fontSize(mobile: 11, tablet: 12, desktop: 13),
        ),
      ),
    );
  }
}
