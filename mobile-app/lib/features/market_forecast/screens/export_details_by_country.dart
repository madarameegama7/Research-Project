import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import '../../../utils/language_prefs.dart';
import '../../../utils/market forecast/export_details_by_country_si.dart';
import '../../../utils/market forecast/db_translations_si.dart';
import '../../../services/market_forecast/export_details_by_country_service.dart';

class ExportDetailsByCountry extends StatefulWidget {
  const ExportDetailsByCountry({super.key});

  @override
  State<ExportDetailsByCountry> createState() => _ExportDetailsByCountryState();
}

class _ExportDetailsByCountryState extends State<ExportDetailsByCountry> {
  String? selectedCountry;
  // Selected year for details
  int? selectedYear;

  // Dynamic data from backend
  List<String> countries = [];
  List<int> years = [];
  bool isLoading = true;
  bool isLoadingYears = false;
  String? errorMessage;

  final ExportDetailsByCountryService _service =
      ExportDetailsByCountryService();

  @override
  void initState() {
    super.initState();
    _loadCountries();
    // Load saved language preference
    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) {
        setState(() {
          _currentLanguage = lang;
        });
      }
    });
  }

  String _currentLanguage = 'en';

  // Load list of countries
  Future<void> _loadCountries() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);
      final loadedCountries = await _service.fetchCountries();
      if (!mounted) return;
      setState(() {
        countries = loadedCountries;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // Load available years for selected country
  Future<void> _loadYearsForCountry(String country) async {
    try {
      if (!mounted) return;
      setState(() {
        isLoadingYears = true;
        years = [];
        selectedYear = null;
      });
      final loadedYears = await _service.fetchYearsForCountry(country);
      if (!mounted) return;
      setState(() {
        years = loadedYears;
        if (years.isNotEmpty) {
          selectedYear = years.last;
        }
        isLoadingYears = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingYears = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            _currentLanguage == 'si'
                ? ExportDetailsByCountrySi.title
                : 'Export Details by Country',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            _currentLanguage == 'si'
                ? ExportDetailsByCountrySi.title
                : 'Export Details by Country',
          ),
          backgroundColor: const Color(0xFF2E7D32),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  (_currentLanguage == 'si'
                          ? ExportDetailsByCountrySi.errorLoadingCountries
                          : 'Error loading countries: ') +
                      '$errorMessage',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCountries,
                child: Text(
                  _currentLanguage == 'si'
                      ? ExportDetailsByCountrySi.retry
                      : 'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _currentLanguage == 'si'
              ? ExportDetailsByCountrySi.title
              : 'Export Details by Country',
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: selectedCountry == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: Colors.black87,
                onPressed: () {
                  setState(() {
                    selectedCountry = null;
                    years = [];
                    selectedYear = null;
                  });
                },
              ),
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
                  if (isLoadingYears)
                    Padding(
                      padding: EdgeInsets.all(responsive.mediumSpacing),
                      child: const CircularProgressIndicator(),
                    )
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
                  _currentLanguage == 'si'
                      ? ExportDetailsByCountrySi.descriptionTitle
                      : 'Sri Lanka\'s Major Export Markets',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentLanguage == 'si'
                      ? ExportDetailsByCountrySi.descriptionBody
                      : 'Track export volumes and pricing trends across key international markets',
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

  // Get flag emoji for country
  String _getFlagForCountry(String country) {
    final flags = {
      'India': '🇮🇳',
      'Germany': '🇩🇪',
      'Spain': '🇪🇸',
      'UAE': '🇦🇪',
      'Japan': '🇯🇵',
      'UK': '🇬🇧',
      'USA': '🇺🇸',
      'Canada': '🇨🇦',
    };
    return flags[country] ?? '🌍';
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
          .map((country) => _buildCountrySelectionCard(country, responsive))
          .toList(),
    );
  }

  // Single country card in the grid
  Widget _buildCountrySelectionCard(String country, Responsive responsive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCountry = country;
        });
        _loadYearsForCountry(country);
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
            Text(
              _getFlagForCountry(country),
              style: const TextStyle(fontSize: 48),
            ),
            SizedBox(height: responsive.smallSpacing),
            Text(
              _currentLanguage == 'si'
                  ? MarketForecastSi.translateCountry(country)
                  : country,
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

  // Country details section
  Widget _buildCountryDetails(Responsive responsive) {
    final country = selectedCountry!;

    if (selectedYear == null) {
      return Container(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        decoration: BoxDecoration(
          color: Colors.yellow.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _currentLanguage == 'si'
              ? ExportDetailsByCountrySi.noDataForCountry
              : 'No data available for this country',
        ),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: _service.fetchExportDetails(
        country: country,
        year: selectedYear!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(responsive.mediumSpacing),
              child: const CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(responsive.mediumSpacing),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              (_currentLanguage == 'si'
                      ? ExportDetailsByCountrySi.errorLoadingDetails
                      : 'Error loading details: ') +
                  '${snapshot.error}',
            ),
          );
        }

        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return Container(
            padding: EdgeInsets.all(responsive.mediumSpacing),
            decoration: BoxDecoration(
              color: Colors.yellow.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _currentLanguage == 'si'
                  ? ExportDetailsByCountrySi.noDataForSelection
                  : 'No data available for this selection',
            ),
          );
        }

        const expectedTypes = [
          'Ground Pepper',
          'Whole Pepper',
          'Pepper Oil',
          'Pepper Oleoresin',
        ];

        const normalizedToExpected = {
          'ground pepper': 'Ground Pepper',
          'whole pepper': 'Whole Pepper',
          'pepper oil': 'Pepper Oil',
          'pepper oleoresin': 'Pepper Oleoresin',
        };

        final byType = <String, Map<String, dynamic>>{};
        for (final item in data) {
          if (item is! Map<String, dynamic>) continue;
          final rawType = (item['pepper_type'] ?? '').toString();
          final normalizedType = rawType.trim().toLowerCase();
          final expectedType = normalizedToExpected[normalizedType];
          if (expectedType != null) {
            byType[expectedType] = item;
          }
        }

        final sectionColors = [
          const Color(0xFFBBDEFB),
          const Color(0xFFA5D6A7),
          const Color(0xFFFFE082),
          const Color(0xFFD1C4E9),
        ];

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
                        _getFlagForCountry(country),
                        style: const TextStyle(fontSize: 48),
                      ),
                      SizedBox(width: responsive.mediumSpacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentLanguage == 'si'
                                  ? MarketForecastSi.translateCountry(country)
                                  : country,
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize + 4,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: responsive.smallSpacing),
                            Text(
                              '${_currentLanguage == 'si' ? ExportDetailsByCountrySi.yearPrefix : 'Year'}: $selectedYear',
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
                  ...expectedTypes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final type = entry.value;
                    final item = byType[type];
                    final exportVolume = _formatValue(
                      item?['export_volume'],
                      suffix: ' MT',
                      decimals: 0,
                    );
                    final exportValue = _formatValue(
                      item?['export_value'],
                      prefix: '\$ ',
                      decimals: 0,
                    );
                    final sectionColor =
                        sectionColors[index % sectionColors.length];

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == expectedTypes.length - 1
                            ? 0
                            : responsive.smallSpacing,
                      ),
                      child: _buildPepperTypeSection(
                        type,
                        exportVolume,
                        exportValue,
                        sectionColor,
                        responsive,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatValue(
    dynamic value, {
    String prefix = '',
    String suffix = '',
    int decimals = 0,
  }) {
    if (value == null) return '-';

    if (value is num) {
      return '$prefix${value.toStringAsFixed(decimals)}$suffix';
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == '-') return '-';
      final parsed = num.tryParse(trimmed);
      if (parsed != null) {
        return '$prefix${parsed.toStringAsFixed(decimals)}$suffix';
      }
      return '$prefix$trimmed$suffix';
    }

    return '$prefix${value.toString()}$suffix';
  }

  // Section for each pepper type with volume and value
  Widget _buildPepperTypeSection(
    String pepperType,
    String exportVolume,
    String exportValue,
    Color sectionColor,
    Responsive responsive,
  ) {
    final icon = _iconForPepperType(pepperType);
    final displayType = _currentLanguage == 'si'
        ? MarketForecastSi.translatePepperType(pepperType)
        : pepperType;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: sectionColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sectionColor.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            color: sectionColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: sectionColor.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.black87, size: 18),
              ),
              SizedBox(width: responsive.smallSpacing),
              Expanded(
                child: Text(
                  '${_currentLanguage == 'si' ? ExportDetailsByCountrySi.pepperType : 'Pepper Type'}: $displayType',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize + 1,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.smallSpacing),
          _buildDetailRow(
            _currentLanguage == 'si'
                ? ExportDetailsByCountrySi.exportVolume
                : 'Export Volume',
            exportVolume,
            responsive,
          ),
          SizedBox(height: responsive.smallSpacing),
          _buildDetailRow(
            _currentLanguage == 'si'
                ? ExportDetailsByCountrySi.exportValue
                : 'Export Value',
            exportValue,
            responsive,
          ),
        ],
      ),
    );
  }

  // Row for individual details like volume and value
  Widget _buildDetailRow(String label, String value, Responsive responsive) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.smallSpacing,
        vertical: responsive.smallSpacing - 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Pepper type with icon
  IconData _iconForPepperType(String pepperType) {
    final lower = pepperType.toLowerCase();
    if (lower.contains('ground')) return Icons.grain_rounded;
    if (lower.contains('whole')) return Icons.circle_rounded;
    if (lower.contains('oil')) return Icons.opacity_rounded;
    if (lower.contains('oleoresin')) return Icons.science_rounded;
    return Icons.local_florist_rounded;
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
                _currentLanguage == 'si'
                    ? ExportDetailsByCountrySi.selectYear
                    : 'Select Year',
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
                    years = [];
                    selectedYear = null;
                  });
                },
                child: Text(
                  _currentLanguage == 'si'
                      ? ExportDetailsByCountrySi.back
                      : 'Back',
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
          if (years.isEmpty)
            Text(
              _currentLanguage == 'si'
                  ? ExportDetailsByCountrySi.noYearsAvailable
                  : 'No years available',
            )
          else
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
                          year.toString(),
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
