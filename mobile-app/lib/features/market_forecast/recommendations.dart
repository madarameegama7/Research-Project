import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class Recommendations extends StatelessWidget {
  // predictedPrice = forecasted next week's price
  // currentPrice = this week's price
  // previousPrice = last week's price
  final double predictedPrice;
  final double currentPrice;
  final double previousPrice;
  final double averagePrice;
  final String? month;
  final String? week;
  final String? year;

  const Recommendations({
    Key? key,
    this.predictedPrice = 1890,
    this.currentPrice = 1800,
    this.previousPrice = 1750,
    this.averagePrice = 1850,
    this.month,
    this.week,
    this.year,
  }) : super(key: key);

  String getRecommendation() {
    // If predicted (next week) price is higher than current price → WAIT (sell next week)
    // If predicted price is lower or equal → SELL now
    return predictedPrice > currentPrice ? 'WAIT' : 'SELL';
  }

  String getRecommendationReason() {
    if (predictedPrice > currentPrice) {
      final priceIncrease = predictedPrice - currentPrice;
      return 'Next week price is Rs. ${priceIncrease.toInt()} higher than current. Wait to sell next week at Rs. ${predictedPrice.toInt()}/kg.';
    } else {
      final priceDrop = currentPrice - predictedPrice;
      return 'Predicted price is Rs. ${priceDrop.toInt()} lower. Sell this week to avoid a drop.';
    }
  }

  String getWaitUntilPrice() {
    // For WAIT recommendations, suggest selling at the predicted (next week) price
    return 'Rs. ${predictedPrice.toInt()}/kg (next week forecast)';
  }

  List<String> getKeyFactors() {
    final priceChange = ((predictedPrice - currentPrice) / currentPrice) * 100;
    final List<String> factors = [];

    factors.add('Previous Week: Rs. ${previousPrice.toInt()}/kg');
    factors.add('Current Week: Rs. ${currentPrice.toInt()}/kg');
    factors.add('Next Week (Predicted): Rs. ${predictedPrice.toInt()}/kg');
    factors.add(
      'Price Change (current → predicted): ${priceChange > 0 ? '+' : ''}${priceChange.toStringAsFixed(1)}%',
    );
    factors.add('Average Price: Rs. ${averagePrice.toInt()}/kg');

    if (predictedPrice > currentPrice) {
      final increase = predictedPrice - currentPrice;
      factors.add(
        'Expected increase: Rs. ${increase.toInt()} per kg next week',
      );
    } else {
      final decrease = currentPrice - predictedPrice;
      factors.add(
        'Expected decrease: Rs. ${decrease.toInt()} per kg next week',
      );
    }

    return factors;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final recommendation = getRecommendation();
    final isSellingRecommendation = recommendation == 'SELL';
    final priceChange = ((predictedPrice - currentPrice) / currentPrice) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Recommendations'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: responsive.largeSpacing),

              // Main Recommendation Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(responsive.largeSpacing),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSellingRecommendation
                        ? [Colors.lightBlue[200]!, Colors.lightBlue[200]!]
                        : [Colors.indigo[400]!, Colors.indigo[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isSellingRecommendation
                          ? Colors.lightBlue.withOpacity(0.3)
                          : Colors.indigo.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Recommended Action',
                      style: TextStyle(
                        fontSize: responsive.smallFontSize,
                        color: const Color.fromARGB(179, 0, 0, 0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: responsive.smallSpacing),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.largeSpacing,
                        vertical: responsive.smallSpacing,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        recommendation,
                        style: const TextStyle(
                          fontSize: 48,
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.mediumSpacing),
                    Text(
                      getRecommendationReason(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize,
                        color: const Color.fromARGB(255, 0, 0, 0),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: responsive.largeSpacing),

              // Period Information and Price Change
              Container(
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.green[700],
                              size: 28,
                            ),
                            SizedBox(height: responsive.smallSpacing / 2),
                            Text(
                              'Period',
                              style: TextStyle(
                                fontSize: responsive.smallFontSize,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              week ?? 'Date Range',
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize,
                                color: Colors.grey[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        Column(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: Colors.blue[700],
                              size: 28,
                            ),
                            SizedBox(height: responsive.smallSpacing / 2),
                            Text(
                              'Price Change',
                              style: TextStyle(
                                fontSize: responsive.smallFontSize,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${priceChange > 0 ? '+' : ''}${priceChange.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize,
                                color: priceChange > 0
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!isSellingRecommendation) ...[
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(responsive.mediumSpacing),
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.indigo[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: Colors.indigo[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sell When Price Reaches',
                                  style: TextStyle(
                                    fontSize: responsive.bodyFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              getWaitUntilPrice(),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Monitor the market regularly for better selling opportunities.',
                              style: TextStyle(
                                fontSize: responsive.smallFontSize,
                                color: Colors.indigo[800],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: responsive.largeSpacing),

              // Price Comparison Cards
              Text(
                'Price Analysis',
                style: TextStyle(
                  fontSize: responsive.titleFontSize - 2,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: responsive.mediumSpacing),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: responsive.mediumSpacing,
                mainAxisSpacing: responsive.mediumSpacing,
                childAspectRatio: 1.15,
                children: [
                  _buildPriceComparisonCard(
                    responsive,
                    'Previous Week',
                    'Rs. ${previousPrice.toInt()}/kg',
                    Icons.history,
                    Colors.grey[600]!,
                  ),
                  _buildPriceComparisonCard(
                    responsive,
                    'Current Week',
                    'Rs. ${currentPrice.toInt()}/kg',
                    Icons.calendar_today,
                    Colors.blue[600]!,
                  ),
                  _buildPriceComparisonCard(
                    responsive,
                    'Next Week (Predicted)',
                    'Rs. ${predictedPrice.toInt()}/kg',
                    Icons.trending_up,
                    Colors.green[600]!,
                  ),
                  _buildPriceComparisonCard(
                    responsive,
                    'Average Price',
                    'Rs. ${averagePrice.toInt()}/kg',
                    Icons.bar_chart,
                    Colors.purple[600]!,
                  ),
                ],
              ),

              SizedBox(height: responsive.largeSpacing),

              // Market Insights Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(responsive.mediumSpacing),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[50]!, Colors.orange[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber[700],
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Market Insights',
                          style: TextStyle(
                            fontSize: responsive.bodyFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.smallSpacing),
                    Text(
                      _getMarketInsight(),
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize - 1,
                        color: Colors.amber[900],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: responsive.largeSpacing),

              // Action Items Section
              Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.checklist,
                          color: Colors.green[700],
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Recommended Actions',
                          style: TextStyle(
                            fontSize: responsive.bodyFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.smallSpacing),
                    ..._getActionItems().asMap().entries.map((entry) {
                      final isLast = entry.key == _getActionItems().length - 1;
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: TextStyle(
                                      fontSize: responsive.smallFontSize - 1,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: responsive.bodyFontSize - 1,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!isLast)
                            SizedBox(height: responsive.smallSpacing),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),

              SizedBox(height: responsive.largeSpacing * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceComparisonCard(
    Responsive responsive,
    String label,
    String price,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: EdgeInsets.all(responsive.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                price,
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMarketInsight() {
    final priceChange = ((predictedPrice - currentPrice) / currentPrice) * 100;
    if (priceChange > 5) {
      return 'The market shows a strong upward trend with prices expected to increase significantly. This is a favorable time to hold your inventory for better returns.';
    } else if (priceChange > 0) {
      return 'Market conditions are stable with slight upward movement expected. Consider waiting for better prices if storage facilities allow.';
    } else if (priceChange < -5) {
      return 'The market is experiencing a downward trend. It is recommended to sell immediately to avoid further price drops.';
    } else {
      return 'Market prices are relatively stable with minimal changes expected. Sell when you have good storage conditions and time permits.';
    }
  }

  List<String> _getActionItems() {
    final recommendation = getRecommendation();
    if (recommendation == 'WAIT') {
      return [
        'Store your pepper in a dry, cool place to maintain quality',
        'Monitor market prices daily for optimal selling timing',
        'Prepare logistics and transport arrangements in advance',
        'Check weather forecasts for any unexpected market impacts',
        'Contact potential buyers to lock in selling arrangements',
      ];
    } else {
      return [
        'Harvest and prepare your pepper for immediate sale',
        'Contact local traders and buyers for best offers',
        'Arrange quality grading and packaging',
        'Complete sales transaction as soon as possible',
        'Document all sales records and transactions properly',
      ];
    }
  }
}
