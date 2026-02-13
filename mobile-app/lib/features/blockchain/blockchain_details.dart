import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class BlockchainDetailsScreen extends StatefulWidget {
  final String qrData;

  const BlockchainDetailsScreen({super.key, required this.qrData});

  @override
  State<BlockchainDetailsScreen> createState() =>
      _BlockchainDetailsScreenState();
}

class _BlockchainDetailsScreenState extends State<BlockchainDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final primary = const Color(0xFF2E7D32);

    // Sample data
    final Map<String, dynamic> blockchainData = {
      'batchId': widget.qrData,
      'origin': 'Sri Lanka',
      'originDate': '20 Dec 2025',
      'destination': 'Singapore',
      'destinationDate': '10 Jan 2026',
      'status': 'In Transit',
      'farmerName': 'P. Silva & Co.',
      'quality': 'Premium Grade A',
      'weight': '25 kg',
      'temperature': '4-8°C',
      'humidity': '65-75%',
      'farmerPrice': 'LKR 1,850',
      'exporterPrice': 'LKR 2,350',
      'totalValue': 'LKR 58,750',
      'certifications': ['Organic', 'Fair Trade'],
      'transactions': [
        {'date': '20 Dec', 'event': 'Harvested', 'location': 'Farm, Kegalle'},
        {
          'date': '20 Dec',
          'event': 'Processed',
          'location': 'Processing Unit, Galle',
        },
        {
          'date': '21 Dec',
          'event': 'Packaged',
          'location': 'Warehouse, Colombo',
        },
        {'date': '22 Dec', 'event': 'Shipped', 'location': 'Port of Colombo'},
        {'date': '28 Dec', 'event': 'In Transit', 'location': 'Ocean Route'},
      ],
    };

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Batch Details'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(responsive.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Status Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.largeSpacing),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, primary.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: responsive.mediumSpacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: TextStyle(
                                fontSize: responsive.fontSize(
                                  mobile: 12,
                                  tablet: 13,
                                  desktop: 14,
                                ),
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: responsive.smallSpacing),
                            Text(
                              blockchainData['status'] as String,
                              style: TextStyle(
                                fontSize: responsive.titleFontSize,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.greenAccent[400],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: responsive.fontSize(
                                  mobile: 11,
                                  tablet: 12,
                                  desktop: 13,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.largeSpacing),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.mediumSpacing,
                      vertical: responsive.smallSpacing,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Text(
                      'Batch ID: ${blockchainData['batchId']}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                          mobile: 11,
                          tablet: 12,
                          desktop: 13,
                        ),
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: responsive.largeSpacing + responsive.mediumSpacing,
            ),

            // Route Section
            _buildSectionTitle(responsive, 'Route', Icons.map_rounded),
            SizedBox(height: responsive.mediumSpacing),
            Row(
              children: [
                Expanded(
                  child: _buildRouteBox(
                    responsive,
                    Icons.location_on_rounded,
                    'From',
                    blockchainData['origin'] as String,
                    blockchainData['originDate'] as String,
                    primary,
                  ),
                ),
                SizedBox(width: responsive.mediumSpacing),
                Expanded(
                  child: _buildRouteBox(
                    responsive,
                    Icons.location_on_rounded,
                    'To',
                    blockchainData['destination'] as String,
                    blockchainData['destinationDate'] as String,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            SizedBox(
              height: responsive.largeSpacing + responsive.mediumSpacing,
            ),

            // Product Info Section
            _buildSectionTitle(
              responsive,
              'Batch Information',
              Icons.info_rounded,
            ),
            SizedBox(height: responsive.mediumSpacing),
            _buildSimpleDetailCard(responsive, [
              ('Producer', blockchainData['farmerName'] as String),
              ('Quality', blockchainData['quality'] as String),
              ('Weight', blockchainData['weight'] as String),
            ]),

            SizedBox(
              height: responsive.largeSpacing + responsive.mediumSpacing,
            ),

            // Storage Conditions
            _buildSectionTitle(
              responsive,
              'Storage Conditions',
              Icons.thermostat_rounded,
            ),
            SizedBox(height: responsive.mediumSpacing),
            Row(
              children: [
                Expanded(
                  child: _buildConditionBox(
                    responsive,
                    Icons.thermostat_rounded,
                    'Temperature',
                    blockchainData['temperature'] as String,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: responsive.mediumSpacing),
                Expanded(
                  child: _buildConditionBox(
                    responsive,
                    Icons.water_drop_rounded,
                    'Humidity',
                    blockchainData['humidity'] as String,
                    Colors.cyan,
                  ),
                ),
              ],
            ),

            SizedBox(
              height: responsive.largeSpacing + responsive.mediumSpacing,
            ),

            // Price Details
            _buildSectionTitle(
              responsive,
              'Price Details',
              Icons.payments_rounded,
            ),
            SizedBox(height: responsive.mediumSpacing),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.mediumSpacing),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[200]!, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceRow(
                    responsive,
                    'Farmer Price (per kg)',
                    blockchainData['farmerPrice'] as String,
                    Colors.green,
                  ),
                  Divider(height: responsive.mediumSpacing * 1.5),
                  _buildPriceRow(
                    responsive,
                    'Exporter Price (per kg)',
                    blockchainData['exporterPrice'] as String,
                    Colors.orange,
                  ),
                  Divider(height: responsive.mediumSpacing * 1.5),
                  _buildPriceRow(
                    responsive,
                    'Total Batch Value',
                    blockchainData['totalValue'] as String,
                    Colors.amber[800]!,
                  ),
                ],
              ),
            ),

            SizedBox(
              height: responsive.largeSpacing + responsive.mediumSpacing,
            ),

            // Certifications
            _buildSectionTitle(
              responsive,
              'Certifications',
              Icons.verified_rounded,
            ),
            SizedBox(height: responsive.mediumSpacing),
            Wrap(
              spacing: responsive.mediumSpacing,
              runSpacing: responsive.mediumSpacing,
              children: [
                for (String cert in blockchainData['certifications'] as List)
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.smallSpacing,
                      horizontal: responsive.mediumSpacing,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      border: Border.all(
                        color: primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: primary,
                          size: 18,
                        ),
                        SizedBox(width: responsive.smallSpacing),
                        Text(
                          cert,
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                            fontSize: responsive.fontSize(
                              mobile: 12,
                              tablet: 13,
                              desktop: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            SizedBox(
              height: responsive.largeSpacing + responsive.mediumSpacing,
            ),

            // Journey Timeline
            _buildSectionTitle(
              responsive,
              'Batch Journey',
              Icons.timeline_rounded,
            ),
            SizedBox(height: responsive.mediumSpacing),
            _buildTimeline(
              responsive,
              blockchainData['transactions'] as List,
              primary,
            ),

            SizedBox(
              height: responsive.largeSpacing + responsive.mediumSpacing,
            ),

            // Download PDF Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFFF6B6B), const Color(0xFFEE5A52)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PDF download feature coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.mediumSpacing + 4,
                      horizontal: responsive.largeSpacing,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.description_rounded,
                            color: Colors.white,
                            size: responsive.mediumIconSize + 2,
                          ),
                        ),
                        SizedBox(width: responsive.mediumSpacing + 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Download Report',
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize + 1,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Export batch details as PDF',
                              style: TextStyle(
                                fontSize: responsive.fontSize(
                                  mobile: 11,
                                  tablet: 12,
                                  desktop: 13,
                                ),
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: responsive.mediumIconSize,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(
              height: responsive.largeSpacing + responsive.mediumSpacing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    Responsive responsive,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: responsive.value(mobile: 4, tablet: 5, desktop: 6),
          height: responsive.value(mobile: 24, tablet: 26, desktop: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: responsive.mediumSpacing),
        Icon(
          icon,
          color: const Color(0xFF2E7D32),
          size: responsive.mediumIconSize,
        ),
        SizedBox(width: responsive.smallSpacing),
        Text(
          title,
          style: TextStyle(
            fontSize: responsive.headingFontSize,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteBox(
    Responsive responsive,
    IconData icon,
    String label,
    String value,
    String date,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: responsive.smallSpacing),
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.fontSize(
                    mobile: 11,
                    tablet: 12,
                    desktop: 13,
                  ),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.smallSpacing),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: responsive.smallSpacing),
          Text(
            date,
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 10,
                tablet: 11,
                desktop: 12,
              ),
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleDetailCard(
    Responsive responsive,
    List<(String, String)> details,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < details.length; i++) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  details[i].$1,
                  style: TextStyle(
                    fontSize: responsive.fontSize(
                      mobile: 13,
                      tablet: 14,
                      desktop: 15,
                    ),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  details[i].$2,
                  style: TextStyle(
                    fontSize: responsive.fontSize(
                      mobile: 13,
                      tablet: 14,
                      desktop: 15,
                    ),
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (i < details.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: responsive.smallSpacing,
                ),
                child: Divider(color: Colors.grey[200], height: 1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionBox(
    Responsive responsive,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: responsive.smallSpacing),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 11,
                tablet: 12,
                desktop: 13,
              ),
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: responsive.smallSpacing),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.titleFontSize,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    Responsive responsive,
    List transactions,
    Color primary,
  ) {
    return Column(
      children: [
        for (int i = 0; i < transactions.length; i++)
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      if (i < transactions.length - 1)
                        Container(
                          width: 2,
                          height: 60,
                          color: primary.withOpacity(0.3),
                          margin: const EdgeInsets.only(top: 4),
                        ),
                    ],
                  ),
                  SizedBox(width: responsive.mediumSpacing),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(responsive.mediumSpacing),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      margin: EdgeInsets.only(top: responsive.smallSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transactions[i]['event'],
                            style: TextStyle(
                              fontSize: responsive.bodyFontSize,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: responsive.smallSpacing),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  transactions[i]['location'],
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(
                                      mobile: 12,
                                      tablet: 13,
                                      desktop: 14,
                                    ),
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            transactions[i]['date'],
                            style: TextStyle(
                              fontSize: responsive.fontSize(
                                mobile: 11,
                                tablet: 12,
                                desktop: 13,
                              ),
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPriceRow(
    Responsive responsive,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.bodyFontSize,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
