import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../utils/responsive.dart';
import '../../../utils/market forecast/export_price_trends_si.dart';
import 'export_details_by_country.dart';
import '../../../services/auth_service.dart';
import '../../../utils/language_prefs.dart';
import '../../../services/market_forecast/past_export_price_service.dart';

class ExportPriceTrends extends StatefulWidget {
  const ExportPriceTrends({super.key});

  @override
  State<ExportPriceTrends> createState() => _ExportPriceTrendsState();
}

class _ExportPriceTrendsState extends State<ExportPriceTrends> {
  String selectedYear = '2025';
  int selectedMonthFrom = 0; // January
  int selectedMonthTo = 6; // July

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final AuthService _authService = AuthService();
  final PastExportPriceService _priceService = PastExportPriceService();
  String? userRole;
  bool isLoading = true;
  bool isLoadingData = true;
  String? errorMessage;
  String _currentLanguage = 'en'; // default to English language

  List<String> years = [];
  final List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final List<String> monthsFull = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<double?> _pricesByMonth = List<double?>.filled(12, null);
  int? _selectedSpotIndex;

  // Generate chart data based on selected month range
  List<FlSpot> getChartData() {
    List<FlSpot> spots = [];
    for (
      int i = selectedMonthFrom;
      i <= selectedMonthTo && i < _pricesByMonth.length;
      i++
    ) {
      final value = _pricesByMonth[i];
      if (value != null) {
        spots.add(FlSpot((i - selectedMonthFrom).toDouble(), value));
      }
    }
    return spots;
  }

  // Get label for selected month range
  String getDateRangeLabel() {
    final from = _currentLanguage == 'si'
        ? ExportPriceTrendsSi.translateMonth(months[selectedMonthFrom])
        : months[selectedMonthFrom];
    final to = _currentLanguage == 'si'
        ? ExportPriceTrendsSi.translateMonth(months[selectedMonthTo])
        : months[selectedMonthTo];
    return '$from - $to';
  }

  // Calculate peak, lowest, and average prices for the selected range
  Map<String, double> calculateStats() {
    final spots = getChartData();
    if (spots.isEmpty) {
      return {'peak': 0, 'lowest': 0, 'average': 0};
    }

    final values = spots.map((spot) => spot.y).toList();
    final peak = values.reduce((a, b) => a > b ? a : b);
    final lowest = values.reduce((a, b) => a < b ? a : b);
    final average = values.fold(0.0, (sum, val) => sum + val) / values.length;

    return {'peak': peak, 'lowest': lowest, 'average': average};
  }

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadYearsAndData();
    // Load language preference
    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) setState(() => _currentLanguage = lang);
    });
  }

  //Load user role to determine if country navigation should be shown
  Future<void> _loadUserRole() async {
    final role = await _authService.storage.read(key: "role");
    setState(() {
      userRole = role;
      isLoading = false;
    });
  }

  // Load years and price data
  Future<void> _loadYearsAndData() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoadingData = true;
        errorMessage = null;
      });

      final loadedYears = await _priceService.fetchYears();
      if (!mounted) return;

      final loadedYearStrings =
          loadedYears.map((year) => year.toString()).toList()..sort();
      if (loadedYearStrings.isNotEmpty) {
        setState(() {
          years = loadedYearStrings;
          selectedYear = years.last;
        });
        await _loadPriceData();
      } else {
        setState(() {
          years = [];
          _pricesByMonth = List<double?>.filled(12, null);
          isLoadingData = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingData = false;
        errorMessage = e.toString();
      });
    }
  }

  // Load price data based on selected filters
  Future<void> _loadPriceData() async {
    try {
      if (!mounted) return;
      final yearValue = int.tryParse(selectedYear) ?? 0;
      if (yearValue <= 0) return;

      setState(() {
        isLoadingData = true;
        errorMessage = null;
      });

      final data = await _priceService.fetchPastExportPrices(
        year: yearValue,
        monthFrom: monthsFull[selectedMonthFrom],
        monthTo: monthsFull[selectedMonthTo],
      );

      if (!mounted) return;
      final prices = List<double?>.filled(12, null);
      for (final item in data) {
        final monthName = item['month']?.toString();
        if (monthName == null) continue;
        final monthIndex = monthsFull.indexWhere(
          (month) => month.toLowerCase() == monthName.toLowerCase(),
        );
        if (monthIndex == -1) continue;

        final priceValue =
            item['export_price_per_kg_lkr'] ?? item['export_price'];
        if (priceValue is num) {
          prices[monthIndex] = priceValue.toDouble();
        }
      }

      setState(() {
        _pricesByMonth = prices;
        _selectedSpotIndex = null;
        isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingData = false;
        errorMessage = e.toString();
      });
    }
  }

  // Dispose overlay
  @override
  void dispose() {
    _overlayEntry?.remove(); // Remove any open overlay
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _currentLanguage == 'si'
              ? ExportPriceTrendsSi.pageTitle
              : 'Past Export Price Trends',
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _descriptionSection(),
            SizedBox(height: responsive.mediumSpacing),
            // Only show country navigation for exporters
            if (userRole == 'exporter') ...[
              _countryNavCard(responsive),
              SizedBox(height: responsive.mediumSpacing),
            ],
            _filtersSection(),
            SizedBox(height: responsive.mediumSpacing),
            if (errorMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: responsive.mediumSpacing),
                child: Text(
                  'Failed to load data: $errorMessage',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: responsive.smallFontSize + 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            _chartCard(),
            SizedBox(height: responsive.mediumSpacing),
            _priceStats(),
            SizedBox(height: responsive.mediumSpacing),
            _insightsCard(),
          ],
        ),
      ),
    );
  }

  // Description Section
  Widget _descriptionSection() {
    final responsive = context.responsive;
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
              Icons.analytics_rounded,
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
                      ? ExportPriceTrendsSi.headerTitle
                      : 'Historical Export Price Analysis',
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
                      ? ExportPriceTrendsSi.headerBody
                      : 'Filter data to view past export prices of black pepper in Sri Lanka. Analyze trends and make informed decisions.',
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
    );
  }

  // Navigation card to "Export Details by Country"
  Widget _countryNavCard(Responsive responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFD0F2E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 89, 96, 95).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
              ),
            ),
            child: const Icon(Icons.public, color: Colors.white, size: 22),
          ),
          SizedBox(width: responsive.mediumSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentLanguage == 'si'
                      ? ExportPriceTrendsSi.exportDetailsByCountry
                      : 'Export Details by Country',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize + 3,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: responsive.smallSpacing / 2),
                Text(
                  _currentLanguage == 'si'
                      ? ExportPriceTrendsSi.exportDetailsBody
                      : 'Tap to view country-wise volumes, prices, and trends.',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.smallSpacing),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: responsive.smallSpacing + 8,
                vertical: responsive.smallSpacing + 2,
              ),
              elevation: 4,
              shadowColor: const Color(0xFF2E7D32).withOpacity(0.35),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExportDetailsByCountry(),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentLanguage == 'si' ? ExportPriceTrendsSi.view : 'View',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Filters
  Widget _filtersSection() {
    final responsive = context.responsive;
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
                ? ExportPriceTrendsSi.filterData
                : 'Filter Data',
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: responsive.mediumSpacing),
          Row(
            children: [
              Expanded(
                child: _customDropdown(
                  _currentLanguage == 'si' ? ExportPriceTrendsSi.year : 'Year',
                  selectedYear,
                  years,
                  (value) {
                    setState(() => selectedYear = value);
                    _loadPriceData();
                  },
                ),
              ),
              SizedBox(width: responsive.smallSpacing),
              Expanded(
                child: _customDropdown(
                  _currentLanguage == 'si' ? ExportPriceTrendsSi.from : 'From',
                  months[selectedMonthFrom],
                  months,
                  (value) {
                    final index = months.indexOf(value);
                    if (index != -1 && index <= selectedMonthTo) {
                      setState(() => selectedMonthFrom = index);
                      _loadPriceData();
                    }
                  },
                ),
              ),
              SizedBox(width: responsive.smallSpacing),
              Expanded(
                child: _customDropdown(
                  _currentLanguage == 'si' ? ExportPriceTrendsSi.to : 'To',
                  months[selectedMonthTo],
                  months,
                  (value) {
                    final index = months.indexOf(value);
                    if (index != -1 && index >= selectedMonthFrom) {
                      setState(() => selectedMonthTo = index);
                      _loadPriceData();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Custom Dropdown implementation
  Widget _customDropdown(
    String title,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    final key = GlobalKey();
    final responsive = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: responsive.smallFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: responsive.smallSpacing / 2),
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: key,
            onTap: () => _toggleDropdown(key, items, value, onChanged),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.smallSpacing + 4,
                vertical: responsive.smallSpacing + 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  responsive.value(mobile: 10, tablet: 12, desktop: 14),
                ),
                border: Border.all(color: Colors.grey.shade300),
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
                  Flexible(
                    child: Text(
                      _currentLanguage == 'si'
                          ? ExportPriceTrendsSi.translateMonth(value)
                          : value,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: responsive.bodyFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: responsive.mediumIconSize,
                    color: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Toggle dropdown visibility
  void _toggleDropdown(
    GlobalKey key,
    List<String> items,
    String value,
    ValueChanged<String> onChanged,
  ) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      return;
    }

    const double itemHeight = 48.0;
    final double dropdownHeight = itemHeight * items.length;

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
                              ? ExportPriceTrendsSi.translateMonth(item)
                              : item,
                        ),
                        selectedTileColor: Colors.green.withOpacity(0.1),
                        selected: item == value,
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

  // Chart
  Widget _chartCard() {
    final chartData = getChartData();
    final dateRange = getDateRangeLabel();
    final responsive = context.responsive;

    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.smallSpacing + 4,
              vertical: responsive.smallSpacing / 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2E7D32).withOpacity(0.2),
              ),
            ),
            child: Text(
              _currentLanguage == 'si'
                  ? ExportPriceTrendsSi.globalTrends
                  : 'Global Black Pepper Price Trends',
              style: TextStyle(
                fontSize: responsive.titleFontSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
          SizedBox(height: responsive.smallSpacing),
          Text(
            dateRange,
            style: TextStyle(
              color: Colors.grey,
              fontSize: responsive.bodyFontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: responsive.mediumSpacing),
          SizedBox(
            height: responsive.value(mobile: 220, tablet: 260, desktop: 300),
            child: isLoadingData
                ? const Center(child: CircularProgressIndicator())
                : chartData.isEmpty
                ? Center(
                    child: Text(
                      _currentLanguage == 'si'
                          ? ExportPriceTrendsSi.noData
                          : 'No data for the selected range',
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final selectedIndex =
                          _selectedSpotIndex != null &&
                              _selectedSpotIndex! < chartData.length
                          ? _selectedSpotIndex
                          : null;

                      final lineBarData = LineChartBarData(
                        spots: chartData,
                        isCurved: true,
                        dotData: FlDotData(show: true),
                        color: Colors.blue,
                        barWidth: 3,
                        showingIndicators: selectedIndex != null
                            ? [selectedIndex]
                            : const [],
                      );

                      return LineChart(
                        LineChartData(
                          minY: 500,
                          maxY: 3000,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            handleBuiltInTouches: false,
                            touchCallback: (event, response) {
                              if (!event.isInterestedForInteractions) {
                                return;
                              }

                              final spots = response?.lineBarSpots;
                              if (spots == null || spots.isEmpty) {
                                setState(() {
                                  _selectedSpotIndex = null;
                                });
                                return;
                              }

                              setState(() {
                                _selectedSpotIndex = spots.first.spotIndex;
                              });
                            },
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) =>
                                  Colors.blueAccent,
                              tooltipRoundedRadius: 8,
                              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final monthIndex =
                                      spot.x.toInt() + selectedMonthFrom;
                                  final monthName = monthIndex < months.length
                                      ? (_currentLanguage == 'si'
                                            ? ExportPriceTrendsSi.translateMonth(
                                                months[monthIndex],
                                              )
                                            : months[monthIndex])
                                      : '';
                                  return LineTooltipItem(
                                    '$monthName\n${_currentLanguage == 'si' ? ExportPriceTrendsSi.currency : 'Rs.'}${spot.y.toInt()}',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 500,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${_currentLanguage == 'si' ? ExportPriceTrendsSi.currency : 'Rs.'}${value.toInt()}',
                                    style: TextStyle(
                                      fontSize: responsive.smallFontSize - 1,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index =
                                      value.toInt() + selectedMonthFrom;
                                  if (index < months.length) {
                                    final label = _currentLanguage == 'si'
                                        ? ExportPriceTrendsSi.translateMonth(
                                            months[index],
                                          )
                                        : months[index];
                                    return Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: responsive.smallFontSize,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          showingTooltipIndicators: selectedIndex != null
                              ? [
                                  ShowingTooltipIndicators([
                                    LineBarSpot(
                                      lineBarData,
                                      0,
                                      chartData[selectedIndex],
                                    ),
                                  ]),
                                ]
                              : const [],
                          lineBarsData: [lineBarData],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Stats
  Widget _priceStats() {
    final stats = calculateStats();
    final responsive = context.responsive;
    return Row(
      children: [
        Expanded(
          child: _statCard(
            _currentLanguage == 'si'
                ? ExportPriceTrendsSi.peakPrice
                : 'Peak Price',
            '${_currentLanguage == 'si' ? ExportPriceTrendsSi.currency : 'Rs.'}${stats['peak']!.toInt()} /kg',
            Icons.trending_up,
            const Color(0xFF43A047),
          ),
        ),
        SizedBox(width: responsive.smallSpacing),
        Expanded(
          child: _statCard(
            _currentLanguage == 'si'
                ? ExportPriceTrendsSi.lowestPrice
                : 'Lowest Price',
            '${_currentLanguage == 'si' ? ExportPriceTrendsSi.currency : 'Rs.'}${stats['lowest']!.toInt()} /kg',
            Icons.trending_down,
            const Color(0xFFE53935),
          ),
        ),
        SizedBox(width: responsive.smallSpacing),
        Expanded(
          child: _statCard(
            _currentLanguage == 'si' ? ExportPriceTrendsSi.average : 'Average',
            '${_currentLanguage == 'si' ? ExportPriceTrendsSi.currency : 'Rs.'}${stats['average']!.toInt()} /kg',
            Icons.show_chart,
            const Color(0xFF1565C0),
          ),
        ),
      ],
    );
  }

  // Stats Card to display peak, lowest, and average prices
  Widget _statCard(String title, String value, IconData icon, Color color) {
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.all(responsive.smallSpacing + 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: responsive.smallSpacing / 2),
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.smallFontSize,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: responsive.smallSpacing / 3),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.bodyFontSize + 2,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Insights
  Widget _insightsCard() {
    final responsive = context.responsive;
    final data = getChartData();
    bool isBullish = false;
    if (data.isNotEmpty) {
      final start = data.first.y;
      final end = data.last.y;
      final change = end - start;
      isBullish = change >= 0;
    }

    const Color tileGreen = Color(0xFF43A047); // Trend tile
    const Color tilePurple = Color(0xFF8E24AA); // Peak vs Average tile
    const Color tileBlue = Color(0xFF1565C0); // Momentum tile
    const Color tileOrange = Color(0xFFEF6C00); // Recommendation tile

    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.smallSpacing + 4,
              vertical: responsive.smallSpacing / 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2E7D32).withOpacity(0.2),
              ),
            ),
            child: Text(
              _currentLanguage == 'si'
                  ? ExportPriceTrendsSi.keyInsights
                  : 'Key Insights',
              style: TextStyle(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
                fontSize: responsive.smallFontSize + 4,
              ),
            ),
          ),
          SizedBox(height: responsive.mediumSpacing),
          // Responsive grid of insight tiles
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 2 : 1,
                mainAxisSpacing: responsive.smallSpacing,
                crossAxisSpacing: responsive.smallSpacing,
                childAspectRatio: isWide ? 3.0 : 3.2,
                children: [
                  _insightTile(
                    icon: Icons.trending_up,
                    color: tileGreen,
                    title: isBullish
                        ? (_currentLanguage == 'si'
                              ? ExportPriceTrendsSi.bullish
                              : 'Prices are trending upward')
                        : (_currentLanguage == 'si'
                              ? ExportPriceTrendsSi.bearish
                              : 'Prices are trending downward'),
                    subtitle: isBullish
                        ? (_currentLanguage == 'si'
                              ? ExportPriceTrendsSi.bullishDetail
                              : 'Recent months show gains driven by importer demand.')
                        : (_currentLanguage == 'si'
                              ? ExportPriceTrendsSi.bearishDetail
                              : 'Recent months show easing prices with improving supply.'),
                  ),
                  _insightTile(
                    icon: Icons.attach_money,
                    color: tilePurple,
                    title: _currentLanguage == 'si'
                        ? ExportPriceTrendsSi.peakVsAverage
                        : 'Peak vs Average',
                    subtitle: _currentLanguage == 'si'
                        ? ExportPriceTrendsSi.peakVsAverageDetail
                        : 'Time exports near peaks; use average for pricing baseline.',
                  ),
                  _insightTile(
                    icon: Icons.timeline,
                    color: tileBlue,
                    title: _currentLanguage == 'si'
                        ? ExportPriceTrendsSi.momentumStability
                        : 'Momentum & Stability',
                    subtitle: _currentLanguage == 'si'
                        ? ExportPriceTrendsSi.momentumStabilityDetail
                        : 'Track monthly momentum; favor stable windows for bulk shipments.',
                  ),
                  _insightTile(
                    icon: Icons.insights,
                    color: tileOrange,
                    title: _currentLanguage == 'si'
                        ? ExportPriceTrendsSi.recommendation
                        : 'Recommendation',
                    subtitle: isBullish
                        ? (_currentLanguage == 'si'
                              ? ExportPriceTrendsSi.recommendationBullish
                              : 'Stagger shipments to capitalize on upward momentum.')
                        : (_currentLanguage == 'si'
                              ? ExportPriceTrendsSi.recommendationBearish
                              : 'Hedge and optimize turnover during softer pricing.'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Insights section
  Widget _insightTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.all(responsive.smallSpacing + 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.22)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: responsive.value(mobile: 36, tablet: 40, desktop: 44),
            height: responsive.value(mobile: 36, tablet: 40, desktop: 44),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: responsive.smallSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: responsive.bodyFontSize,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: responsive.smallSpacing / 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: responsive.smallFontSize + 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card decoration for consistent styling
  BoxDecoration _cardDecoration() {
    final responsive = context.responsive;
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        responsive.value(mobile: 12, tablet: 14, desktop: 16),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
