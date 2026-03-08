import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../utils/responsive.dart';
import 'export_price_trends.dart';

class ExportPricePrediction extends StatefulWidget {
  const ExportPricePrediction({super.key});

  @override
  State<ExportPricePrediction> createState() => _ExportPricePredictionState();
}

class _ExportPricePredictionState extends State<ExportPricePrediction> {
  String? selectedPepperType = 'Black';
  late String nextMonth;
  late String nextYear;
  final TextEditingController _volumeController = TextEditingController();

  bool showErrors = false;
  bool showResult = false;
  bool isLoading = false;
  bool showMonthDetails = false;
  bool isLoadingMonthDetails = false;
  double? predictedPricePerKg;
  double? predictedMonthlyTotal;

  @override
  void initState() {
    super.initState();
    _calculateNextMonth();
  }

  // Method to calculate the next month
  void _calculateNextMonth() {
    DateTime now = DateTime.now();
    DateTime nextMonthDate = DateTime(now.year, now.month + 1, 1);

    nextMonth = DateFormat('MMMM').format(nextMonthDate);
    nextYear = nextMonthDate.year.toString();
  }

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final buttonWidth = responsive.value(
      mobile: MediaQuery.of(context).size.width * 0.65,
      tablet: MediaQuery.of(context).size.width * 0.45,
      desktop: 360,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Export Price Prediction'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _resetForm,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(0.0),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              responsive.pagePadding,
              0,
              responsive.pagePadding,
              responsive.largeSpacing,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: responsive.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: responsive.mediumSpacing),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        responsive.largeSpacing,
                        responsive.largeSpacing,
                        responsive.largeSpacing,
                        responsive.xlargeSpacing,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFC8E6C9),
                            const Color(0xFFA5D6A7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.08),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.trending_up_rounded,
                                  color: Colors.black87,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Export Price Prediction',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Forecast export pepper prices monthly with your current details.',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsive.mediumSpacing),
                          Row(
                            children: [
                              _buildChip('Fast 2-step setup'),
                              SizedBox(width: responsive.smallSpacing),
                              _buildChip('Realistic outlook'),
                            ],
                          ),
                          SizedBox(height: responsive.mediumSpacing),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_rounded,
                                  color: Colors.black87,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Get accurate monthly export price forecasts to plan your shipments better',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: responsive.largeSpacing),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pepper Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Black',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.mediumSpacing),

                    _buildNumberField(),
                    SizedBox(height: responsive.mediumSpacing),

                    _buildMonthDetailsSection(responsive),

                    SizedBox(height: responsive.largeSpacing),

                    Center(
                      child: SizedBox(
                        width: buttonWidth,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            elevation: 4,
                            shadowColor: Colors.green.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: isLoading ? null : _onSubmit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Predict the Export Price',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    SizedBox(height: responsive.mediumSpacing),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: isLoading
                          ? _buildLoadingCard(context)
                          : showResult
                          ? _buildResultCard(context)
                          : const SizedBox(),
                    ),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: showResult
                          ? Column(
                              children: [
                                SizedBox(height: responsive.mediumSpacing),
                                Center(
                                  child: SizedBox(
                                    width: buttonWidth,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 20,
                                        ),
                                        backgroundColor: const Color(
                                          0xFF2E7D32,
                                        ),
                                        elevation: 4,
                                        shadowColor: Colors.green.withOpacity(
                                          0.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ExportPriceTrends(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'View More Details',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build the loading card
  Widget _buildLoadingCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const ValueKey('loading-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing Market Data',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Processing your export prediction...',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Buld the result card
  Widget _buildResultCard(BuildContext context) {
    final theme = Theme.of(context);
    final volumeKg = double.tryParse(_volumeController.text) ?? 0;

    return Container(
      key: const ValueKey('result-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 191, 243, 169),
            const Color.fromARGB(255, 208, 222, 204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 176, 238, 143).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color.fromARGB(255, 182, 221, 156).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.4)),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.black87,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Export Price Forecast',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your predicted export price',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildResultRowEnhanced(
                  'Pepper Type',
                  selectedPepperType ?? '-',
                  Icons.local_shipping_rounded,
                ),
                const SizedBox(height: 12),
                _buildResultRowEnhanced(
                  'Month',
                  nextMonth,
                  Icons.calendar_month_rounded,
                ),
                const SizedBox(height: 12),
                _buildResultRowEnhanced(
                  'Year',
                  nextYear,
                  Icons.date_range_rounded,
                ),
                const SizedBox(height: 12),
                _buildResultRowEnhanced(
                  'Volume',
                  '${volumeKg.toStringAsFixed(0)} kg',
                  Icons.scale_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Per kg Price',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'LKR',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              predictedPricePerKg != null
                                  ? _formatCurrencyNumber(predictedPricePerKg!)
                                  : '—',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Monthly Total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'LKR',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              predictedMonthlyTotal != null
                                  ? _formatCurrencyNumber(
                                      predictedMonthlyTotal!,
                                    )
                                  : '—',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build number field
  Widget _buildNumberField() {
    final hasError = showErrors && _volumeController.text.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Export Volume (kg)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? Colors.red : Colors.grey.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _volumeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              hintText: 'Enter volume in kg',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
            ),
          ),
        ),
        if (showErrors && _volumeController.text.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Export volume is required',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // Build enhanced result row
  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Build month details section
  Widget _buildMonthDetailsSection(Responsive responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Year & Month',
          style: TextStyle(
            fontSize: responsive.bodyFontSize - 0.5,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
        if (!showMonthDetails)
          Center(
            child: _buildFetchButton(
              isLoading: isLoadingMonthDetails,
              onPressed: () async {
                setState(() {
                  isLoadingMonthDetails = true;
                });
                // Simulate API call delay
                await Future.delayed(const Duration(milliseconds: 1500));
                setState(() {
                  isLoadingMonthDetails = false;
                  showMonthDetails = true;
                });
              },
              color: Colors.green.shade700,
            ),
          ),
        if (showMonthDetails) ...[_buildMonthCard(responsive)],
      ],
    );
  }

  // Build fetch button with loading state
  Widget _buildFetchButton({
    required bool isLoading,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: isLoading ? 0 : 3,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CupertinoActivityIndicator(color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Loading',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : const Text(
                  key: ValueKey('fetch'),
                  'Fetch Details',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  // Build month card
  Widget _buildMonthCard(Responsive responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.cyan.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Predicting Price For',
            style: TextStyle(
              fontSize: responsive.bodyFontSize - 0.5,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Center(
              child: Text(
                '$nextMonth $nextYear',
                style: TextStyle(
                  fontSize: responsive.bodyFontSize + 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue.shade600, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Get export price predictions for this month',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize - 1.5,
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // On submit, validate and call API
  void _onSubmit() {
    setState(() {
      showErrors = true;
    });

    if (selectedPepperType == null ||
        _volumeController.text.isEmpty ||
        !showMonthDetails) {
      return;
    }

    _callExportPredictionApi();
  }

  Future<void> _callExportPredictionApi() async {
    setState(() {
      isLoading = true;
    });

    final volume = double.tryParse(_volumeController.text) ?? 0;

    // Deployed API URL
    final apiUrl = Uri.parse(
      'https://price-prediction-755295357792.europe-west1.run.app/predictexportprice',
    );

    try {
      final resp = await http.post(
        apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quantity_kg': volume}),
      );

      if (resp.statusCode != 200) {
        throw Exception('Server returned ${resp.statusCode}');
      }

      final body = json.decode(resp.body) as Map<String, dynamic>;
      if (body.containsKey('error')) {
        throw Exception(body['error'].toString());
      }

      final predicted = (body['predicted_export_price_lkr_per_kg'] as num?)
          ?.toDouble();
      final year = body['year'] as int?;
      final monthNum = body['month'] as int?;

      setState(() {
        predictedPricePerKg = predicted;
        predictedMonthlyTotal = (predicted != null) ? predicted * volume : null;
        if (year != null && monthNum != null) {
          nextYear = year.toString();
          nextMonth = DateFormat('MMMM').format(DateTime(year, monthNum, 1));
        }
        showResult = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction failed: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _volumeController.clear();
      showErrors = false;
      showResult = false;
      isLoading = false;
      predictedPricePerKg = null;
      predictedMonthlyTotal = null;
      showMonthDetails = false;
      isLoadingMonthDetails = false;
    });
  }

  String _formatCurrencyNumber(double value) {
    final rounded = value.round();
    final chars = rounded.toString().split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i != 0 && i % 3 == 0) buffer.write(',');
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  Widget _buildResultRowEnhanced(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.black87, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
