import 'package:CeylonPepper/features/market_forecast/recommendations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class WeeklyPrediction extends StatelessWidget {
  final String? year;
  final String? month;
  final String? week;

  WeeklyPrediction({
    super.key,
    required this.year,
    required this.month,
    required this.week,
  });

  final List<double> blackPepperPriceData = <double>[
    1500,
    1600,
    1750,
    2000,
    1800,
    1950,
    2100,
    2200,
    2300,
    2400,
  ];

  final List<double> whitePepperPriceData = <double>[
    1800,
    1750,
    1900,
    2100,
    2000,
    2200,
    2300,
    2400,
    2500,
    2600,
  ];

  final Color blackPepperColor = Colors.orange;
  final Color whitePepperColor = Colors.blue;

  String getMonthName(int month) {
    final monthNames = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return monthNames[month];
  }

  List<Map<String, dynamic>> generatePreviousWeeks(
    int year,
    int month,
    int weekNumber,
    int count,
  ) {
    List<Map<String, dynamic>> weeks = [];

    DateTime firstDayOfMonth = DateTime(year, month, 1);
    int dayOfWeek = firstDayOfMonth.weekday;
    int offset = (dayOfWeek == 1) ? 0 : (8 - dayOfWeek);
    DateTime firstMonday = firstDayOfMonth.add(Duration(days: offset));
    DateTime selectedWeekStart = firstMonday.add(
      Duration(days: (weekNumber - 1) * 7),
    );

    for (int i = count - 1; i >= 0; i--) {
      DateTime weekStart = selectedWeekStart.subtract(Duration(days: i * 7));
      int wYear = weekStart.year;
      int wMonth = weekStart.month;

      DateTime firstOfMonth = DateTime(wYear, wMonth, 1);
      int firstWeekday = firstOfMonth.weekday;
      int firstMondayOffset = (firstWeekday == 1) ? 0 : (8 - firstWeekday);
      DateTime monthFirstMonday = firstOfMonth.add(
        Duration(days: firstMondayOffset),
      );

      int weekInMonth =
          ((weekStart.difference(monthFirstMonday).inDays) / 7).floor() + 1;
      if (weekStart.isBefore(monthFirstMonday)) weekInMonth = 1;

      weeks.add({'year': wYear, 'month': wMonth, 'week': weekInMonth});
    }

    return weeks;
  }

  List<String> formatWeekLabelsFromMap(List<Map<String, dynamic>> weeks) {
    final monthNames = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return weeks
        .map((w) => "${monthNames[w['month']!]} w${w['week']!}")
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final y = int.tryParse(year ?? '') ?? 2025;
    final m = int.tryParse(month ?? '') ?? 1;
    final w = int.tryParse(week ?? '') ?? 1;

    final previousWeeks = generatePreviousWeeks(y, m, w, 5);
    final weekLabels = formatWeekLabelsFromMap(previousWeeks);
    final dataLength = previousWeeks.length;

    List<double> blackData = [];
    List<double> whiteData = [];
    for (int i = 0; i < dataLength; i++) {
      int priceIndex = i % blackPepperPriceData.length;
      blackData.add(blackPepperPriceData[priceIndex]);
      whiteData.add(whitePepperPriceData[priceIndex]);
    }

    // Calculate statistics
    final currentPrice = 1890.0; // This week's price
    final predictedPrice = 2150.0; // Next week's predicted price
    final previousPrice = blackData.last;
    final priceChange = predictedPrice - currentPrice;
    final percentageChange = (priceChange / currentPrice) * 100;
    final highPrice = blackData.reduce((a, b) => a > b ? a : b);
    final lowPrice = blackData.reduce((a, b) => a < b ? a : b);
    final avgPrice = blackData.reduce((a, b) => a + b) / blackData.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: const Text('Price Forecast Analysis'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: responsive.mediumSpacing),

              // Header Card with Period and Predicted Price
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(responsive.largeSpacing),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green[400]!.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Period Information
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.mediumSpacing,
                        vertical: responsive.smallSpacing / 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            week ?? 'Date Range',
                            style: TextStyle(
                              fontSize: responsive.bodyFontSize,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.mediumSpacing),

                    // Predicted Price Section
                    Text(
                      'Predicted Price',
                      style: TextStyle(
                        fontSize: responsive.smallFontSize,
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Rs. ',
                          style: TextStyle(
                            fontSize: responsive.titleFontSize * 1.2,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${predictedPrice.toInt()}',
                          style: const TextStyle(
                            fontSize: 56,
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '/kg',
                            style: TextStyle(
                              fontSize: responsive.titleFontSize * 1.1,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: responsive.mediumSpacing),

                    // Price Change Indicator
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.mediumSpacing,
                        vertical: responsive.smallSpacing,
                      ),
                      decoration: BoxDecoration(
                        color: priceChange >= 0
                            ? Colors.lightGreen[300]!.withOpacity(0.8)
                            : Colors.red[300]!.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (priceChange >= 0
                                        ? Colors.lightGreen[300]
                                        : Colors.red[300])!
                                    .withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            priceChange >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: Colors.black87,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Price Change',
                                style: TextStyle(
                                  fontSize: responsive.smallFontSize,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${priceChange >= 0 ? '+' : ''}Rs. ${priceChange.toStringAsFixed(0)} (${percentageChange.toStringAsFixed(1)}%)',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: responsive.mediumSpacing),
                  ],
                ),
              ),

              SizedBox(height: responsive.largeSpacing),

              // Current vs Previous Price
              ResponsiveText(
                'Current vs Previous Price',
                mobileFontSize: responsive.titleFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
              SizedBox(height: responsive.mediumSpacing),

              Center(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(responsive.mediumSpacing),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _priceColumn(
                        icon: Icons.trending_flat,
                        label: 'Previous Week',
                        value: previousPrice.toInt(),
                        color: Colors.blue[700],
                        responsive: responsive,
                      ),
                      Container(height: 50, width: 1, color: Colors.grey[300]),
                      _priceColumn(
                        icon: Icons.trending_up,
                        label: 'Current Week',
                        value: currentPrice.toInt(),
                        color: Colors.green[700],
                        responsive: responsive,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: responsive.largeSpacing),

              ResponsiveText(
                'Past Price Trend',
                mobileFontSize: responsive.titleFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
              SizedBox(height: responsive.smallSpacing / 2),
              Text(
                'Last 5 weeks comparison',
                style: TextStyle(
                  fontSize: responsive.smallFontSize,
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: responsive.mediumSpacing),
              _buildLegend(responsive),
              SizedBox(height: responsive.mediumSpacing),

              Center(
                child: Container(
                  width: responsive.maxContentWidth,
                  height: 260,
                  padding: EdgeInsets.all(responsive.smallSpacing),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      responsive.largeSpacing / 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (dataLength - 1).toDouble(),
                      minY: 1000,
                      maxY: 3200,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 500,
                      ),
                      borderData: FlBorderData(show: false),
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
                            reservedSize: 40,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= weekLabels.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                angle: 0.5,
                                child: Text(
                                  weekLabels[value.toInt()],
                                  style: TextStyle(
                                    fontSize: responsive.smallFontSize * 0.9,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          barWidth: 3,
                          color: blackPepperColor,
                          dotData: FlDotData(show: true),
                          spots: List.generate(
                            dataLength,
                            (i) => FlSpot(i.toDouble(), blackData[i]),
                          ),
                        ),
                        LineChartBarData(
                          isCurved: true,
                          barWidth: 3,
                          color: whitePepperColor,
                          dotData: FlDotData(show: true),
                          spots: List.generate(
                            dataLength,
                            (i) => FlSpot(i.toDouble(), whiteData[i]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: responsive.largeSpacing),

              // Market Insights
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(responsive.mediumSpacing),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Market Insights',
                          style: TextStyle(
                            fontSize: responsive.bodyFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.smallSpacing),
                    _buildInsightRow(
                      Icons.trending_up,
                      'Price trend shows ${priceChange >= 0 ? 'upward' : 'downward'} movement',
                      responsive,
                    ),
                    const SizedBox(height: 6),
                    _buildInsightRow(
                      Icons.analytics_outlined,
                      'Historical average: Rs. ${avgPrice.toInt()}/kg',
                      responsive,
                    ),
                    const SizedBox(height: 6),
                    _buildInsightRow(
                      Icons.info_outline,
                      'Price range: Rs. ${lowPrice.toInt()} - Rs. ${highPrice.toInt()}',
                      responsive,
                    ),
                  ],
                ),
              ),

              SizedBox(height: responsive.largeSpacing),

              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Recommendations',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Recommendations(
                            // predictedPrice: next-week forecast (1950)
                            predictedPrice: predictedPrice,
                            currentPrice: currentPrice,
                            previousPrice: previousPrice,
                            averagePrice: avgPrice,
                            month: month,
                            week: week,
                            year: year,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: responsive.largeSpacing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String text, Responsive responsive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.smallFontSize,
              color: Colors.blue[900],
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Responsive responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(
          color: blackPepperColor,
          label: 'Black Pepper',
          responsive: responsive,
        ),
        SizedBox(width: responsive.mediumSpacing),
        _legendItem(
          color: whitePepperColor,
          label: 'White Pepper',
          responsive: responsive,
        ),
      ],
    );
  }

  Widget _priceColumn({
    required IconData icon,
    required String label,
    required int value,
    required Color? color,
    required Responsive responsive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: responsive.smallSpacing / 2),
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.smallFontSize,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Rs. $value /kg',
          style: TextStyle(
            fontSize: responsive.titleFontSize * 0.9,
            color: Colors.grey[900],
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required Responsive responsive,
  }) {
    return Row(
      children: [
        Container(
          width: responsive.smallSpacing,
          height: responsive.smallSpacing,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: responsive.smallSpacing / 2),
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.bodyFontSize,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
