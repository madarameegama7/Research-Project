import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class PastPriceReportsScreen extends StatefulWidget {
  const PastPriceReportsScreen({super.key});

  @override
  State<PastPriceReportsScreen> createState() => _PastPriceReportsScreenState();
}

class _PastPriceReportsScreenState extends State<PastPriceReportsScreen> {
  // Mock data for past submitted reports
  final List<Map<String, dynamic>> pastReports = [
    {
      'date': '2026-01-27',
      'district': 'Colombo',
      'variety': 'Black Pepper',
      'grade': 'Grade 1',
      'price': 3850.00,
      'quantity': 250,
      'notes': 'Good quality batch from this season',
      'submittedAt': '2026-01-27 14:30',
    },
    {
      'date': '2026-01-26',
      'district': 'Kandy',
      'variety': 'White Pepper',
      'grade': 'Grade 2',
      'price': 4200.00,
      'quantity': 180,
      'notes': 'Premium quality',
      'submittedAt': '2026-01-26 10:15',
    },
    {
      'date': '2026-01-25',
      'district': 'Galle',
      'variety': 'Black Pepper',
      'grade': 'Grade 1',
      'price': 3800.00,
      'quantity': 200,
      'notes': '',
      'submittedAt': '2026-01-25 16:45',
    },
    {
      'date': '2026-01-23',
      'district': 'Matara',
      'variety': 'Black Pepper',
      'grade': 'Grade 2',
      'price': 3450.00,
      'quantity': 320,
      'notes': 'Local market sale',
      'submittedAt': '2026-01-23 11:20',
    },
    {
      'date': '2026-01-22',
      'district': 'Kurunegala',
      'variety': 'White Pepper',
      'grade': 'Grade 1',
      'price': 4150.00,
      'quantity': 150,
      'notes': '',
      'submittedAt': '2026-01-22 09:30',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Past Price Reports'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.mediumSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(responsive),
            SizedBox(height: responsive.largeSpacing),
            _buildReportsList(responsive),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Responsive responsive) {
    final totalReports = pastReports.length;
    final avgPrice = pastReports.isEmpty
        ? 0.0
        : pastReports.map((r) => r['price'] as double).reduce((a, b) => a + b) /
              totalReports;
    final totalQuantity = pastReports
        .map((r) => r['quantity'] as int)
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
                      'My Submissions',
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize + 2,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your historical price submissions',
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
                child: _buildStatItem(
                  responsive,
                  'Total Reports',
                  '$totalReports',
                  Icons.list_alt_rounded,
                ),
              ),
              SizedBox(width: responsive.smallSpacing),
              Expanded(
                child: _buildStatItem(
                  responsive,
                  'Avg Price',
                  'LKR ${avgPrice.toStringAsFixed(0)}',
                  Icons.attach_money_rounded,
                ),
              ),
              SizedBox(width: responsive.smallSpacing),
              Expanded(
                child: _buildStatItem(
                  responsive,
                  'Total Qty',
                  '$totalQuantity kg',
                  Icons.scale_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    Responsive responsive,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.smallSpacing + 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2E7D32)),
          SizedBox(height: responsive.smallSpacing / 2),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.bodyFontSize + 1,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.smallFontSize - 1,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(Responsive responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Reports',
              style: TextStyle(
                fontSize: responsive.bodyFontSize + 2,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              '${pastReports.length} entries',
              style: TextStyle(
                fontSize: responsive.smallFontSize + 1,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.smallSpacing + 4),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pastReports.length,
          itemBuilder: (context, index) {
            return _buildReportCard(responsive, pastReports[index]);
          },
        ),
      ],
    );
  }

  Widget _buildReportCard(Responsive responsive, Map<String, dynamic> report) {
    final priceColor = _getPriceColor(report['price'] as double);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(report['date'] as String),
                      style: TextStyle(
                        fontSize: responsive.smallFontSize + 1,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                    'LKR ${(report['price'] as double).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: responsive.bodyFontSize,
                      fontWeight: FontWeight.w800,
                      color: priceColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.smallSpacing + 4),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['variety'] as String,
                        style: TextStyle(
                          fontSize: responsive.bodyFontSize + 2,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.smallSpacing,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              report['grade'] as String,
                              style: TextStyle(
                                fontSize: responsive.smallFontSize,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${report['quantity']} kg',
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
                            report['district'] as String,
                            style: TextStyle(
                              fontSize: responsive.smallFontSize,
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      if ((report['notes'] as String).isNotEmpty) ...[
                        SizedBox(height: responsive.smallSpacing),
                        Container(
                          padding: EdgeInsets.all(responsive.smallSpacing),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.note_rounded,
                                size: 14,
                                color: Colors.black45,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  report['notes'] as String,
                                  style: TextStyle(
                                    fontSize: responsive.smallFontSize,
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.smallSpacing),
            Divider(height: 1, color: Colors.grey.shade200),
            SizedBox(height: responsive.smallSpacing),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: Colors.black38,
                ),
                const SizedBox(width: 4),
                Text(
                  'Submitted: ${report['submittedAt']}',
                  style: TextStyle(
                    fontSize: responsive.smallFontSize - 1,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriceColor(double price) {
    if (price >= 4000) {
      return Colors.green.shade700;
    } else if (price >= 3500) {
      return Colors.green.shade600;
    } else if (price >= 3000) {
      return Colors.orange.shade700;
    } else {
      return Colors.red.shade700;
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
