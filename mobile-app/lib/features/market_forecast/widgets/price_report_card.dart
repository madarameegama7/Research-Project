import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import '../../../utils/market forecast/actual_price_data_si.dart';
import '../../../utils/market forecast/db_translations_si.dart';

class PriceReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final String language;

  const PriceReportCard({
    super.key,
    required this.report,
    required this.onUpdate,
    required this.onDelete,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final pricePerKg = (report['pricePerKg'] as num?)?.toDouble() ?? 0.0;
    final priceColor = const Color(0xFF2E7D32);
    final quantity = (report['quantity'] as num?)?.toDouble() ?? 0.0;
    final variety = report['pepperType'] as String? ?? 'N/A';
    final grade = report['grade'] as String? ?? 'N/A';
    final gradeColor = _gradeColor(grade);
    final district = report['district'] as String? ?? 'N/A';
    final notes = report['notes'] as String? ?? '';
    final saleDate = report['saleDate'] as String? ?? '';
    final marketplaceProductId = report['marketplaceProductId'] as String?;
    final isInMarketplace =
        marketplaceProductId != null && marketplaceProductId.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: responsive.smallSpacing + 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              responsive,
              saleDate,
              pricePerKg,
              priceColor,
              isInMarketplace,
            ),
            SizedBox(height: responsive.smallSpacing + 4),
            _buildContent(
              responsive,
              variety,
              grade,
              gradeColor,
              quantity,
              district,
            ),
            if (notes.isNotEmpty) ...[
              SizedBox(height: responsive.smallSpacing),
              _buildNotesSection(responsive, notes),
            ],
            SizedBox(height: responsive.smallSpacing + 4),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  // Helper methods to build different sections of the card
  Widget _buildHeader(
    Responsive responsive,
    String saleDate,
    double pricePerKg,
    Color priceColor,
    bool isInMarketplace,
  ) {
    final status = (report['currentStatus'] ?? 'created').toString();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: Colors.black54),
            const SizedBox(width: 6),
            Text(
              _formatDate(saleDate),
              style: TextStyle(
                fontSize: responsive.smallFontSize + 1,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Only display status badge if not N/A
            if (status.toUpperCase() != 'N/A')
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status[0].toUpperCase() + status.substring(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _statusColor(status),
                        fontSize: responsive.smallFontSize + 1,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            if (isInMarketplace) ...[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.smallSpacing + 4,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      language == 'si'
                          ? ActualPriceDataSi.inMarketplace
                          : 'In Marketplace',
                      style: TextStyle(
                        fontSize: responsive.smallFontSize - 1,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.smallSpacing + 4,
                vertical: responsive.smallSpacing,
              ),
              decoration: BoxDecoration(
                color: priceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: priceColor.withOpacity(0.3)),
              ),
              child: Text(
                (language == 'si' ? ActualPriceDataSi.currency : 'LKR ') +
                    pricePerKg.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  fontWeight: FontWeight.w800,
                  color: priceColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Builds the main content section of the card with variety, grade, quantity, and district information
  Widget _buildContent(
    Responsive responsive,
    String variety,
    String grade,
    Color gradeColor,
    double quantity,
    String district,
  ) {
    final displayVariety = language == 'si'
        ? MarketForecastSi.translatePepperType(variety)
        : variety;
    final displayGrade = language == 'si'
        ? MarketForecastSi.translateGrade(grade)
        : grade;
    final displayDistrict = language == 'si'
        ? MarketForecastSi.translateDistrict(district)
        : district;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayVariety,
                style: TextStyle(
                  fontSize: responsive.bodyFontSize + 2,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.smallSpacing + 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gradeColor, gradeColor.withOpacity(0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: gradeColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          displayGrade,
                          style: TextStyle(
                            fontSize: responsive.smallFontSize + 1,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatDecimal(quantity)} kg',
                    style: TextStyle(
                      fontSize: responsive.smallFontSize + 1,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.smallSpacing),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: Colors.black45,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    displayDistrict,
                    style: TextStyle(
                      fontSize: responsive.smallFontSize,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Builds the notes section of the card, displayed only if there are notes provided by the user
  Widget _buildNotesSection(Responsive responsive, String notes) {
    return Container(
      padding: EdgeInsets.all(responsive.smallSpacing),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note_rounded, size: 14, color: Colors.black45),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              notes,
              style: TextStyle(
                fontSize: responsive.smallFontSize,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the action buttons for updating and deleting the price report
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: onUpdate,
          icon: const Icon(Icons.edit_rounded, size: 16),
          label: Text(language == 'si' ? ActualPriceDataSi.update : 'Update'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2E7D32),
            side: const BorderSide(color: Color(0xFF2E7D32)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_rounded, size: 16),
          label: Text(
            language == 'si' ? ActualPriceDataSi.deleteBtn : 'Delete',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  // Format the date to readable format
  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Colors based on the grade
  Color _gradeColor(String grade) {
    switch (grade) {
      case 'Grade 1':
        return const Color(0xFF1B5E20);
      case 'Grade 2':
        return const Color(0xFF0277BD);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  // Colors based on the status
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'created':
        return const Color(0xFFFFA000); // Amber;
      case 'approved':
        return const Color(0xFF0277BD); // Blue
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Format decimal values to remove unnecessary trailing zeros
  String _formatDecimal(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
}
