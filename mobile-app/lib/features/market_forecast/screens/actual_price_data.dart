import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../utils/responsive.dart';
import '../../../utils/language_prefs.dart';
import '../../../utils/market forecast/actual_price_data_si.dart';
import '../../../utils/market forecast/db_translations_si.dart';
import 'past_price_reports.dart';
import '../../../services/market_forecast/actual_price_data_service.dart';
import '../../../services/market_forecast/quality_check_service.dart';
import '../widgets/description_info_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_picker_field.dart';

class ActualPriceData extends StatefulWidget {
  final Map<String, dynamic>? reportData;

  const ActualPriceData({super.key, this.reportData});

  @override
  State<ActualPriceData> createState() => _ActualPriceDataState();
}

class _ActualPriceDataState extends State<ActualPriceData> {
  final _formKey = GlobalKey<FormState>();
  final ActualPriceDataService _actualPriceDataService =
      ActualPriceDataService();
  final QualityCheckService _qualityCheckService = QualityCheckService();

  // Form controllers
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _varietyController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();

  // Edit mode
  String? _reportId;
  bool get _isEditMode => _reportId != null;

  // Dropdown values
  String? _selectedVariety;
  String? _selectedGrade;
  String? _selectedDistrict;
  DateTime _selectedDate = DateTime.now();

  final List<String> _districts = [
    'Badulla',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kurunegala',
    'Matale',
    'Matara',
    'Monaragala',
    'Nuwara Eliya',
    'Ratnapura',
  ];

  bool _isSubmitting = false;

  bool showErrors = false;
  final Color _errorColor = Colors.grey.shade300;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // Quality check batches
  List<Map<String, dynamic>> _batches = [];
  String? _selectedBatchId;

  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadReportData();
    _loadBatches();

    // Load saved language preference
    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) {
        setState(() {
          _currentLanguage = lang;
        });
        _refreshDisplayValues();
      }
    });
  }

  // Load batch Ids
  Future<void> _loadBatches() async {
    try {
      final items = await _qualityCheckService.fetchMyQualityChecks();
      if (!mounted) return;
      setState(() {
        _batches = items;
      });
    } catch (e) {
      debugPrint('Failed to load batches: $e');
    }
  }

  // Load existing report data into form fields if in edit mode
  void _loadReportData() {
    if (widget.reportData != null) {
      final report = widget.reportData!;
      _reportId = report['_id'] as String? ?? report['id'] as String?;
      _selectedBatchId = report['batchId'] as String?;
      _priceController.text = (report['pricePerKg'] as num?)?.toString() ?? '';
      _quantityController.text = (report['quantity'] as num?)?.toString() ?? '';
      _notesController.text = report['notes'] as String? ?? '';

      _selectedVariety = report['pepperType'] as String?;
      _selectedGrade = report['grade'] as String?;

      _varietyController.text =
          (_selectedVariety != null && _selectedVariety!.isNotEmpty)
          ? (_currentLanguage == 'si'
                ? MarketForecastSi.translatePepperType(_selectedVariety!)
                : _selectedVariety!)
          : '';

      _gradeController.text =
          (_selectedGrade != null && _selectedGrade!.isNotEmpty)
          ? (_currentLanguage == 'si'
                ? MarketForecastSi.translateGrade(_selectedGrade!)
                : _selectedGrade!)
          : '';

      _selectedDistrict = report['district'] as String?;

      final saleDateStr = report['saleDate'] as String?;
      if (saleDateStr != null && saleDateStr.isNotEmpty) {
        try {
          _selectedDate = DateTime.parse(saleDateStr);
        } catch (_) {
          _selectedDate = DateTime.now();
        }
      }
    }
  }

  // Refresh displayed controller values based on current language
  void _refreshDisplayValues() {
    if (!mounted) return;
    setState(() {
      if (_selectedVariety != null && _selectedVariety!.isNotEmpty) {
        _varietyController.text = _currentLanguage == 'si'
            ? MarketForecastSi.translatePepperType(_selectedVariety!)
            : _selectedVariety!;
      } else {
        _varietyController.text = '';
      }

      if (_selectedGrade != null && _selectedGrade!.isNotEmpty) {
        _gradeController.text = _currentLanguage == 'si'
            ? MarketForecastSi.translateGrade(_selectedGrade!)
            : _selectedGrade!;
      } else {
        _gradeController.text = '';
      }
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _priceController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _varietyController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? (_currentLanguage == 'si'
                    ? ActualPriceDataSi.updatePriceDetails
                    : 'Update Price Details')
              : (_currentLanguage == 'si'
                    ? ActualPriceDataSi.realPriceDetails
                    : 'Real Price Details'),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: _currentLanguage == 'si'
                ? ActualPriceDataSi.reset
                : 'Reset',
            onPressed: _resetForm,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DescriptionInfoCard(
                title: _currentLanguage == 'si'
                    ? ActualPriceDataSi.marketPriceDetails
                    : 'Market Price Details',
                description: _currentLanguage == 'si'
                    ? ActualPriceDataSi.enterPriceDetails
                    : 'Enter the price details of your pepper batch',
                icon: Icons.edit_note_rounded,
              ),
              SizedBox(height: responsive.mediumSpacing),
              _buildViewPastReportsButton(responsive),
              SizedBox(height: responsive.largeSpacing),
              _buildFormSection(responsive),
              SizedBox(height: responsive.largeSpacing),
              _buildSubmitButton(responsive),
              SizedBox(height: responsive.mediumSpacing),
            ],
          ),
        ),
      ),
    );
  }

  // "View Past Reports" button
  Widget _buildViewPastReportsButton(Responsive responsive) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PastPriceReportsScreen(),
            ),
          );
        },
        icon: const Icon(Icons.history_rounded, size: 20),
        label: Text(
          _currentLanguage == 'si'
              ? ActualPriceDataSi.viewPastRecords
              : 'View My Records',
          style: TextStyle(
            fontSize: responsive.bodyFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2E7D32),
          side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          padding: EdgeInsets.symmetric(vertical: responsive.smallSpacing + 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Build form section
  Widget _buildFormSection(Responsive responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            _currentLanguage == 'si'
                ? ActualPriceDataSi.priceDetails
                : 'Price Details',
            style: TextStyle(
              fontSize: responsive.bodyFontSize + 3,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: responsive.mediumSpacing),

          if (_batches.isNotEmpty) ...[
            SizedBox(height: responsive.smallSpacing),
            _buildDropdownField(
              responsive,
              label: _currentLanguage == 'si'
                  ? ActualPriceDataSi.batchId
                  : 'Batch ID',
              icon: Icons.inventory_2_rounded,
              value: _selectedBatchId,
              items: _batches.map((b) => b['batchId'] as String).toList(),
              hint: _currentLanguage == 'si'
                  ? ActualPriceDataSi.selectBatchId
                  : 'Select Batch ID',
              readOnly: _isEditMode,
              onChanged: (value) {
                setState(() {
                  _selectedBatchId = value;
                  if (value == null) {
                    _selectedVariety = null;
                    _selectedGrade = null;
                    _varietyController.text = '';
                    _gradeController.text = '';
                    _quantityController.text = '';
                  } else {
                    final batch = _batches.firstWhere(
                      (b) => b['batchId'] == value,
                    );
                    final batchInfo = batch['batch'] ?? {};
                    final pepperType =
                        (batchInfo['pepperType'] as String?) ?? '';

                    if (pepperType.isNotEmpty) {
                      final key = pepperType.trim().toLowerCase();
                      if (key.contains('black')) {
                        _selectedVariety = 'Black Pepper';
                      } else if (key.contains('white')) {
                        _selectedVariety = 'White Pepper';
                      } else {
                        _selectedVariety = pepperType;
                      }

                      _varietyController.text = (_currentLanguage == 'si')
                          ? MarketForecastSi.translatePepperType(
                              _selectedVariety!,
                            )
                          : _selectedVariety!;
                    } else {
                      _selectedVariety = null;
                      _varietyController.text = '';
                    }

                    final gradeVal = batch['grade'] as String?;
                    _selectedGrade = gradeVal;
                    _gradeController.text = _selectedGrade ?? '';

                    final weightGrams = (batchInfo['batchWeightGrams'] as num?)
                        ?.toDouble();
                    if (weightGrams != null) {
                      final kg = weightGrams / 1000.0;
                      _quantityController.text = kg.toStringAsFixed(2);
                    }
                  }
                });
              },
            ),
            SizedBox(height: responsive.mediumSpacing),
          ],

          DatePickerField(
            label: _currentLanguage == 'si'
                ? ActualPriceDataSi.saleDate
                : 'Sale Date',
            selectedDate: _selectedDate,
            onDateChanged: (date) => setState(() => _selectedDate = date),
          ),
          SizedBox(height: responsive.mediumSpacing),

          CustomTextField(
            controller: _varietyController,
            label: _currentLanguage == 'si'
                ? ActualPriceDataSi.pepperVariety
                : 'Pepper Variety',
            hint: '',
            keyboardType: TextInputType.text,
            readOnly: true,
          ),
          SizedBox(height: responsive.mediumSpacing),

          CustomTextField(
            controller: _gradeController,
            label: _currentLanguage == 'si' ? ActualPriceDataSi.grade : 'Grade',
            hint: '',
            keyboardType: TextInputType.text,
            readOnly: true,
          ),
          SizedBox(height: responsive.mediumSpacing),

          CustomTextField(
            controller: _priceController,
            label: _currentLanguage == 'si'
                ? ActualPriceDataSi.pricePerKg
                : 'Price per kg (LKR)',
            hint: _currentLanguage == 'si'
                ? ActualPriceDataSi.enterPricePerKg
                : 'Enter price per kg',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (_) => null,
          ),
          SizedBox(height: responsive.mediumSpacing),

          CustomTextField(
            controller: _quantityController,
            label: _currentLanguage == 'si'
                ? ActualPriceDataSi.quantityKg
                : 'Quantity (kg)',
            hint: '',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            readOnly: true,
            validator: (_) => null,
          ),
          SizedBox(height: responsive.mediumSpacing),

          _buildCustomDropdownField(
            responsive,
            title: _currentLanguage == 'si'
                ? ActualPriceDataSi.district
                : 'District',
            value: _selectedDistrict,
            items: _districts,
            isDistrict: true,
          ),
          SizedBox(height: responsive.mediumSpacing),

          CustomTextField(
            controller: _notesController,
            label: _currentLanguage == 'si'
                ? ActualPriceDataSi.additionalNotes
                : 'Additional Notes (Optional)',
            hint: _currentLanguage == 'si'
                ? ActualPriceDataSi.anyAdditionalInfo
                : 'Any additional information...',
            keyboardType: TextInputType.multiline,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // Dropdown fields
  Widget _buildDropdownField(
    Responsive responsive, {
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
    bool readOnly = false,
  }) {
    final key = GlobalKey();
    final double horizontalPadding = responsive.smallSpacing + 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: key,
            onTap: readOnly
                ? null
                : () => _toggleDropdown(key, items, value, onChanged),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (value == null) ? _errorColor : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: responsive.bodyFontSize,
                      fontWeight: FontWeight.w600,
                      color: value == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                  readOnly
                      ? const Icon(Icons.lock_outline, color: Colors.grey)
                      : const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Colors.black87,
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDropdownField(
    Responsive responsive, {
    required String title,
    required String? value,
    required List<String> items,
    bool isDistrict = false,
  }) {
    final key = GlobalKey();
    final double horizontalPadding = responsive.smallSpacing + 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: key,
            onTap: () {
              if (isDistrict) {
                _toggleDistrictDropdown(key, items, value, (newValue) {
                  setState(() {
                    _selectedDistrict = newValue;
                  });
                });
              } else {
                _toggleDropdown(key, items, value, (newValue) {
                  setState(() {
                    _selectedDistrict = newValue;
                  });
                });
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (value == null) ? _errorColor : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (value != null && isDistrict && _currentLanguage == 'si')
                        ? MarketForecastSi.translateDistrict(value)
                        : (value ??
                              (_currentLanguage == 'si'
                                  ? '$title ${ActualPriceDataSi.selectPrefix}'
                                  : 'Select $title')),
                    style: TextStyle(
                      fontSize: responsive.bodyFontSize,
                      fontWeight: FontWeight.w600,
                      color: value == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleDropdown(
    GlobalKey key,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      return;
    }

    const double itemHeight = 48.0;
    final double dropdownHeight = items.length > 3
        ? itemHeight * 3
        : itemHeight * items.length;

    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: dropdownHeight),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: items
                  .map(
                    (item) => SizedBox(
                      height: itemHeight,
                      child: ListTile(
                        title: Text(item),
                        onTap: () {
                          onChanged(item);
                          _overlayEntry!.remove();
                          _overlayEntry = null;
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _toggleDistrictDropdown(
    GlobalKey key,
    List<String> items,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      return;
    }

    const double itemHeight = 48.0;
    final double dropdownHeight = items.length > 3
        ? itemHeight * 3
        : itemHeight * items.length;

    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        width: size.width,
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: dropdownHeight),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: items
                  .map(
                    (item) => SizedBox(
                      height: itemHeight,
                      child: ListTile(
                        title: Text(
                          _currentLanguage == 'si'
                              ? MarketForecastSi.translateDistrict(item)
                              : item,
                        ),
                        onTap: () {
                          onChanged(item);
                          _overlayEntry!.remove();
                          _overlayEntry = null;
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // Submit button
  Widget _buildSubmitButton(Responsive responsive) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          padding: EdgeInsets.symmetric(vertical: responsive.mediumSpacing),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isEditMode
                        ? (_currentLanguage == 'si'
                              ? ActualPriceDataSi.updatePriceData
                              : 'Update Price Data')
                        : (_currentLanguage == 'si'
                              ? ActualPriceDataSi.submitPriceData
                              : 'Submit Price Data'),
                    style: TextStyle(
                      fontSize: responsive.bodyFontSize + 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Submit handler (UPDATED: no marketplace prompt, status only on create)
  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final bool priceEmpty = _priceController.text.trim().isEmpty;
    final bool quantityEmpty = _quantityController.text.trim().isEmpty;
    final bool notesEmpty = _notesController.text.trim().isEmpty;
    final bool varietyEmpty =
        (_selectedVariety == null || _selectedVariety!.trim().isEmpty) &&
        _varietyController.text.trim().isEmpty;
    final bool gradeEmpty =
        (_selectedGrade == null || _selectedGrade!.trim().isEmpty) &&
        _gradeController.text.trim().isEmpty;
    final bool districtEmpty =
        _selectedDistrict == null || _selectedDistrict!.trim().isEmpty;
    final bool batchEmpty =
        _selectedBatchId == null || _selectedBatchId!.trim().isEmpty;

    if (priceEmpty &&
        quantityEmpty &&
        notesEmpty &&
        varietyEmpty &&
        gradeEmpty &&
        districtEmpty &&
        batchEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentLanguage == 'si'
                ? ActualPriceDataSi.pleaseFillTheForm
                : 'please fill the form',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final gradeValue = (_selectedGrade != null && _selectedGrade!.isNotEmpty)
        ? _selectedGrade
        : (_gradeController.text.trim().isNotEmpty
              ? _gradeController.text.trim()
              : null);

    final pepperValue =
        (_selectedVariety != null && _selectedVariety!.isNotEmpty)
        ? _selectedVariety
        : (_varietyController.text.trim().isNotEmpty
              ? _varietyController.text.trim()
              : null);

    final parsedPrice = double.tryParse(_priceController.text.trim());
    final parsedQuantity = double.tryParse(_quantityController.text.trim());

    final notes = _notesController.text.trim();
    final districtValue =
        (_selectedDistrict != null && _selectedDistrict!.trim().isNotEmpty)
        ? _selectedDistrict!.trim()
        : null;

    final payload = <String, dynamic>{
      'saleDate': _selectedDate.toIso8601String(),
      'pepperType': pepperValue,
      'grade': gradeValue,
      'district': districtValue,
      'batchId': _selectedBatchId,
      'pricePerKg': parsedPrice,
      'quantity': parsedQuantity,
      'notes': notes.isNotEmpty ? notes : null,
    };

    // IMPORTANT: only set status for NEW record creation
    if (!_isEditMode) {
      payload['currentStatus'] = 'BATCH_CREATED';
    }

    try {
      if (_isEditMode && _reportId != null) {
        await _actualPriceDataService.updateActualPriceData(
          _reportId!,
          payload,
        );

        _clearFormFieldsPreserveSubmission();

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentLanguage == 'si'
                      ? ActualPriceDataSi.success
                      : 'Success',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Text(
              _currentLanguage == 'si'
                  ? ActualPriceDataSi.recordUpdated
                  : 'Record updated successfully.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: Text(
                  _currentLanguage == 'si' ? ActualPriceDataSi.ok : 'OK',
                ),
              ),
            ],
          ),
        );
      } else {
        await _actualPriceDataService.createActualPriceData(payload);

        _clearFormFieldsPreserveSubmission();

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentLanguage == 'si'
                      ? ActualPriceDataSi.success
                      : 'Success',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Text(
              _currentLanguage == 'si'
                  ? 'වාර්තාව සාර්ථකව සුරකින ලදි.'
                  : 'Record saved successfully.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetForm();
                },
                child: Text(
                  _currentLanguage == 'si' ? ActualPriceDataSi.ok : 'OK',
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentLanguage == 'si'
                ? (_isEditMode
                      ? '${ActualPriceDataSi.updateFailed}: $e'
                      : '${ActualPriceDataSi.createFailed}: $e')
                : (_isEditMode ? 'Update failed: $e' : 'Create failed: $e'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Clear form fields
  void _clearFormFieldsPreserveSubmission() {
    _formKey.currentState?.reset();
    _priceController.clear();
    _quantityController.clear();
    _notesController.clear();
    setState(() {
      _selectedVariety = null;
      _selectedGrade = null;
      _selectedDistrict = null;
      _selectedDate = DateTime.now();
      showErrors = false;
    });
  }

  // Reset form
  void _resetForm() {
    _formKey.currentState?.reset();
    _priceController.clear();
    _quantityController.clear();
    _notesController.clear();
    _varietyController.clear();
    _gradeController.clear();
    setState(() {
      _selectedBatchId = null;
      _selectedVariety = null;
      _selectedGrade = null;
      _selectedDistrict = null;
      _selectedDate = DateTime.now();
    });
  }
}
