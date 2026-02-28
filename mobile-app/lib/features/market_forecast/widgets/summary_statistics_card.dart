import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import 'summary_stat_item.dart';
import '../../../utils/market forecast/actual_price_data_si.dart';

class SummaryStatisticsCard extends StatelessWidget {
  final List<Map<String, dynamic>> reports;
  final String language;

  const SummaryStatisticsCard({
    super.key,
    required this.reports,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final totalReports = reports.length;
    final avgPrice = reports.isEmpty
        ? 0.0
        : reports
                  .map((r) => (r['pricePerKg'] as num?)?.toDouble() ?? 0.0)
                  .reduce((a, b) => a + b) /
              totalReports;
    final totalQuantity = reports.isEmpty
        ? 0.0
        : reports
              .map((r) => (r['quantity'] as num?)?.toDouble() ?? 0.0)
              .reduce((a, b) => a + b);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 12,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: const Icon(
                  Icons.assessment_rounded,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language == 'si'
                          ? ActualPriceDataSi.mySubmissions
                          : 'My Submissions',
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize + 2,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      language == 'si'
                          ? ActualPriceDataSi.trackHistorical
                          : 'Track the details of pepper batches and price submissions',
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize - 1,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.mediumSpacing),
          Row(
            children: [
              Expanded(
                child: SummaryStatItem(
                  label: language == 'si'
                      ? ActualPriceDataSi.totalRecords
                      : 'Total Records',
                  value: '$totalReports',
                  icon: Icons.list_alt_rounded,
                ),
              ),
              SizedBox(width: responsive.smallSpacing),
              Expanded(
                child: SummaryStatItem(
                  label: language == 'si'
                      ? ActualPriceDataSi.avgPrice
                      : 'Avg Price',
                  value:
                      (language == 'si' ? 'රු.' : 'Rs.') +
                      ' ${avgPrice.toStringAsFixed(0)}',
                  icon: Icons.attach_money_rounded,
                ),
              ),
              SizedBox(width: responsive.smallSpacing),
              Expanded(
                child: SummaryStatItem(
                  label: language == 'si'
                      ? ActualPriceDataSi.totalQty
                      : 'Total Qty',
                  value: '${_formatDecimal(totalQuantity)} kg',
                  icon: Icons.scale_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDecimal(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
}
