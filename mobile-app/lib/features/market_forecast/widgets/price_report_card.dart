import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import '../../../utils/market forecast/actual_price_data_si.dart';
import '../../../utils/market forecast/db_translations_si.dart';

class PriceReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onAddToMarketplace;
  final String language;

  const PriceReportCard({
    super.key,
    required this.report,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddToMarketplace,
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
            _buildHeader(responsive, saleDate, pricePerKg, priceColor),
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

  Widget _buildHeader(
    Responsive responsive,
    String saleDate,
    double pricePerKg,
    Color priceColor,
  ) {
    // Normalize status for consistent display
    final rawStatus = (report['currentStatus'] as String?)?.trim();
    final status = _normalizeStatus(rawStatus);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: Colors.black54,
            ),
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
            // Show badge only if status exists and not N/A
            if (status.isNotEmpty && status != 'N/A')
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _displayStatusText(status),
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
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
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
                  const Icon(
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
          const Icon(Icons.note_rounded, size: 14, color: Colors.black45),
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

  Widget _buildActionButtons(BuildContext context) {
    final rawStatus = (report['currentStatus'] as String?)?.trim();
    final status = _normalizeStatus(rawStatus);

    final bool canShowAddToMarketplace = status != 'MARKETPLACE_LISTED';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // First row: Update & Delete
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onUpdate,
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Update'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded, size: 16),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),

        if (canShowAddToMarketplace) ...[
          const SizedBox(height: 10),

          // Second row: Marketplace button FULL WIDTH
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddToMarketplace,
              icon: const Icon(Icons.storefront_rounded, size: 16),
              label: const Text('Add to Marketplace'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade700),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _normalizeStatus(String? status) {
    if (status == null) return '';
    return status.trim().replaceAll(' ', '_').toUpperCase();
  }

  String _displayStatusText(String normalizedStatus) {
    switch (normalizedStatus) {
      case 'BATCH_CREATED':
        return 'Batch Created';
      case 'MARKETPLACE_LISTED':
        return 'Marketplace Listed';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      default:
        // fallback: SOME_STATUS -> Some Status
        final s = normalizedStatus.replaceAll('_', ' ').toLowerCase();
        return s
            .split(' ')
            .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
            .join(' ');
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

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

  Color _statusColor(String status) {
    final s = _normalizeStatus(status);
    switch (s) {
      case 'BATCH_CREATED':
        return const Color(0xFF6A1B9A);
      case 'MARKETPLACE_LISTED':
        return Colors.blue.shade700;
      case 'APPROVED':
        return const Color(0xFF0277BD);
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDecimal(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
}
