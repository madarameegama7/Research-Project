import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import '../services/quality_check_api.dart';
import 'bulk_density_screen.dart';
import 'bulk_density_screen2.dart';

class BatchDetailsScreen extends StatefulWidget {
  const BatchDetailsScreen({super.key});

  @override
  State<BatchDetailsScreen> createState() => _BatchDetailsScreenState();
}

class _BatchDetailsScreenState extends State<BatchDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  String _pepperType = 'Black Pepper';
  String _pepperVariety = 'Ceylon Pepper';
  String _dryingMethod = 'Sun Dried';

  String _mapPepperType(String ui) {
    return ui == 'Black Pepper' ? 'black' : 'white';
  }

  String _mapVariety(String ui) {
    switch (ui) {
      case 'Ceylon Pepper':
        return 'ceylon_pepper';
      case 'Panniyur-1':
        return 'panniyur_1';
      case 'Kuching':
        return 'kuching';
      case 'Dingi Rala':
        return 'dingi_rala';
      case 'Kohukumbure Rala':
        return 'kohukumbure_rala';
      case 'Bootawe Rala':
        return 'bootawe_rala';
      case 'Malabar':
        return 'malabar';
      default:
        return 'unknown';
    }
  }

  String _mapDryingMethod(String ui) {
    return ui == 'Sun Dried' ? 'sun_dried' : 'machine_dried';
  }

  DateTime? _harvestDate;

  final TextEditingController _batchWeightKgController =
      TextEditingController();
  final TextEditingController _batchWeightGController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _animationController.dispose();
    _batchWeightKgController.dispose();
    _batchWeightGController.dispose();
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Batch Details',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },

        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
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
                      // Step indicator (4 steps)
                      Row(
                        children: [
                          _buildStepIndicator(1, true, primary, responsive),
                          _buildStepLine(true, primary, responsive),
                          _buildStepIndicator(2, false, primary, responsive),
                          _buildStepLine(false, primary, responsive),
                          _buildStepIndicator(3, false, primary, responsive),
                          _buildStepLine(false, primary, responsive),
                          _buildStepIndicator(4, false, primary, responsive),
                        ],
                      ),
                      ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                      Text(
                        "Batch Information",
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
                        "Enter your pepper batch details",
                        style: TextStyle(
                          fontSize: responsive.bodyFontSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                // Form Content
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
                          // Pepper Information Section
                          _buildSectionHeader(
                            responsive,
                            primary,
                            'Pepper Information',
                            Icons.grass_rounded,
                          ),

                          ResponsiveSpacing(
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),

                          _buildDropdownField(
                            responsive,
                            primary,
                            label: 'Pepper Type',
                            value: _pepperType,
                            icon: Icons.category_rounded,
                            items: const ['Black Pepper', 'White Pepper'],
                            onChanged: (value) =>
                                setState(() => _pepperType = value!),
                          ),

                          _buildDropdownField(
                            responsive,
                            primary,
                            label: 'Pepper Variety',
                            value: _pepperVariety,
                            icon: Icons.local_florist_rounded,
                            items: const [
                              'Ceylon Pepper',
                              'Panniyur-1',
                              'Kuching',
                              'Dingi Rala',
                              'Kohukumbure Rala',
                              'Bootawe Rala',
                              'Malabar',
                              'Unknown',
                            ],
                            onChanged: (value) =>
                                setState(() => _pepperVariety = value!),
                          ),

                          ResponsiveSpacing(
                            mobile: 28,
                            tablet: 32,
                            desktop: 36,
                          ),

                          // Harvest & Processing Section
                          _buildSectionHeader(
                            responsive,
                            primary,
                            'Harvest & Processing',
                            Icons.agriculture_rounded,
                          ),

                          ResponsiveSpacing(
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),

                          _buildDatePickerField(
                            context: context,
                            responsive: responsive,
                            primary: primary,
                            label: 'Harvest Date',
                            selectedDate: _harvestDate,
                            onDateSelected: (date) =>
                                setState(() => _harvestDate = date),
                          ),

                          _buildDropdownField(
                            responsive,
                            primary,
                            label: 'Drying Method',
                            value: _dryingMethod,
                            icon: Icons.wb_sunny_rounded,
                            items: const ['Sun Dried', 'Machine Dried'],
                            onChanged: (value) =>
                                setState(() => _dryingMethod = value!),
                          ),

                          ResponsiveSpacing(
                            mobile: 28,
                            tablet: 32,
                            desktop: 36,
                          ),

                          // Quantity Section
                          _buildSectionHeader(
                            responsive,
                            primary,
                            'Quantity',
                            Icons.scale_rounded,
                          ),

                          ResponsiveSpacing(
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),

                          _buildSplitWeightField(responsive, primary),

                          ResponsiveSpacing(
                            mobile: 32,
                            tablet: 40,
                            desktop: 48,
                          ),

                          // Continue Button
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
                              onPressed: () async {
                                if (!_formKey.currentState!.validate()) return;

                                if (_harvestDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please select harvest date",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  final api = QualityCheckApi();

                                  final result = await api.createQualityCheck(
                                    pepperType: _mapPepperType(_pepperType),
                                    pepperVariety: _mapVariety(_pepperVariety),
                                    harvestDate: _harvestDate!,
                                    dryingMethod: _mapDryingMethod(
                                      _dryingMethod,
                                    ),
                                    batchWeightKg: _parseIntOrZero(
                                      _batchWeightKgController.text,
                                    ),
                                    batchWeightG: _parseIntOrZero(
                                      _batchWeightGController.text,
                                    ),
                                  );

                                  if (!mounted) return;
                                  if (Navigator.canPop(context))
                                    Navigator.pop(context);

                                  final qualityCheckId =
                                      result["qualityCheckId"] as String;
                                  final batchId = result["batchId"] as String;

                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (_) => BulkDensityScreen(
                                  //       qualityCheckId: qualityCheckId,
                                  //       batchId: batchId,
                                  //     ),
                                  //   ),
                                  // );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BulkDensityScreen2(
                                        qualityCheckId: qualityCheckId,
                                        batchId: batchId,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    if (Navigator.canPop(context))
                                      Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                }
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
                                    "Continue to Bulk Density",
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

  Widget _buildStepIndicator(
    int step,
    bool isActive,
    Color primary,
    Responsive responsive,
  ) {
    return Container(
      width: responsive.value(mobile: 32, tablet: 36, desktop: 40),
      height: responsive.value(mobile: 32, tablet: 36, desktop: 40),
      decoration: BoxDecoration(
        color: isActive ? primary : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
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

  Widget _buildDropdownField(
    Responsive responsive,
    Color primary, {
    required String label,
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: responsive.value(mobile: 16, tablet: 18, desktop: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: responsive.bodyFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            style: TextStyle(
              fontSize: responsive.bodyFontSize + 1,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                icon,
                color: Colors.grey[600],
                size: responsive.mediumIconSize,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.mediumSpacing,
                vertical: responsive.value(mobile: 18, tablet: 20),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primary, width: 2),
              ),
            ),
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    Responsive responsive,
    Color primary, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: responsive.value(mobile: 16, tablet: 18, desktop: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: responsive.bodyFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isRequired)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: responsive.bodyFontSize,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: responsive.bodyFontSize + 1),
            validator: isRequired
                ? (value) => value == null || value.isEmpty
                      ? 'This field is required'
                      : null
                : null,
            decoration: InputDecoration(
              hintText: 'Enter ${label.toLowerCase()}',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: responsive.bodyFontSize + 1,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                icon,
                color: Colors.grey[600],
                size: responsive.mediumIconSize,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.mediumSpacing,
                vertical: responsive.value(mobile: 18, tablet: 20),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required Responsive responsive,
    required Color primary,
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: responsive.value(mobile: 16, tablet: 18, desktop: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: responsive.bodyFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2015),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(primary: primary),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null) {
                onDateSelected(pickedDate);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.mediumSpacing,
                vertical: responsive.value(mobile: 18, tablet: 20),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.grey[600],
                    size: responsive.mediumIconSize,
                  ),
                  ResponsiveSpacing.horizontal(
                    mobile: 12,
                    tablet: 14,
                    desktop: 16,
                  ),
                  Text(
                    selectedDate == null
                        ? 'Select harvest date'
                        : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: TextStyle(
                      color: selectedDate == null
                          ? Colors.grey[400]
                          : Colors.black87,
                      fontSize: responsive.bodyFontSize + 1,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.grey[600],
                    size: responsive.value(mobile: 24, tablet: 26, desktop: 28),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitWeightField(Responsive responsive, Color primary) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: responsive.value(mobile: 16, tablet: 18, desktop: 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batch Weight',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: responsive.bodyFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // KG Field
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _batchWeightKgController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: responsive.bodyFontSize + 1),
                  decoration: InputDecoration(
                    hintText: 'Kilograms',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: responsive.bodyFontSize + 1,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(
                      Icons.balance_rounded,
                      color: Colors.grey[600],
                      size: responsive.mediumIconSize,
                    ),
                    suffixText: 'kg',
                    suffixStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: responsive.bodyFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsive.mediumSpacing,
                      vertical: responsive.value(mobile: 18, tablet: 20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                  ),
                ),
              ),

              SizedBox(
                width: responsive.value(mobile: 12, tablet: 14, desktop: 16),
              ),

              // G Field
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _batchWeightGController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: responsive.bodyFontSize + 1),
                  decoration: InputDecoration(
                    hintText: 'Grams',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: responsive.bodyFontSize + 1,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    suffixText: 'g',
                    suffixStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: responsive.bodyFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: responsive.value(
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                      vertical: responsive.value(mobile: 18, tablet: 20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Enter weight in kg and/or grams',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: responsive.fontSize(
                mobile: 12,
                tablet: 13,
                desktop: 14,
              ),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  int _parseIntOrZero(String s) {
    final v = int.tryParse(s.trim());
    return v ?? 0;
  }
}
