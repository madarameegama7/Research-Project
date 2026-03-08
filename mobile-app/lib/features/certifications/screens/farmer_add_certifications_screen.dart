import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import '../models/certification_model.dart';
import '../services/certification_api.dart';
import '../../../utils/responsive.dart';

// Helper to create a Color from an existing Color with a custom opacity (0.0-1.0)
Color colorWithOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

class FarmerAddCertificationScreen extends StatefulWidget {
  final CertificationApi api;

  const FarmerAddCertificationScreen({super.key, required this.api});

  @override
  State<FarmerAddCertificationScreen> createState() =>
      _FarmerAddCertificationScreenState();
}

class _FarmerAddCertificationScreenState
    extends State<FarmerAddCertificationScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF2E7D32);

  final _formKey = GlobalKey<FormState>();

  static const _certTypeOptions = <String>['SL-GAP', 'Other'];
  String? _certificationType;

  static const _issuingBodyOptions = <String>[
    'Department of Agriculture Sri Lanka',
    'Other',
  ];
  String? _issuingBody;

  final _certNumberCtrl = TextEditingController();

  DateTime? _issueDate;
  DateTime? _expiryDate;
  File? _attachmentFile;
  String? _attachmentName;
  bool _attachmentIsPdf = false;

  bool _submitting = false;

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _certNumberCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<String?> _showOtherInputDialog({
    required String title,
    required String hint,
  }) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorWithOpacity(_primary, 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined, color: _primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 2),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.pop(ctx, ctrl.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return (result == null || result.trim().isEmpty) ? null : result.trim();
  }

  Future<void> _pickDate({required bool isIssueDate}) async {
    final now = DateTime.now();
    final initial = isIssueDate
        ? (_issueDate ?? now)
        : (_expiryDate ?? (_issueDate ?? now));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 20),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: _primary)),
        child: child!,
      ),
    );

    if (picked == null) return;

    setState(() {
      if (isIssueDate) {
        _issueDate = picked;
        if (_expiryDate != null && !_expiryDate!.isAfter(_issueDate!)) {
          _expiryDate = null;
        }
      } else {
        _expiryDate = picked;
      }
    });
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) return;

      final file = File(path);
      final name = result.files.single.name;
      final ext = name.split('.').last.toLowerCase();

      setState(() {
        _attachmentFile = file;
        _attachmentName = name;
        _attachmentIsPdf = ext == 'pdf';
      });
    } catch (e) {
      _toast("File pick failed: $e");
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachmentFile = null;
      _attachmentName = null;
      _attachmentIsPdf = false;
    });
  }

  Future<void> _previewPickedAttachment() async {
    if (_attachmentFile == null) return;
    await OpenFilex.open(_attachmentFile!.path);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    if (_issueDate == null) {
      _toast('Please select issue date');
      return;
    }
    if (_expiryDate == null) {
      _toast('Please select expiry date');
      return;
    }
    if (!_expiryDate!.isAfter(_issueDate!)) {
      _toast('Expiry date must be after issue date');
      return;
    }

    setState(() => _submitting = true);

    try {
      final created = await widget.api.createCertification(
        certificationType: _certificationType!.trim(),
        certificateNumber: _certNumberCtrl.text.trim(),
        issuingBody: _issuingBody!.trim(),
        issueDate: _issueDate!,
        expiryDate: _expiryDate!,
        attachmentFile: _attachmentFile,
      );

      if (!mounted) return;

      Navigator.pop<CertificationModel>(context, created);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString());
      setState(() => _submitting = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.fixed,
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
            // Header matching dashboard style
            _buildHeader(responsive),

            // Scrollable form content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      responsive.value(mobile: 16, tablet: 24, desktop: 32),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section label
                          _buildSectionTitle(
                            responsive,
                            'Certification Details',
                            Icons.verified_outlined,
                          ),

                          ResponsiveSpacing(
                            mobile: 16,
                            tablet: 20,
                            desktop: 24,
                          ),

                          // Form card
                          _sectionCard(
                            responsive,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Certification type dropdown
                                _buildDropdown(
                                  responsive,
                                  value:
                                      (_certificationType == null ||
                                          _certTypeOptions.contains(
                                            _certificationType,
                                          ))
                                      ? _certificationType
                                      : 'Other',
                                  items: _certTypeOptions,
                                  label: 'Certification Type',
                                  icon: Icons.verified_outlined,
                                  validator: (_) {
                                    if (_certificationType == null ||
                                        _certificationType!.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                  onChanged: (val) async {
                                    if (val == null) return;
                                    if (val == 'Other') {
                                      final custom =
                                          await _showOtherInputDialog(
                                            title: 'Other Certification Type',
                                            hint: 'Type certification name',
                                          );
                                      if (custom == null) return;
                                      setState(
                                        () => _certificationType = custom,
                                      );
                                    } else {
                                      setState(() => _certificationType = val);
                                    }
                                  },
                                ),

                                ResponsiveSpacing(
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),

                                // Certificate number
                                _buildTextField(
                                  responsive,
                                  controller: _certNumberCtrl,
                                  label: 'Certificate Number',
                                  icon: Icons.confirmation_number_outlined,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Required'
                                      : null,
                                ),

                                ResponsiveSpacing(
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),

                                // Issuing body dropdown
                                _buildDropdown(
                                  responsive,
                                  value:
                                      (_issuingBody == null ||
                                          _issuingBodyOptions.contains(
                                            _issuingBody,
                                          ))
                                      ? _issuingBody
                                      : 'Other',
                                  items: _issuingBodyOptions,
                                  label: 'Issuing Body',
                                  icon: Icons.account_balance_outlined,
                                  validator: (_) {
                                    if (_issuingBody == null ||
                                        _issuingBody!.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                  onChanged: (val) async {
                                    if (val == null) return;
                                    if (val == 'Other') {
                                      final custom =
                                          await _showOtherInputDialog(
                                            title: 'Other Issuing Body',
                                            hint: 'Type issuing organization',
                                          );
                                      if (custom == null) return;
                                      setState(() => _issuingBody = custom);
                                    } else {
                                      setState(() => _issuingBody = val);
                                    }
                                  },
                                ),

                                ResponsiveSpacing(
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),

                                // Issue date picker
                                _buildDateField(
                                  responsive,
                                  label: 'Issue Date',
                                  icon: Icons.event_outlined,
                                  date: _issueDate,
                                  onTap: () => _pickDate(isIssueDate: true),
                                ),

                                ResponsiveSpacing(
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),

                                // Expiry date picker
                                _buildDateField(
                                  responsive,
                                  label: 'Expiry Date',
                                  icon: Icons.event_available_outlined,
                                  date: _expiryDate,
                                  onTap: () => _pickDate(isIssueDate: false),
                                ),

                                ResponsiveSpacing(
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),
                                _buildAttachmentField(responsive),
                              ],
                            ),
                          ),

                          ResponsiveSpacing(
                            mobile: 24,
                            tablet: 28,
                            desktop: 32,
                          ),

                          // Submit button
                          _buildSubmitButton(responsive),

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
            ),
          ],
        ),
      ),
    );
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
          // Back button
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

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Certification',
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
                const SizedBox(height: 2),
                Text(
                  'Fill in the details below',
                  style: TextStyle(
                    color: colorWithOpacity(Colors.white, 0.8),
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

          // Decorative icon
          Container(
            padding: EdgeInsets.all(
              responsive.value(mobile: 10, tablet: 12, desktop: 14),
            ),
            decoration: BoxDecoration(
              color: colorWithOpacity(Colors.white, 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: responsive.value(mobile: 22, tablet: 24, desktop: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    Responsive responsive,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: responsive.value(mobile: 4, tablet: 5, desktop: 6),
          height: responsive.value(mobile: 20, tablet: 22, desktop: 24),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 10, tablet: 12, desktop: 14),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 17,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        Icon(
          icon,
          color: _primary,
          size: responsive.value(mobile: 22, tablet: 24, desktop: 26),
        ),
      ],
    );
  }

  Widget _sectionCard(Responsive responsive, {required Widget child}) {
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
      child: child,
    );
  }

  Widget _buildTextField(
    Responsive responsive, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: responsive.fontSize(mobile: 14, tablet: 15, desktop: 16),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: responsive.fontSize(mobile: 13, tablet: 14, desktop: 15),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        prefixIcon: Icon(
          icon,
          color: _primary,
          size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: responsive.value(mobile: 14, tablet: 16, desktop: 18),
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _buildDropdown(
    Responsive responsive, {
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: validator,
      style: TextStyle(
        color: Colors.grey[800],
        fontSize: responsive.fontSize(mobile: 14, tablet: 15, desktop: 16),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: responsive.fontSize(mobile: 13, tablet: 14, desktop: 15),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        prefixIcon: Icon(
          icon,
          color: _primary,
          size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: responsive.value(mobile: 14, tablet: 16, desktop: 18),
          horizontal: 12,
        ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _primary,
        size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField(
    Responsive responsive, {
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final hasDate = date != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: responsive.fontSize(mobile: 13, tablet: 14, desktop: 15),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: hasDate
                  ? colorWithOpacity(_primary, 0.5)
                  : Colors.grey.shade300,
            ),
          ),
          prefixIcon: Icon(
            icon,
            color: _primary,
            size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
          ),
          suffixIcon: Icon(
            Icons.calendar_month_rounded,
            color: hasDate ? _primary : Colors.grey[400],
            size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: responsive.value(mobile: 14, tablet: 16, desktop: 18),
            horizontal: 12,
          ),
          filled: hasDate,
          fillColor: hasDate
              ? colorWithOpacity(_primary, 0.04)
              : Colors.transparent,
        ),
        child: Text(
          hasDate ? _formatDate(date) : 'Select date',
          style: TextStyle(
            color: hasDate ? Colors.grey[800] : Colors.grey[500],
            fontSize: responsive.fontSize(mobile: 14, tablet: 15, desktop: 16),
            fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(Responsive responsive) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _submitting ? null : _submit,
          borderRadius: BorderRadius.circular(
            responsive.value(mobile: 14, tablet: 16, desktop: 18),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              vertical: responsive.value(mobile: 16, tablet: 18, desktop: 20),
            ),
            decoration: BoxDecoration(
              gradient: _submitting
                  ? null
                  : LinearGradient(
                      colors: [_primary, colorWithOpacity(_primary, 0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _submitting ? Colors.grey[300] : null,
              borderRadius: BorderRadius.circular(
                responsive.value(mobile: 14, tablet: 16, desktop: 18),
              ),
              boxShadow: _submitting
                  ? []
                  : [
                      BoxShadow(
                        color: colorWithOpacity(_primary, 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_submitting)
                  SizedBox(
                    width: responsive.value(
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                    height: responsive.value(
                      mobile: 18,
                      tablet: 20,
                      desktop: 22,
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[600]!,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
                  ),
                ResponsiveSpacing.horizontal(
                  mobile: 10,
                  tablet: 12,
                  desktop: 14,
                ),
                Text(
                  _submitting ? 'Submitting...' : 'Submit Certificate',
                  style: TextStyle(
                    color: _submitting ? Colors.grey[600] : Colors.white,
                    fontSize: responsive.fontSize(
                      mobile: 15,
                      tablet: 16,
                      desktop: 17,
                    ),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentField(Responsive responsive) {
    final hasFile = _attachmentFile != null;

    return Container(
      width: double.infinity,
      padding: responsive.padding(
        mobile: const EdgeInsets.all(14),
        tablet: const EdgeInsets.all(16),
        desktop: const EdgeInsets.all(18),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorWithOpacity(_primary, 0.18), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                color: _primary,
                size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Certificate File (Optional)",
                  style: TextStyle(
                    fontSize: responsive.fontSize(
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _pickAttachment,
                icon: const Icon(Icons.upload_file),
                label: Text(hasFile ? "Replace" : "Upload"),
                style: TextButton.styleFrom(foregroundColor: _primary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (!hasFile)
            Text(
              "Upload JPG, PNG, WEBP, or PDF (max 10MB).",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: responsive.fontSize(
                  mobile: 12,
                  tablet: 13,
                  desktop: 13,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorWithOpacity(_primary, 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorWithOpacity(_primary, 0.15)),
              ),
              child: Row(
                children: [
                  Icon(
                    _attachmentIsPdf
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_rounded,
                    color: _primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _attachmentName ?? "Selected file",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "Preview",
                    onPressed: _previewPickedAttachment,
                    icon: const Icon(Icons.visibility_outlined),
                    color: _primary,
                  ),
                  IconButton(
                    tooltip: "Remove",
                    onPressed: _removeAttachment,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
