import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import 'QR_scan.dart';

class BlockchainDashboard extends StatefulWidget {
  const BlockchainDashboard({super.key});

  @override
  State<BlockchainDashboard> createState() => _BlockchainDashboardState();
}

class _BlockchainDashboardState extends State<BlockchainDashboard> {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final primary = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Traceability'),
        backgroundColor: primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(responsive.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(responsive.largeSpacing),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.qr_code_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        SizedBox(width: responsive.mediumSpacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Track Your Batch',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: responsive.titleFontSize,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: responsive.smallSpacing),
                              Text(
                                'Verify authenticity & trace origin',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: responsive.bodyFontSize,
                                  fontWeight: FontWeight.w500,
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
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: Colors.amber[300],
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Blockchain Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
              ),

              SizedBox(
                height: responsive.largeSpacing + responsive.mediumSpacing,
              ),

              // Benefits Section
              _buildBenefitsSection(responsive),

              SizedBox(height: responsive.largeSpacing),

              // Info Section
              Text(
                'How It Works',
                style: TextStyle(
                  fontSize: responsive.headingFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: responsive.smallSpacing),
              Text(
                'Follow these simple steps to trace your pepper batch',
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(height: responsive.largeSpacing),

              _buildEnhancedInfoCard(
                responsive,
                '1',
                'Locate QR Code',
                'Find the unique QR code on your pepper package label',
                Icons.qr_code_rounded,
                Colors.blue,
              ),
              SizedBox(height: responsive.mediumSpacing),
              _buildEnhancedInfoCard(
                responsive,
                '2',
                'Start Scanning',
                'Click Start button and point camera at the QR code',
                Icons.camera_alt_rounded,
                Colors.purple,
              ),
              SizedBox(height: responsive.mediumSpacing),
              _buildEnhancedInfoCard(
                responsive,
                '3',
                'View Full Details',
                'See complete batch information, origin, and handling details',
                Icons.info_outline_rounded,
                Colors.orange,
              ),
              SizedBox(height: responsive.mediumSpacing),
              _buildEnhancedInfoCard(
                responsive,
                '4',
                'Verify Origin',
                'Confirm the pepper is authentic and from registered exporters',
                Icons.verified_rounded,
                Colors.green,
              ),
              SizedBox(height: responsive.mediumSpacing),
              _buildEnhancedInfoCard(
                responsive,
                '5',
                'Check History',
                'View complete blockchain record of the batch journey',
                Icons.history_rounded,
                Colors.teal,
              ),

              SizedBox(
                height: responsive.largeSpacing + responsive.mediumSpacing,
              ),

              // Start Button
              Center(
                child: SizedBox(
                  width: responsive.value(
                    mobile: MediaQuery.of(context).size.width * 0.75,
                    tablet: MediaQuery.of(context).size.width * 0.5,
                    desktop: 400,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.value(
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                        horizontal: 24,
                      ),
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      elevation: 8,
                      shadowColor: primary.withOpacity(0.4),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QRScanScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Scan Batch Now',
                          style: TextStyle(
                            fontSize: responsive.bodyFontSize,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(Responsive responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Why Track with Us?',
          style: TextStyle(
            fontSize: responsive.headingFontSize,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: responsive.mediumSpacing),
        Row(
          children: [
            Expanded(
              child: _buildBenefitCard(
                responsive,
                Icons.security_rounded,
                'Secure',
                'Blockchain\nVerified',
                Colors.blue.shade50,
                Colors.blue.shade600,
              ),
            ),
            SizedBox(width: responsive.mediumSpacing),
            Expanded(
              child: _buildBenefitCard(
                responsive,
                Icons.speed_rounded,
                'Fast',
                'Instant\nVerification',
                Colors.green.shade50,
                Colors.green.shade600,
              ),
            ),
            SizedBox(width: responsive.mediumSpacing),
            Expanded(
              child: _buildBenefitCard(
                responsive,
                Icons.layers_rounded,
                'Transparent',
                'Complete\nHistory',
                Colors.orange.shade50,
                Colors.orange.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBenefitCard(
    Responsive responsive,
    IconData icon,
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(height: responsive.smallSpacing),
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 12,
                tablet: 13,
                desktop: 14,
              ),
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 10,
                tablet: 11,
                desktop: 12,
              ),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInfoCard(
    Responsive responsive,
    String number,
    String title,
    String description,
    IconData icon,
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
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [Icon(icon, color: color, size: 28)],
            ),
          ),
          SizedBox(width: responsive.mediumSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Step $number: ',
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                          mobile: 11,
                          tablet: 12,
                          desktop: 13,
                        ),
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: responsive.fontSize(
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.smallSpacing),
          Icon(Icons.arrow_forward_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}
