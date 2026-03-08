import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../utils/responsive.dart';
import '../../../utils/language_prefs.dart';
import '../../../utils/market forecast/db_translations_si.dart';
import '../../../utils/market forecast/weekly_prediction_si.dart';

class PricePredictionService {
  final String apiUrl;
  PricePredictionService({required this.apiUrl});

  Future<double> fetchPredictedPrice({
    required String district,
    required String pepperType,
    required String grade,
    required int year,
    required int month,
    required int week, // ISO week number
  }) async {
    // Map grade values to API expected format
    String mappedGrade = grade;
    if (grade == 'Grade 1') {
      mappedGrade = 'GR1';
    } else if (grade == 'Grade 2') {
      mappedGrade = 'GR2';
    }

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'district': district,
        'pepper_type': pepperType,
        'grade': mappedGrade,
        'year': year,
        'month': month,
        'week': week,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final price = data['predicted_price_LKR_per_kg'];

      if (price == null) {
        throw Exception(
          'Predicted price not found in response. Full response: ${response.body}',
        );
      }

      return (price is num)
          ? price.toDouble()
          : double.tryParse(price.toString()) ?? 0.0;
    } else {
      throw Exception(
        'Failed to fetch predicted price. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }
}

// Screen to display the predicted price
class WeeklyPrediction extends StatefulWidget {
  final String year;
  final String month;
  final String week; // label text (e.g. "Week 10 (Mar 2–8)")
  final String district;
  final String pepperType;
  final String grade;
  final int weekNumber;

  const WeeklyPrediction({
    Key? key,
    required this.year,
    required this.month,
    required this.week,
    required this.district,
    required this.pepperType,
    required this.grade,
    required this.weekNumber,
  }) : super(key: key);

  @override
  State<WeeklyPrediction> createState() => _WeeklyPredictionState();
}

class _WeeklyPredictionState extends State<WeeklyPrediction> {
  String _currentLanguage = 'en';
  double? predictedPrice;
  bool isLoading = true;
  String? errorMsg;

  bool showInlineRecommendation = false;
  final TextEditingController _weightController = TextEditingController();
  double estimatedRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    fetchPrediction();
    // load language preference for translations
    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) setState(() => _currentLanguage = lang);
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> fetchPrediction() async {
    final service = PricePredictionService(
      apiUrl:
          'https://price-prediction-755295357792.europe-west1.run.app/predictlocalprice',
    );

    try {
      final price = await service.fetchPredictedPrice(
        district: widget.district,
        pepperType: widget.pepperType,
        grade: widget.grade,
        year: int.tryParse(widget.year) ?? 2025,
        month: int.tryParse(widget.month) ?? 1,
        week: widget.weekNumber,
      );

      setState(() {
        predictedPrice = price;
        isLoading = false;
        errorMsg = null;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        isLoading = false;
      });
    }
  }

  //  Recommendation rules
  String _actionTitleFromPrice(double p) {
    if (_currentLanguage == 'si') {
      if (p < 1300) return WeeklyPredictionSi.considerHolding;
      if (p <= 1500) return WeeklyPredictionSi.sellPartially;
      return WeeklyPredictionSi.goodTimeToSell;
    }
    if (p < 1300) return "Consider holding";
    if (p <= 1500) return "Sell partially";
    return "Good time to sell";
  }

  String _actionReasonFromPrice(double p) {
    if (_currentLanguage == 'si') {
      if (p < 1300) return WeeklyPredictionSi.reasonHold;
      if (p <= 1500) return WeeklyPredictionSi.reasonPartial;
      return WeeklyPredictionSi.reasonSell;
    }
    if (p < 1300) {
      return "The predicted price is relatively low. If storage is possible, waiting may help you get a better price.";
    } else if (p <= 1500) {
      return "The predicted price is moderate. You can sell some stock now and keep the rest to reduce risk.";
    }
    return "The predicted price is high. Selling now may give you better returns and reduce market risk.";
  }

  IconData _actionIconFromPrice(double p) {
    if (p < 1300) return Icons.pause_circle_outline;
    if (p <= 1500) return Icons.call_split;
    return Icons.sell_outlined;
  }

  Color _actionColorFromPrice(double p) {
    if (p < 1300) return Colors.red.shade600;
    if (p <= 1500) return Colors.orange.shade700;
    return Colors.green.shade700;
  }

  Widget _infoRow({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(
            context.responsive.spacing(mobile: 8, tablet: 10, desktop: 12),
          ),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: context.responsive.iconSize(
              mobile: 18,
              tablet: 20,
              desktop: 22,
            ),
            color: iconColor,
          ),
        ),
        SizedBox(
          width: context.responsive.spacing(
            mobile: 12,
            tablet: 14,
            desktop: 16,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: context.responsive.fontSize(
                    mobile: 12,
                    tablet: 13,
                    desktop: 14,
                  ),
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(
                height: context.responsive.spacing(
                  mobile: 3,
                  tablet: 4,
                  desktop: 5,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: context.responsive.fontSize(
                    mobile: 15,
                    tablet: 16,
                    desktop: 17,
                  ),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Open recommendation section
  void _openInlineRecommendation() {
    if (predictedPrice == null) return;

    setState(() {
      showInlineRecommendation = true;
      _weightController.text = '';
      estimatedRevenue = 0.0;
    });
  }

  // Close recommendation section
  void _closeInlineRecommendation() {
    setState(() {
      showInlineRecommendation = false;
      _weightController.text = '';
      estimatedRevenue = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentLanguage == 'si'
              ? WeeklyPredictionSi.screenTitle
              : 'Price Forecast Analysis',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg != null
          ? Padding(
              padding: EdgeInsets.all(
                r.spacing(mobile: 24, tablet: 28, desktop: 32),
              ),
              child: Text(
                'Error: $errorMsg',
                style: TextStyle(
                  fontSize: r.fontSize(mobile: 16, tablet: 17, desktop: 18),
                  color: Colors.red,
                ),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  r.pagePadding,
                  r.mediumSpacing,
                  r.pagePadding,
                  r.spacing(mobile: 26, tablet: 30, desktop: 34),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Week pill
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: r.spacing(
                            mobile: 18,
                            tablet: 20,
                            desktop: 24,
                          ),
                          vertical: r.spacing(
                            mobile: 8,
                            tablet: 10,
                            desktop: 12,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(
                          widget.week,
                          style: TextStyle(
                            fontSize: r.fontSize(
                              mobile: 13,
                              tablet: 14,
                              desktop: 15,
                            ),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: r.spacing(mobile: 14, tablet: 16, desktop: 18),
                    ),

                    // Predicted Price Card
                    Container(
                      padding: r.padding(
                        mobile: const EdgeInsets.all(18),
                        tablet: const EdgeInsets.all(22),
                        desktop: const EdgeInsets.all(26),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF81C784),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _currentLanguage == 'si'
                                ? WeeklyPredictionSi.predictedPrice
                                : "Predicted Price",
                            style: TextStyle(
                              fontSize: r.fontSize(
                                mobile: 16,
                                tablet: 18,
                                desktop: 20,
                              ),
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(
                            height: r.spacing(
                              mobile: 10,
                              tablet: 12,
                              desktop: 14,
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: (_currentLanguage == 'si'
                                      ? '${WeeklyPredictionSi.currency} ${predictedPrice!.toStringAsFixed(0)} '
                                      : 'Rs. ${predictedPrice!.toStringAsFixed(0)} '),
                                  style: TextStyle(
                                    fontSize: r.fontSize(
                                      mobile: 42,
                                      tablet: 48,
                                      desktop: 54,
                                    ),
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                TextSpan(
                                  text: _currentLanguage == 'si'
                                      ? '/${WeeklyPredictionSi.kg}'
                                      : '/kg',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: r.spacing(
                              mobile: 8,
                              tablet: 10,
                              desktop: 12,
                            ),
                          ),
                          Text(
                            _currentLanguage == 'si'
                                ? WeeklyPredictionSi.estimatedAverage
                                : 'Estimated average for the selected week',
                            style: TextStyle(
                              fontSize: r.fontSize(
                                mobile: 12.5,
                                tablet: 13,
                                desktop: 14,
                              ),
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: r.spacing(mobile: 14, tablet: 16, desktop: 18),
                    ),

                    // Details Card
                    Container(
                      padding: r.padding(
                        mobile: const EdgeInsets.all(14),
                        tablet: const EdgeInsets.all(16),
                        desktop: const EdgeInsets.all(18),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _infoRow(
                            context: context,
                            icon: Icons.location_on,
                            iconBg: const Color(0xFFE8F5E9),
                            iconColor: const Color(0xFF388E3C),
                            label: _currentLanguage == 'si'
                                ? WeeklyPredictionSi.district
                                : "District",
                            value: _currentLanguage == 'si'
                                ? MarketForecastSi.translateDistrict(
                                    widget.district,
                                  )
                                : widget.district,
                          ),
                          SizedBox(
                            height: r.spacing(
                              mobile: 10,
                              tablet: 12,
                              desktop: 14,
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          SizedBox(
                            height: r.spacing(
                              mobile: 10,
                              tablet: 12,
                              desktop: 14,
                            ),
                          ),
                          _infoRow(
                            context: context,
                            icon: Icons.local_florist,
                            iconBg: const Color(0xFFFFF3E0),
                            iconColor: Colors.brown.shade700,
                            label: _currentLanguage == 'si'
                                ? WeeklyPredictionSi.pepperType
                                : "Pepper Type",
                            value: _currentLanguage == 'si'
                                ? MarketForecastSi.translatePepperType(
                                    widget.pepperType,
                                  )
                                : widget.pepperType,
                          ),
                          SizedBox(
                            height: r.spacing(
                              mobile: 10,
                              tablet: 12,
                              desktop: 14,
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          SizedBox(
                            height: r.spacing(
                              mobile: 10,
                              tablet: 12,
                              desktop: 14,
                            ),
                          ),
                          _infoRow(
                            context: context,
                            icon: Icons.grade,
                            iconBg: const Color(0xFFFFF8E1),
                            iconColor: Colors.amber.shade700,
                            label: _currentLanguage == 'si'
                                ? WeeklyPredictionSi.grade
                                : "Grade",
                            value: _currentLanguage == 'si'
                                ? MarketForecastSi.translateGrade(widget.grade)
                                : widget.grade,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height: r.spacing(mobile: 14, tablet: 16, desktop: 18),
                    ),

                    // Recommendations button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green.shade700),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: r.padding(
                          mobile: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          tablet: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          desktop: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                        ),
                      ),
                      icon: Icon(
                        Icons.lightbulb_outline,
                        color: Colors.green.shade700,
                        size: r.iconSize(mobile: 20, tablet: 22, desktop: 24),
                      ),
                      label: Text(
                        _currentLanguage == 'si'
                            ? WeeklyPredictionSi.showRecommendations
                            : "Show Recommendations",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w700,
                          fontSize: r.fontSize(
                            mobile: 14,
                            tablet: 15,
                            desktop: 16,
                          ),
                        ),
                      ),
                      onPressed: _openInlineRecommendation,
                    ),

                    SizedBox(
                      height: r.spacing(mobile: 12, tablet: 14, desktop: 16),
                    ),

                    // Recommendation Details
                    if (showInlineRecommendation && predictedPrice != null)
                      Container(
                        padding: r.padding(
                          mobile: const EdgeInsets.all(14),
                          tablet: const EdgeInsets.all(16),
                          desktop: const EdgeInsets.all(18),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _currentLanguage == 'si'
                                        ? WeeklyPredictionSi.recommendations
                                        : "Recommendations",
                                    style: TextStyle(
                                      fontSize: r.fontSize(
                                        mobile: 15,
                                        tablet: 16,
                                        desktop: 18,
                                      ),
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _closeInlineRecommendation,
                                  icon: Icon(
                                    Icons.close,
                                    size: r.iconSize(
                                      mobile: 20,
                                      tablet: 22,
                                      desktop: 24,
                                    ),
                                  ),
                                  splashRadius: 18,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: r.spacing(
                                mobile: 6,
                                tablet: 8,
                                desktop: 10,
                              ),
                            ),

                            // Action
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: r.spacing(
                                  mobile: 12,
                                  tablet: 14,
                                  desktop: 16,
                                ),
                                vertical: r.spacing(
                                  mobile: 10,
                                  tablet: 12,
                                  desktop: 14,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: _actionColorFromPrice(
                                  predictedPrice!,
                                ).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _actionColorFromPrice(
                                    predictedPrice!,
                                  ).withOpacity(0.22),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _actionIconFromPrice(predictedPrice!),
                                    color: _actionColorFromPrice(
                                      predictedPrice!,
                                    ),
                                    size: r.iconSize(
                                      mobile: 20,
                                      tablet: 22,
                                      desktop: 24,
                                    ),
                                  ),
                                  SizedBox(
                                    width: r.spacing(
                                      mobile: 10,
                                      tablet: 12,
                                      desktop: 14,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _actionTitleFromPrice(predictedPrice!),
                                      style: TextStyle(
                                        fontSize: r.fontSize(
                                          mobile: 14,
                                          tablet: 15,
                                          desktop: 16,
                                        ),
                                        fontWeight: FontWeight.w800,
                                        color: _actionColorFromPrice(
                                          predictedPrice!,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: r.spacing(
                                mobile: 10,
                                tablet: 12,
                                desktop: 14,
                              ),
                            ),
                            Text(
                              _actionReasonFromPrice(predictedPrice!),
                              style: TextStyle(
                                fontSize: r.fontSize(
                                  mobile: 13,
                                  tablet: 14,
                                  desktop: 15,
                                ),
                                color: Colors.grey.shade700,
                              ),
                            ),

                            SizedBox(
                              height: r.spacing(
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
                            ),

                            // Weight input + revenue
                            Text(
                              _currentLanguage == 'si'
                                  ? WeeklyPredictionSi.estimateYourRevenue
                                  : "Estimate your revenue",
                              style: TextStyle(
                                fontSize: r.fontSize(
                                  mobile: 14,
                                  tablet: 15,
                                  desktop: 16,
                                ),
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(
                              height: r.spacing(
                                mobile: 8,
                                tablet: 10,
                                desktop: 12,
                              ),
                            ),
                            Text(
                              _currentLanguage == 'si'
                                  ? WeeklyPredictionSi.enterWeight
                                  : "Enter your pepper weight (kg):",
                              style: TextStyle(
                                fontSize: r.fontSize(
                                  mobile: 12.5,
                                  tablet: 13,
                                  desktop: 14,
                                ),
                                color: Colors.grey.shade700,
                              ),
                            ),
                            SizedBox(
                              height: r.spacing(
                                mobile: 8,
                                tablet: 10,
                                desktop: 12,
                              ),
                            ),
                            TextField(
                              controller: _weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.scale_outlined),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: r.spacing(
                                    mobile: 12,
                                    tablet: 14,
                                    desktop: 16,
                                  ),
                                  vertical: r.spacing(
                                    mobile: 12,
                                    tablet: 14,
                                    desktop: 16,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (val) {
                                final w = double.tryParse(val) ?? 0.0;
                                setState(() {
                                  estimatedRevenue =
                                      (predictedPrice ?? 0.0) * w;
                                });
                              },
                            ),
                            SizedBox(
                              height: r.spacing(
                                mobile: 10,
                                tablet: 12,
                                desktop: 14,
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(
                                r.spacing(mobile: 12, tablet: 14, desktop: 16),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F8F3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                (_currentLanguage == 'si'
                                        ? '${WeeklyPredictionSi.estimatedRevenue}: ${WeeklyPredictionSi.currency} '
                                        : 'Estimated Revenue: Rs. ') +
                                    estimatedRevenue.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: r.fontSize(
                                    mobile: 14,
                                    tablet: 15,
                                    desktop: 16,
                                  ),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: r.spacing(
                                mobile: 12,
                                tablet: 14,
                                desktop: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
