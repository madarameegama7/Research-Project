import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../utils/responsive.dart';
import 'image_capture_guide_screen.dart';
import 'processing_screen.dart';
import 'processing_screen2.dart' show ProcessingScreen2;
import 'review_and_confirm_screen.dart';

class ImageUploadScreen2 extends StatefulWidget {
  const ImageUploadScreen2({super.key});

  @override
  State<ImageUploadScreen2> createState() => _ImageUploadScreen2State();
}

class _ImageUploadScreen2State extends State<ImageUploadScreen2>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  final Map<String, File?> images = {
    'bottom_full': null,
    'bottom_half': null,
    'bottom_close': null,
    'middle_full': null,
    'middle_half': null,
    'middle_close': null,
    'top_full': null,
    'top_half': null,
    'top_close': null,
  };

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

  Future<void> pickImage(String key) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text("Take a photo"),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text("Choose from gallery"),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );

  if (source == null) return;

  final result = await _picker.pickImage(
    source: source,
    imageQuality: 85,
  );

  if (result != null) {
    setState(() {
      images[key] = File(result.path);
    });
  }
}

  bool get allImagesUploaded => images.values.every((element) => element != null);

  int get uploadedImagesCount => images.values.where((element) => element != null).length;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    const primary = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Image Upload',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: responsive.padding(
                  mobile: const EdgeInsets.all(16),
                  tablet: const EdgeInsets.all(20),
                  desktop: const EdgeInsets.all(24),
                ),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step indicator
                    Row(
                      children: [
                        _buildStepIndicator(1, true, primary, responsive),
                        _buildStepLine(true, primary, responsive),
                        _buildStepIndicator(2, true, primary, responsive),
                        _buildStepLine(true, primary, responsive),
                        _buildStepIndicator(3, true, primary, responsive),
                      ],
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                    Text(
                      "Capture Pepper Images",
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                          mobile: 22,
                          tablet: 24,
                          desktop: 26,
                        ),
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    ResponsiveSpacing(mobile: 4, tablet: 6, desktop: 8),
                    Text(
                      "Take 9 images from different angles and layers",
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                    // Compact Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$uploadedImagesCount of 9 images',
                                    style: TextStyle(
                                      fontSize: responsive.bodyFontSize - 1,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    '${((uploadedImagesCount / 9) * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: responsive.bodyFontSize - 1,
                                      fontWeight: FontWeight.w600,
                                      color: allImagesUploaded
                                          ? Colors.green.shade700
                                          : primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: uploadedImagesCount / 9,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    allImagesUploaded
                                        ? Colors.green.shade500
                                        : primary,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

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
                      // Info Card with View More Instructions Button
                      Container(
                        padding: responsive.padding(
                          mobile: const EdgeInsets.all(20),
                          tablet: const EdgeInsets.all(24),
                          desktop: const EdgeInsets.all(28),
                        ),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(
                                    responsive.value(
                                      mobile: 10,
                                      tablet: 11,
                                      desktop: 12,
                                    ),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.blue.shade700,
                                    size: responsive.mediumIconSize,
                                  ),
                                ),
                                ResponsiveSpacing.horizontal(
                                  mobile: 12,
                                  tablet: 14,
                                  desktop: 16,
                                ),
                                Expanded(
                                  child: Text(
                                    'Image Capture Instructions',
                                    style: TextStyle(
                                      fontSize: responsive.titleFontSize,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                            Text(
                              '1. Place pepper on clean white A4 paper\n2. Ensure good natural lighting\n3. Capture 9 images (3 angles × 3 layers)\n4. Keep camera 20-30 cm above sample',
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                            ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ImageCaptureGuideScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.value(
                                    mobile: 12,
                                    tablet: 14,
                                    desktop: 16,
                                  ),
                                  vertical: responsive.value(
                                    mobile: 8,
                                    tablet: 9,
                                    desktop: 10,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.help_outline_rounded,
                                      color: Colors.blue.shade700,
                                      size: responsive.smallIconSize,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'View detailed instructions',
                                      style: TextStyle(
                                        fontSize: responsive.bodyFontSize - 1,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                      // Sample Sections
                      _buildSection(
                        responsive,
                        primary,
                        'Bottom Sample',
                        'bottom',
                        Icons.arrow_downward_rounded,
                        Colors.orange,
                      ),

                      ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                      _buildSection(
                        responsive,
                        primary,
                        'Middle Sample',
                        'middle',
                        Icons.remove_rounded,
                        Colors.blue,
                      ),

                      ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                      _buildSection(
                        responsive,
                        primary,
                        'Top Sample',
                        'top',
                        Icons.arrow_upward_rounded,
                        Colors.purple,
                      ),

                      ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                      // Submit Button - Always Enabled
                      Container(
                        width: double.infinity,
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProcessingScreen2(
                                  images: images,
                                ),
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
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: responsive.smallIconSize,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Continue",
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

                      ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      Responsive responsive,
      Color primary,
      String title,
      String keyPrefix,
      IconData icon,
      Color accentColor,
      ) {
    final sectionImages = {
      '${keyPrefix}_full': images['${keyPrefix}_full'],
      '${keyPrefix}_half': images['${keyPrefix}_half'],
      '${keyPrefix}_close': images['${keyPrefix}_close'],
    };

    final sectionComplete = sectionImages.values.every((img) => img != null);

    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(18),
        desktop: const EdgeInsets.all(20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: sectionComplete ? accentColor.withOpacity(0.3) : Colors.grey.shade200,
          width: sectionComplete ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  responsive.value(mobile: 8, tablet: 9, desktop: 10),
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
                ),
              ),
              ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (sectionComplete)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.value(mobile: 10, tablet: 11, desktop: 12),
                    vertical: responsive.value(mobile: 4, tablet: 5, desktop: 6),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green.shade700,
                        size: responsive.value(mobile: 14, tablet: 15, desktop: 16),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Complete',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: responsive.bodyFontSize - 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
          Row(
            children: [
              _buildImageTile(
                responsive,
                '${keyPrefix}_full',
                'Full View',
                Icons.crop_free_rounded,
                accentColor,
              ),
              ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
              _buildImageTile(
                responsive,
                '${keyPrefix}_half',
                'Half View',
                Icons.crop_square_rounded,
                accentColor,
              ),
              ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
              _buildImageTile(
                responsive,
                '${keyPrefix}_close',
                'Close-up',
                Icons.zoom_in_rounded,
                accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(
      Responsive responsive,
      String key,
      String label,
      IconData icon,
      Color accentColor,
      ) {
    final hasImage = images[key] != null;

    return Expanded(
      child: GestureDetector(
        onTap: () => pickImage(key),
        child: Container(
          height: responsive.value(mobile: 120, tablet: 140, desktop: 160),
          decoration: BoxDecoration(
            color: hasImage ? Colors.grey.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasImage ? accentColor.withOpacity(0.3) : Colors.grey.shade300,
              width: hasImage ? 2 : 1,
            ),
          ),
          child: hasImage
              ? Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  images[key]!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
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
                    size: responsive.value(mobile: 14, tablet: 15, desktop: 16),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.value(mobile: 6, tablet: 7, desktop: 8),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: responsive.bodyFontSize - 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(
                  responsive.value(mobile: 10, tablet: 11, desktop: 12),
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_a_photo_rounded,
                  color: accentColor,
                  size: responsive.value(mobile: 24, tablet: 26, desktop: 28),
                ),
              ),
              ResponsiveSpacing(mobile: 8, tablet: 10, desktop: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize - 2,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ResponsiveSpacing(mobile: 4, tablet: 5, desktop: 6),
              Icon(
                icon,
                color: Colors.grey.shade400,
                size: responsive.value(mobile: 16, tablet: 17, desktop: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive, Color primary, Responsive responsive) {
    final isCompleted = step < 3;

    return Container(
      width: responsive.value(mobile: 32, tablet: 36, desktop: 40),
      height: responsive.value(mobile: 32, tablet: 36, desktop: 40),
      decoration: BoxDecoration(
        color: isActive || isCompleted ? primary : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
          Icons.check,
          color: Colors.white,
          size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
        )
            : Text(
          '$step',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: responsive.bodyFontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive, Color primary, Responsive responsive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: EdgeInsets.symmetric(
          horizontal: responsive.value(mobile: 8, tablet: 10, desktop: 12),
        ),
        color: isActive ? primary : Colors.grey[300],
      ),
    );
  }
}