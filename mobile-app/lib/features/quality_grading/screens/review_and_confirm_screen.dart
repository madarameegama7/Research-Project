import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import 'processing_screen.dart';

class SummaryConfirmationScreen extends StatefulWidget {
  final Map<String, File?> images;

  const SummaryConfirmationScreen({
    super.key,
    required this.images,
  });

  @override
  State<SummaryConfirmationScreen> createState() => _SummaryConfirmationScreenState();
}

class _SummaryConfirmationScreenState extends State<SummaryConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    const primary = Color(0xFF2E7D32);

    return WillPopScope(
      onWillPop: () async {
        return false;
      },

      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: primary,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Center(
            child: const Text(
              'Review & Confirm',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
      
                // Content
                SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.pagePadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Batch Information Section
                        _buildSectionHeader(
                          responsive,
                          primary,
                          'Batch Information',
                          Icons.info_rounded,
                        ),
      
                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
      
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                responsive,
                                'Pepper Type',
                                'Black Pepper',
                                Icons.grass_rounded,
                              ),
                              _buildDivider(responsive),
                              _buildInfoRow(
                                responsive,
                                'Pepper Variety',
                                'Ceylon Pepper',
                                Icons.local_florist_rounded,
                              ),
                              _buildDivider(responsive),
                              _buildInfoRow(
                                responsive,
                                'Drying Method',
                                'Sun Dried',
                                Icons.wb_sunny_rounded,
                              ),
                              _buildDivider(responsive),
                              _buildInfoRow(
                                responsive,
                                'Batch Weight',
                                '25 kg',
                                Icons.scale_rounded,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
      
                        ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
      
                        // Bulk Density Section
                        _buildSectionHeader(
                          responsive,
                          primary,
                          'Bulk Density',
                          Icons.science_rounded,
                        ),

                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                responsive,
                                'Measured Density',
                                '540 g/L',
                                Icons.analytics_rounded,
                              ),
                              _buildDivider(responsive),
                              _buildInfoRow(
                                responsive,
                                'Status',
                                'Verified',
                                Icons.check_circle_rounded,
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
      
                        ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
      
                        // Certificates Section
                        _buildSectionHeader(
                          responsive,
                          primary,
                          'Certificates',
                          Icons.verified_rounded,
                        ),
      
                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
      
                        Wrap(
                          spacing: responsive.value(mobile: 8, tablet: 10, desktop: 12),
                          runSpacing: responsive.value(mobile: 8, tablet: 10, desktop: 12),
                          children: [
                            _buildCertificateChip(responsive, 'GAP', Colors.blue),
                            _buildCertificateChip(
                              responsive,
                              'Quality Certificate',
                              Colors.purple,
                            ),
                          ],
                        ),
      
                        ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
      
                        // Captured Images Section
                        _buildSectionHeader(
                          responsive,
                          primary,
                          'Captured Images',
                          Icons.photo_library_rounded,
                        ),
      
                        ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
      
                        Container(
                          padding: responsive.padding(
                            mobile: const EdgeInsets.all(12),
                            tablet: const EdgeInsets.all(14),
                            desktop: const EdgeInsets.all(16),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.green.shade600,
                                    size: responsive.smallIconSize,
                                  ),
                                  ResponsiveSpacing.horizontal(
                                    mobile: 8,
                                    tablet: 10,
                                    desktop: 12,
                                  ),
                                  Text(
                                    '${widget.images.values.whereType<File>().length} images captured',
                                    style: TextStyle(
                                      fontSize: responsive.bodyFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                              _buildImageGrid(responsive),
                            ],
                          ),
                        ),
      
                        ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
      
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: responsive.buttonHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.edit_rounded,
                                        size: responsive.smallIconSize,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Back to Edit",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: responsive.titleFontSize,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ResponsiveSpacing.horizontal(
                              mobile: 12,
                              tablet: 14,
                              desktop: 16,
                            ),
                            Expanded(
                              child: Container(
                                height: responsive.buttonHeight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ProcessingScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Confirm",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: responsive.titleFontSize,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: responsive.smallIconSize,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
      
                        ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      Responsive responsive,
      Color primary,
      String title,
      IconData icon,
      ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(
            responsive.value(mobile: 8, tablet: 9, desktop: 10),
          ),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primary,
            size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: responsive.headingFontSize - 2,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      Responsive responsive,
      String label,
      String value,
      IconData icon, {
        bool isLast = false,
      }) {
    return Padding(
      padding: responsive.padding(
        mobile: EdgeInsets.fromLTRB(16, 14, 16, isLast ? 14 : 0),
        tablet: EdgeInsets.fromLTRB(18, 16, 18, isLast ? 16 : 0),
        desktop: EdgeInsets.fromLTRB(20, 18, 20, isLast ? 18 : 0),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: responsive.smallIconSize,
            color: Colors.grey[600],
          ),
          ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.bodyFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Responsive responsive) {
    return Divider(
      height: 1,
      indent: responsive.value(mobile: 16, tablet: 18, desktop: 20),
      endIndent: responsive.value(mobile: 16, tablet: 18, desktop: 20),
    );
  }

  Widget _buildCertificateChip(
      Responsive responsive,
      String text,
      Color color,
      ) {
    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        desktop: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            color: color,
            size: responsive.value(mobile: 16, tablet: 17, desktop: 18),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: responsive.bodyFontSize - 1,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(Responsive responsive) {
    final imageFiles = widget.images.values.whereType<File>().toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsive.isMobile ? 3 : 4,
        crossAxisSpacing: responsive.value(mobile: 8, tablet: 10, desktop: 12),
        mainAxisSpacing: responsive.value(mobile: 8, tablet: 10, desktop: 12),
      ),
      itemCount: imageFiles.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFiles[index],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.shade500,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: responsive.value(mobile: 12, tablet: 13, desktop: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}