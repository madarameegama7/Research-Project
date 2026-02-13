import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import 'export_country_detail.dart';

class ExportDetailsByCountry extends StatefulWidget {
  const ExportDetailsByCountry({super.key});

  @override
  State<ExportDetailsByCountry> createState() => _ExportDetailsByCountryState();
}

class _ExportDetailsByCountryState extends State<ExportDetailsByCountry> {
  // Currently selected country (null means showing grid)
  String? selectedCountry;
  // Default selected year
  String selectedYear = '2025';

  // Countries to display in the grid
  final List<String> countries = [
    'India',
    'Germany',
    'Spain',
    'UAE',
    'Japan',
    'UK',
    'USA',
    'Canada',
  ];
  // Year options (2020–2025)
  final List<String> years = ['2020', '2021', '2022', '2023', '2024', '2025'];

  // Static mock data per country/year (volume MT, LKR price/kg, trend)
  final Map<String, Map<String, dynamic>> countryData = {
    'India': {
      'flag': '🇮🇳',
      '2020': {'volume': 900, 'price': 3100, 'trend': 'down'},
      '2021': {'volume': 1000, 'price': 3200, 'trend': 'up'},
      '2022': {'volume': 1100, 'price': 3300, 'trend': 'up'},
      '2023': {'volume': 1200, 'price': 3400, 'trend': 'up'},
      '2024': {'volume': 1450, 'price': 3650, 'trend': 'up'},
      '2025': {'volume': 1800, 'price': 3800, 'trend': 'up'},
    },
    'Germany': {
      'flag': '🇩🇪',
      '2020': {'volume': 600, 'price': 3400, 'trend': 'down'},
      '2021': {'volume': 650, 'price': 3450, 'trend': 'up'},
      '2022': {'volume': 720, 'price': 3500, 'trend': 'up'},
      '2023': {'volume': 800, 'price': 3550, 'trend': 'stable'},
      '2024': {'volume': 920, 'price': 3650, 'trend': 'up'},
      '2025': {'volume': 980, 'price': 3800, 'trend': 'up'},
    },
    'Spain': {
      'flag': '🇪🇸',
      '2020': {'volume': 450, 'price': 3150, 'trend': 'down'},
      '2021': {'volume': 500, 'price': 3200, 'trend': 'stable'},
      '2022': {'volume': 550, 'price': 3250, 'trend': 'up'},
      '2023': {'volume': 600, 'price': 3300, 'trend': 'down'},
      '2024': {'volume': 680, 'price': 3500, 'trend': 'stable'},
      '2025': {'volume': 750, 'price': 3700, 'trend': 'up'},
    },
    'UAE': {
      'flag': '🇦🇪',
      '2020': {'volume': 350, 'price': 3050, 'trend': 'down'},
      '2021': {'volume': 380, 'price': 3100, 'trend': 'up'},
      '2022': {'volume': 410, 'price': 3150, 'trend': 'up'},
      '2023': {'volume': 450, 'price': 3200, 'trend': 'stable'},
      '2024': {'volume': 500, 'price': 3400, 'trend': 'up'},
      '2025': {'volume': 550, 'price': 3550, 'trend': 'stable'},
    },
    'Japan': {
      'flag': '🇯🇵',
      '2020': {'volume': 420, 'price': 3500, 'trend': 'stable'},
      '2021': {'volume': 460, 'price': 3600, 'trend': 'up'},
      '2022': {'volume': 500, 'price': 3650, 'trend': 'up'},
      '2023': {'volume': 550, 'price': 3700, 'trend': 'up'},
      '2024': {'volume': 580, 'price': 3850, 'trend': 'up'},
      '2025': {'volume': 620, 'price': 4000, 'trend': 'up'},
    },
    'UK': {
      'flag': '🇬🇧',
      '2020': {'volume': 520, 'price': 3400, 'trend': 'down'},
      '2021': {'volume': 580, 'price': 3480, 'trend': 'up'},
      '2022': {'volume': 630, 'price': 3520, 'trend': 'up'},
      '2023': {'volume': 700, 'price': 3600, 'trend': 'up'},
      '2024': {'volume': 820, 'price': 3750, 'trend': 'up'},
      '2025': {'volume': 950, 'price': 3900, 'trend': 'up'},
    },
    'USA': {
      'flag': '🇺🇸',
      '2020': {'volume': 1100, 'price': 3600, 'trend': 'down'},
      '2021': {'volume': 1250, 'price': 3700, 'trend': 'up'},
      '2022': {'volume': 1350, 'price': 3750, 'trend': 'up'},
      '2023': {'volume': 1500, 'price': 3800, 'trend': 'up'},
      '2024': {'volume': 1750, 'price': 3950, 'trend': 'up'},
      '2025': {'volume': 2000, 'price': 4100, 'trend': 'up'},
    },
    'Canada': {
      'flag': '🇨🇦',
      '2020': {'volume': 400, 'price': 3200, 'trend': 'down'},
      '2021': {'volume': 440, 'price': 3280, 'trend': 'up'},
      '2022': {'volume': 490, 'price': 3330, 'trend': 'up'},
      '2023': {'volume': 550, 'price': 3400, 'trend': 'stable'},
      '2024': {'volume': 600, 'price': 3550, 'trend': 'up'},
      '2025': {'volume': 680, 'price': 3700, 'trend': 'up'},
    },
  };

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Export Details by Country'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        // Hide back arrow while in grid view
        automaticallyImplyLeading: selectedCountry == null,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDescriptionCard(responsive),
            SizedBox(height: responsive.mediumSpacing),
            // Show grid until a country is picked; then show year + details
            if (selectedCountry == null)
              _buildCountrySelectorGrid(responsive)
            else
              Column(
                children: [
                  _buildYearFilter(responsive),
                  SizedBox(height: responsive.mediumSpacing),
                  _buildCountryDetails(responsive),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Intro card explaining the screen purpose
  Widget _buildDescriptionCard(Responsive responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFC8E6C9), const Color(0xFFA5D6A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: const Icon(
              Icons.public_rounded,
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
                  'Sri Lanka\'s Major Export Markets',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track export volumes and pricing trends across key international markets',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize - 1,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Grid of country cards (2 columns)
  Widget _buildCountrySelectorGrid(Responsive responsive) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: responsive.mediumSpacing,
      mainAxisSpacing: responsive.mediumSpacing,
      childAspectRatio: 1.2,
      physics: const NeverScrollableScrollPhysics(),
      children: countries
          .map(
            (country) => _buildCountrySelectionCard(
              country,
              countryData[country]!['flag'],
              responsive,
            ),
          )
          .toList(),
    );
  }

  // Single country card in the grid; navigates to detail screen
  Widget _buildCountrySelectionCard(
    String country,
    String flag,
    Responsive responsive,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExportCountryDetailScreen(
              country: country,
              countryData: countryData[country]!,
              years: years,
              initialYear: selectedYear,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 48)),
            SizedBox(height: responsive.smallSpacing),
            Text(
              country,
              style: TextStyle(
                fontSize: responsive.bodyFontSize + 1,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Country details section when selected in-place (kept for reuse)
  Widget _buildCountryDetails(Responsive responsive) {
    final country = selectedCountry!;
    final countryInfo = countryData[country]!;
    final yearData = countryInfo[selectedYear] as Map<String, dynamic>;

    final totalVolume = (yearData['volume'] as num?) ?? 0;
    final lkrPricePerKg = (yearData['price'] as num?) ?? 0;
    // Assumption: convert LKR to USD at ~360 LKR/USD for display
    final usdPricePerKg = lkrPricePerKg / 360.0;

    return Column(
      children: [
        Container(
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
            children: [
              Row(
                children: [
                  Text(
                    countryInfo['flag'],
                    style: const TextStyle(fontSize: 48),
                  ),
                  SizedBox(width: responsive.mediumSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country,
                          style: TextStyle(
                            fontSize: responsive.bodyFontSize + 4,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: responsive.smallSpacing),
                        Text(
                          'Year: $selectedYear',
                          style: TextStyle(
                            fontSize: responsive.bodyFontSize,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.mediumSpacing),
              _buildProductBreakdown(totalVolume, usdPricePerKg, responsive),
              SizedBox(height: responsive.mediumSpacing),
              _buildTrendCard(yearData['trend'], responsive),
            ],
          ),
        ),
      ],
    );
  }

  // Builds list of product cards (one per product type)
  Widget _buildProductBreakdown(
    num totalVolume,
    double usdPricePerKg,
    Responsive responsive,
  ) {
    // Split volumes by product (percentages of total)
    final splits = <String, double>{
      'Ground Pepper': 0.35,
      'Whole Pepper': 0.32,
      'Pepper Oil': 0.18,
      'Oleoresin': 0.15,
    };

    final colors = {
      'Ground Pepper': Colors.brown.shade400,
      'Whole Pepper': Colors.teal.shade600,
      'Pepper Oil': Colors.orange.shade600,
      'Oleoresin': Colors.indigo.shade500,
    };

    return Column(
      children: splits.entries.map((entry) {
        final title = entry.key;
        final pct = entry.value;
        final volumeMt = (totalVolume * pct).round();
        return _buildProductCard(
          title,
          volumeMt,
          usdPricePerKg,
          colors[title] ?? Colors.grey,
          responsive,
        );
      }).toList(),
    );
  }

  // Single product row card showing volume and price
  Widget _buildProductCard(
    String title,
    int volumeMt,
    double usdPricePerKg,
    Color color,
    Responsive responsive,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: responsive.smallSpacing),
      padding: EdgeInsets.all(responsive.smallSpacing + 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$volumeMt MT',
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: responsive.smallSpacing / 2),
              Text(
                '\$${usdPricePerKg.toStringAsFixed(2)} / kg',
                style: TextStyle(
                  fontSize: responsive.smallFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Trend chip/card (up / down / stable)
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
                  fontSize: responsive.smallFontSize,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: responsive.smallSpacing / 2),
              Text(
                trendLabel,
                style: TextStyle(
                  fontSize: responsive.bodyFontSize + 2,
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

  // Year selector with “Back” to return to the grid
  Widget _buildYearFilter(Responsive responsive) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Year',
                style: TextStyle(
                  fontSize: responsive.bodyFontSize + 2,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCountry = null;
                  });
                },
                child: Text(
                  'Back',
                  style: TextStyle(
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w600,
                    fontSize: responsive.bodyFontSize,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.mediumSpacing),
          Wrap(
            spacing: responsive.smallSpacing,
            runSpacing: responsive.smallSpacing,
            children: years
                .map(
                  (year) => GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedYear = year;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.mediumSpacing,
                        vertical: responsive.smallSpacing,
                      ),
                      decoration: BoxDecoration(
                        color: selectedYear == year
                            ? const Color(0xFF2E7D32)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedYear == year
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        year,
                        style: TextStyle(
                          fontSize: responsive.bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: selectedYear == year
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
