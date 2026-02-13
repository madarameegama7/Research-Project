import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class ExportCountryDetailScreen extends StatefulWidget {
  final String country;
  final Map<String, dynamic> countryData;
  final List<String> years;
  final String initialYear;

  const ExportCountryDetailScreen({
    super.key,
    required this.country,
    required this.countryData,
    required this.years,
    required this.initialYear,
  });

  @override
  State<ExportCountryDetailScreen> createState() =>
      _ExportCountryDetailScreenState();
}

class _ExportCountryDetailScreenState extends State<ExportCountryDetailScreen> {
  // Currently selected year for the detail view
  late String selectedYear;

  @override
  void initState() {
    super.initState();
    // Initialize with the year passed from the previous screen
    selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    // Extract selected year data safely
    final yearData = widget.countryData[selectedYear] as Map<String, dynamic>;
    // Total export volume (metric tons) for the selected year
    final totalVolume = (yearData['volume'] as num?) ?? 0;
    // Price provided in LKR per kg
    final lkrPricePerKg = (yearData['price'] as num?) ?? 0;
    // Convert to USD for display (assumes ~360 LKR/USD)
    final usdPricePerKg = lkrPricePerKg / 360.0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // Show the selected country name in the app bar
        title: Text(widget.country),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country header card with flag and year info
            _buildHeaderCard(responsive),
            SizedBox(height: responsive.mediumSpacing),
            // Year chips selector
            _buildYearFilter(responsive),
            SizedBox(height: responsive.mediumSpacing),
            // Product breakdown grid (4 boxes, 2 per row)
            _buildProductBreakdown(totalVolume, usdPricePerKg, responsive),
            SizedBox(height: responsive.mediumSpacing),
            // Trend card (up / down / stable)
            _buildTrendCard(yearData['trend'], responsive),
          ],
        ),
      ),
    );
  }

  // Header card showing flag, country name, and current year
  Widget _buildHeaderCard(Responsive responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Flag block
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              widget.countryData['flag'] ?? '🌍',
              style: const TextStyle(fontSize: 42),
            ),
          ),
          SizedBox(width: responsive.mediumSpacing),
          // Country name and year
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.country,
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize + 6,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: responsive.smallSpacing),
                Text(
                  'Year: $selectedYear',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize + 1,
                    color: const Color.fromARGB(137, 0, 0, 0),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: responsive.smallSpacing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Year selector using ChoiceChips
  Widget _buildYearFilter(Responsive responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: responsive.smallSpacing,
        runSpacing: responsive.smallSpacing,
        children: widget.years
            .map(
              (year) => ChoiceChip(
                label: Text(
                  year,
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize,
                    fontWeight: FontWeight.w700,
                    color: selectedYear == year
                        ? Colors.white
                        : Colors.green.shade900,
                  ),
                ),
                selected: selectedYear == year,
                selectedColor: const Color(0xFF2E7D32),
                backgroundColor: Colors.grey[100],
                onSelected: (_) {
                  // Update selected year and rebuild
                  setState(() {
                    selectedYear = year;
                  });
                },
              ),
            )
            .toList(),
      ),
    );
  }

  // Build 4 product cards in a 2x2 layout
  Widget _buildProductBreakdown(
    num totalVolume,
    double usdPricePerKg,
    Responsive responsive,
  ) {
    // Product mix percentages of total volume
    final splits = <String, double>{
      'Ground Pepper': 0.35,
      'Whole Pepper': 0.32,
      'Pepper Oil': 0.18,
      'Pepper Oleoresin': 0.15,
    };

    // Friendly background colors per product
    final colors = {
      'Ground Pepper': const Color(0xFFBBDEFB),
      'Whole Pepper': const Color(0xFFA5D6A7),
      'Pepper Oil': const Color(0xFFFFE082),
      'Pepper Oleoresin': const Color(0xFFD1C4E9),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = responsive.smallSpacing;
        // Two columns layout: width for each item
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: splits.entries.map((entry) {
            final title = entry.key;
            final pct = entry.value;
            // Compute per-product volume from total
            final volumeMt = (totalVolume * pct).round();
            return SizedBox(
              width: itemWidth,
              child: _buildProductCard(
                title,
                volumeMt,
                usdPricePerKg,
                colors[title] ?? Colors.grey.shade100,
                responsive,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // Single product card showing volume and price
  Widget _buildProductCard(
    String title,
    int volumeMt,
    double usdPricePerKg,
    Color bgColor,
    Responsive responsive,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: responsive.smallSpacing),
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.bodyFontSize + 2,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: responsive.smallSpacing),
          // Export volume label/value
          Text(
            'Export Volume',
            style: TextStyle(
              fontSize: responsive.smallFontSize + 1,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$volumeMt MT',
            style: TextStyle(
              fontSize: responsive.bodyFontSize + 2,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: responsive.smallSpacing),
          // Export price label/value (USD/kg)
          Text(
            'Export Price',
            style: TextStyle(
              fontSize: responsive.smallFontSize + 1,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '\$${usdPricePerKg.toStringAsFixed(2)} / kg',
            style: TextStyle(
              fontSize: responsive.bodyFontSize + 1,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Trend card shows market direction with color and icon
  Widget _buildTrendCard(String trend, Responsive responsive) {
    Color trendColor = Colors.grey;
    IconData trendIcon = Icons.remove_rounded;
    String trendLabel = 'Stable';

    if (trend == 'up') {
      trendColor = Colors.green;
      trendIcon = Icons.trending_up_rounded;
      trendLabel = 'Growing';
    } else if (trend == 'down') {
      trendColor = Colors.red;
      trendIcon = Icons.trending_down_rounded;
      trendLabel = 'Declining';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: trendColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(trendIcon, color: trendColor, size: 24),
          SizedBox(width: responsive.mediumSpacing),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Market Trend',
                style: TextStyle(
                  fontSize: responsive.smallFontSize + 1,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: responsive.smallSpacing / 2),
              Text(
                trendLabel,
                style: TextStyle(
                  fontSize: responsive.bodyFontSize + 3,
                  fontWeight: FontWeight.w800,
                  color: trendColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
