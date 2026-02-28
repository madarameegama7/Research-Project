import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';
import '../../services/quality_check_api.dart';
import 'certificates_step_screen.dart';

class BulkDensityScreen2 extends StatefulWidget {
  final String qualityCheckId;
  final String batchId;

  const BulkDensityScreen2({
    super.key,
    required this.qualityCheckId,
    required this.batchId,
  });

  @override
  State<BulkDensityScreen2> createState() => _BulkDensityScreen2State();
}

class _BulkDensityScreen2State extends State<BulkDensityScreen2>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _densityController = TextEditingController();

  bool _isSubmitting = false;
  double? _savedDensity;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

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
  }

  @override
  void dispose() {
    _densityController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  double? _parseDensity(String s) {
    final cleaned = s.trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Future<void> _submitDensity() async {
    if (!_formKey.currentState!.validate()) return;

    final density = _parseDensity(_densityController.text);
    if (density == null) return;

    setState(() => _isSubmitting = true);

    try {
      final api = QualityCheckApi();

      final result = await api.updateDensity(
        qualityCheckId: widget.qualityCheckId,
        value: density,
      );

      if (!mounted) return;

      setState(() {
        _savedDensity = (result["density"]?["value"] as num).toDouble();
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Density saved successfully"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
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
          'Bulk Density',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
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
                      // Step indicator – 4 steps, step 2 active
                      Row(
                        children: [
                          _buildStepIndicator(1, true, primary, responsive),
                          _buildStepLine(true, primary, responsive),
                          _buildStepIndicator(2, true, primary, responsive),
                          _buildStepLine(false, primary, responsive),
                          _buildStepIndicator(3, false, primary, responsive),
                          _buildStepLine(false, primary, responsive),
                          _buildStepIndicator(4, false, primary, responsive),
                        ],
                      ),
                      ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                      Text(
                        "Density Measurement",
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
                        "Enter the bulk density manually until the IoT device is available.",
                        style: TextStyle(
                          fontSize: responsive.bodyFontSize,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.pagePadding,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── Instructions Card (matches reference page) ────
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Card header
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        responsive.value(
                                          mobile: 10,
                                          tablet: 11,
                                          desktop: 12,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.info_outline_rounded,
                                        color: Colors.blue.shade700,
                                        size: responsive.mediumIconSize,
                                      ),
                                    ),
                                    ResponsiveSpacing.horizontal(
                                      mobile: 12,
                                      tablet: 14,
                                      desktop: 16,
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Measurement Instructions',
                                        style: TextStyle(
                                          fontSize: responsive.titleFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                ResponsiveSpacing(
                                  mobile: 16,
                                  tablet: 18,
                                  desktop: 20,
                                ),

                                // Instruction steps
                                _buildInstructionStep(
                                  number: '1',
                                  text:
                                      'Measure the bulk density of the pepper sample using a scale and measuring container.',
                                  responsive: responsive,
                                ),
                                const SizedBox(height: 10),
                                _buildInstructionStep(
                                  number: '2',
                                  text:
                                      'Calculate the density in grams per litre (g/L).',
                                  responsive: responsive,
                                ),
                                const SizedBox(height: 10),
                                _buildInstructionStep(
                                  number: '3',
                                  text:
                                      'Enter the value in the field below and tap "Save Density".',
                                  responsive: responsive,
                                ),
                                const SizedBox(height: 10),
                                _buildInstructionStep(
                                  number: '4',
                                  text:
                                      'Accepted range is 200–900 g/L. Double-check before saving.',
                                  responsive: responsive,
                                ),

                                ResponsiveSpacing(
                                  mobile: 12,
                                  tablet: 14,
                                  desktop: 16,
                                ),

                                // IoT note chip
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: responsive.value(
                                      mobile: 12,
                                      tablet: 14,
                                      desktop: 16,
                                    ),
                                    vertical: responsive.value(
                                      mobile: 8,
                                      tablet: 9,
                                      desktop: 10,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.sensors_rounded,
                                        color: Colors.amber.shade800,
                                        size: responsive.smallIconSize,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'IoT integration coming soon – manual entry for now.',
                                          style: TextStyle(
                                            fontSize:
                                                responsive.bodyFontSize - 1,
                                            color: Colors.amber.shade900,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          ResponsiveSpacing(
                            mobile: 24,
                            tablet: 28,
                            desktop: 32,
                          ),

                          // ── Input Card ────────────────────────────────────
                          Container(
                            width: double.infinity,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Card header
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        responsive.value(
                                          mobile: 10,
                                          tablet: 11,
                                          desktop: 12,
                                        ),
                                      ),
                                      decoration: BoxDecoration(
                                        color: primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.straighten_rounded,
                                        color: primary,
                                        size: responsive.mediumIconSize,
                                      ),
                                    ),
                                    ResponsiveSpacing.horizontal(
                                      mobile: 12,
                                      tablet: 14,
                                      desktop: 16,
                                    ),
                                    Expanded(
                                      child: Text(
                                        "Enter Bulk Density",
                                        style: TextStyle(
                                          fontSize: responsive.titleFontSize,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                ResponsiveSpacing(
                                  mobile: 18,
                                  tablet: 20,
                                  desktop: 22,
                                ),

                                Text(
                                  "Bulk density (g/L)",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: responsive.bodyFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                TextFormField(
                                  controller: _densityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: TextStyle(
                                    fontSize: responsive.bodyFontSize + 1,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "e.g. 500",
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    prefixIcon: Icon(
                                      Icons.numbers_rounded,
                                      color: Colors.grey[600],
                                      size: responsive.mediumIconSize,
                                    ),
                                    suffixText: "g/L",
                                    suffixStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: responsive.bodyFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: responsive.mediumSpacing,
                                      vertical: responsive.value(
                                        mobile: 18,
                                        tablet: 20,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: primary,
                                        width: 2,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    final v = _parseDensity(value ?? "");
                                    if (v == null) {
                                      return "Please enter a density value";
                                    }
                                    if (v <= 0) {
                                      return "Density must be greater than 0";
                                    }
                                    if (v < 200 || v > 900) {
                                      return "Enter a realistic value (200–900 g/L)";
                                    }
                                    return null;
                                  },
                                ),

                                ResponsiveSpacing(
                                  mobile: 12,
                                  tablet: 14,
                                  desktop: 16,
                                ),

                                // Success banner after save
                                if (_savedDensity != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade700,
                                          size: responsive.mediumIconSize,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Saved: ${_savedDensity!.toStringAsFixed(1)} g/L",
                                            style: TextStyle(
                                              fontSize: responsive.bodyFontSize,
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          ResponsiveSpacing(
                            mobile: 20,
                            tablet: 24,
                            desktop: 28,
                          ),

                          // ── Save button ───────────────────────────────────
                          Container(
                            width: double.infinity,
                            height: responsive.buttonHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (!_isSubmitting)
                                  BoxShadow(
                                    color: primary.withOpacity(0.25),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed:
                                  _isSubmitting ? null : _submitDensity,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.grey.shade300,
                                disabledForegroundColor:
                                    Colors.grey.shade600,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.save_rounded,
                                          size: responsive.smallIconSize,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Save Density",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize:
                                                responsive.titleFontSize,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          ResponsiveSpacing(
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),

                          // ── Continue button ───────────────────────────────
                          Container(
                            width: double.infinity,
                            height: responsive.buttonHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                if (_savedDensity != null)
                                  BoxShadow(
                                    color: primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _savedDensity != null
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CertificatesStepScreen(
                                            qualityCheckId:
                                                widget.qualityCheckId,
                                            batchId: widget.batchId,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.grey.shade300,
                                disabledForegroundColor:
                                    Colors.grey.shade600,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Continue to Certification",
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

                          ResponsiveSpacing(
                            mobile: 32,
                            tablet: 40,
                            desktop: 48,
                          ),
                        ],
                      ),
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

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildInstructionStep({
    required String number,
    required String text,
    required Responsive responsive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: responsive.value(mobile: 24, tablet: 26, desktop: 28),
          height: responsive.value(mobile: 24, tablet: 26, desktop: 28),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: responsive.bodyFontSize - 1,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(
    int step,
    bool isActive,
    Color primary,
    Responsive responsive,
  ) {
    final isCompleted = step < 2;

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

  Widget _buildStepLine(
      bool isActive, Color primary, Responsive responsive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: EdgeInsets.symmetric(
          horizontal:
              responsive.value(mobile: 8, tablet: 10, desktop: 12),
        ),
        color: isActive ? primary : Colors.grey[300],
      ),
    );
  }
}