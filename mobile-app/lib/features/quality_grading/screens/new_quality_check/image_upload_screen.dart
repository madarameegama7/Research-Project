import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/language_prefs.dart';
import '../../../../utils/quality_grading/image_upload_screen_si.dart';
import '../../services/quality_check_api.dart';
import '../image_capture_guide_screen.dart';
import 'review_and_confirm_screen.dart';
import 'review_and_confirm_screen.dart' show ImageStore;

class ImageUploadScreen extends StatefulWidget {
  final String qualityCheckId;
  final String batchId;

  const ImageUploadScreen({
    super.key,
    required this.qualityCheckId,
    required this.batchId,
  });

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  String _currentLanguage = 'en';

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

  String? _uploadingKey;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get _isSinhala => _currentLanguage == 'si';
  String _t(String english, String sinhala) => _isSinhala ? sinhala : english;

  @override
  void initState() {
    super.initState();

    final stored = ImageStore.instance.images;
    stored.forEach((key, file) {
      if (images.containsKey(key)) images[key] = file;
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();

    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) setState(() => _currentLanguage = lang);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> pickImage(String key) async {
    final source = await _showImageSourceSheet();
    if (source == null) return;

    final result = await _picker.pickImage(source: source, imageQuality: 85);
    if (result == null) return;

    final stableFile = await _savePickedImage(result, key);
    setState(() => _uploadingKey = key);

    // validate before saving
    try {
      final api = QualityCheckApi();
      await api.validateImage(image: stableFile);

      if (!mounted) return;
      setState(() {
        images[key] = stableFile;
        _uploadingKey = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingKey = null);

      // Remove the copied file if validation failed to avoid stale files.
      if (await stableFile.exists()) {
        await stableFile.delete().catchError((_) {});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Please ensure the photo clearly shows the pepper sample.',
              'කරුණාකර ඡායාරූපයේ ගම්මිරිස් සාම්පලය පැහැදිලිව පෙනෙන බව තහවුරු කරන්න.',
            ),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<File> _savePickedImage(XFile pickedFile, String key) async {
    final bytes = await pickedFile.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final filename = pickedFile.name.isNotEmpty
        ? pickedFile.name
        : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final stablePath = '${dir.path}/quality_grading_${key}_$filename';
    final stableFile = File(stablePath);
    await stableFile.writeAsBytes(bytes, flush: true);
    return stableFile;
  }

  Future<ImageSource?> _showImageSourceSheet() async {
    final responsive = context.responsive;
    const primary = Color(0xFF2E7D32);

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: EdgeInsets.symmetric(
          horizontal: responsive.pagePadding,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _t(
                  'Select Image Source',
                  ImageUploadScreenSi.selectImageSource,
                ),
                style: TextStyle(
                  fontSize: responsive.titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.camera_alt_rounded,
                      label: _t('Camera', ImageUploadScreenSi.camera),
                      color: primary,
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.photo_library_rounded,
                      label: _t('Gallery', ImageUploadScreenSi.gallery),
                      color: Colors.blue.shade600,
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Computed state ─────────────────────────────────────────────────────────

  bool get allImagesUploaded => images.values.every((e) => e != null);
  int get uploadedImagesCount => images.values.where((e) => e != null).length;
  int get remainingCount => 9 - uploadedImagesCount;

  // ── Build ──────────────────────────────────────────────────────────────────

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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Image Upload', ImageUploadScreenSi.imageUpload),
          style: const TextStyle(
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
              // ── Header ─────────────────────────────────────────────────────
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
                    Row(
                      children: [
                        _buildStepIndicator(1, true, primary, responsive),
                        _buildStepLine(true, primary, responsive),
                        _buildStepIndicator(2, true, primary, responsive),
                        _buildStepLine(true, primary, responsive),
                        _buildStepIndicator(3, true, primary, responsive),
                        _buildStepLine(true, primary, responsive),
                        _buildStepIndicator(4, true, primary, responsive),
                      ],
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                    Text(
                      _t(
                        'Capture Pepper Images',
                        ImageUploadScreenSi.capturePepperImages,
                      ),
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
                      _t(
                        'Take or select 9 images from different angles and layers',
                        ImageUploadScreenSi.headerSubtitle,
                      ),
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize,
                        color: Colors.grey[600],
                      ),
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isSinhala
                                  ? 'රූප $uploadedImagesCount / 9 ${ImageUploadScreenSi.imagesUploaded}'
                                  : '$uploadedImagesCount of 9 images uploaded',
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
                  ],
                ),
              ),

              ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

              // ── Content ────────────────────────────────────────────────────
              SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.pagePadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instructions card
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
                                    _t(
                                      'Image Capture Instructions',
                                      ImageUploadScreenSi
                                          .imageCaptureInstructions,
                                    ),
                                    style: TextStyle(
                                      fontSize: responsive.titleFontSize,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            ResponsiveSpacing(
                              mobile: 16,
                              tablet: 18,
                              desktop: 20,
                            ),
                            Text(
                              _t(
                                '1. Place pepper on clean white A4 paper\n2. Ensure good natural lighting\n3. Capture 9 images (3 angles × 3 layers)\n4. Keep camera 20–30 cm above sample\n5. Use Camera to take a fresh photo or Gallery to pick an existing one',
                                ImageUploadScreenSi.instructions,
                              ),
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                            ResponsiveSpacing(
                              mobile: 12,
                              tablet: 14,
                              desktop: 16,
                            ),
                            InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ImageCaptureGuideScreen(),
                                ),
                              ),
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
                                      _t(
                                        'View detailed instructions',
                                        ImageUploadScreenSi
                                            .viewDetailedInstructions,
                                      ),
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

                      // Sample sections
                      _buildSection(
                        responsive,
                        primary,
                        _t('Bottom Sample', ImageUploadScreenSi.bottomSample),
                        'bottom',
                        Icons.arrow_downward_rounded,
                        Colors.orange,
                      ),
                      ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),
                      _buildSection(
                        responsive,
                        primary,
                        _t('Middle Sample', ImageUploadScreenSi.middleSample),
                        'middle',
                        Icons.remove_rounded,
                        Colors.blue,
                      ),
                      ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),
                      _buildSection(
                        responsive,
                        primary,
                        _t('Top Sample', ImageUploadScreenSi.topSample),
                        'top',
                        Icons.arrow_upward_rounded,
                        Colors.purple,
                      ),

                      ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                      // ── Validation banner ─────────────────────────────────
                      if (!allImagesUploaded)
                        Container(
                          width: double.infinity,
                          padding: responsive.padding(
                            mobile: const EdgeInsets.all(16),
                            tablet: const EdgeInsets.all(18),
                            desktop: const EdgeInsets.all(20),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade800,
                                size: responsive.mediumIconSize,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isSinhala
                                          ? '$remainingCount ${remainingCount == 1 ? ImageUploadScreenSi.imageSingularRemaining : ImageUploadScreenSi.imagesRemaining}'
                                          : '$remainingCount image${remainingCount == 1 ? '' : 's'} remaining',
                                      style: TextStyle(
                                        fontSize: responsive.bodyFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _t(
                                        'All 9 images must be uploaded before you can continue to the next step.',
                                        ImageUploadScreenSi.allImagesRequired,
                                      ),
                                      style: TextStyle(
                                        fontSize: responsive.bodyFontSize - 1,
                                        color: Colors.amber.shade800,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (!allImagesUploaded)
                        ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                      // ── Continue button ───────────────────────────────────
                      Container(
                        width: double.infinity,
                        height: responsive.value(
                          mobile: 60,
                          tablet: 64,
                          desktop: 68,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            if (allImagesUploaded)
                              BoxShadow(
                                color: primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: allImagesUploaded
                              ? () {
                                  ImageStore.instance.images = Map.from(images);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SummaryConfirmationScreen(
                                        images: images,
                                        qualityCheckId: widget.qualityCheckId,
                                        batchId: widget.batchId,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade500,
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

                              // IMPORTANT: let text wrap/shrink inside the Row
                              Flexible(
                                child: Text(
                                  allImagesUploaded
                                      ? _t(
                                          'Continue',
                                          ImageUploadScreenSi.continueText,
                                        )
                                      : _t(
                                          'Upload all images to continue',
                                          ImageUploadScreenSi
                                              .uploadAllToContinue,
                                        ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: responsive.titleFontSize,
                                    height: 1.1,
                                  ),
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

  // ── Section builder ────────────────────────────────────────────────────────

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
          color: sectionComplete
              ? accentColor.withOpacity(0.3)
              : Colors.grey.shade200,
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
                    horizontal: responsive.value(
                      mobile: 10,
                      tablet: 11,
                      desktop: 12,
                    ),
                    vertical: responsive.value(
                      mobile: 4,
                      tablet: 5,
                      desktop: 6,
                    ),
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
                        size: responsive.value(
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _t('Complete', ImageUploadScreenSi.complete),
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
                _t('Full View', ImageUploadScreenSi.fullView),
                Icons.crop_free_rounded,
                accentColor,
              ),
              ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
              _buildImageTile(
                responsive,
                '${keyPrefix}_half',
                _t('Half View', ImageUploadScreenSi.halfView),
                Icons.crop_square_rounded,
                accentColor,
              ),
              ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
              _buildImageTile(
                responsive,
                '${keyPrefix}_close',
                _t('Close-up', ImageUploadScreenSi.closeUp),
                Icons.zoom_in_rounded,
                accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Image tile ─────────────────────────────────────────────────────────────

  Widget _buildImageTile(
    Responsive responsive,
    String key,
    String label,
    IconData icon,
    Color accentColor,
  ) {
    final hasImage = images[key] != null;
    final isUploading = _uploadingKey == key;

    return Expanded(
      child: GestureDetector(
        onTap: isUploading ? null : () => pickImage(key),
        child: Container(
          height: responsive.value(mobile: 120, tablet: 140, desktop: 160),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasImage
                  ? accentColor.withOpacity(0.3)
                  : Colors.grey.shade300,
              width: hasImage ? 2 : 1,
            ),
          ),
          child: isUploading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: responsive.value(mobile: 24, tablet: 26, desktop: 28),
                      width: responsive.value(mobile: 24, tablet: 26, desktop: 28),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: accentColor,
                      ),
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                    Text(
                      _t('Validating...', 'තහවුරු කරමින්...'),
                      style: TextStyle(
                        fontSize: responsive.bodyFontSize - 2,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : hasImage
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
                              size: responsive.value(
                                mobile: 14,
                                tablet: 15,
                                desktop: 16,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: responsive.value(
                                mobile: 6,
                                tablet: 7,
                                desktop: 8,
                              ),
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
                        size: responsive.value(
                          mobile: 24,
                          tablet: 26,
                          desktop: 28,
                        ),
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
                      size: responsive.value(
                        mobile: 16,
                        tablet: 17,
                        desktop: 18,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Step indicators ────────────────────────────────────────────────────────

  Widget _buildStepIndicator(
    int step,
    bool isActive,
    Color primary,
    Responsive responsive,
  ) {
    final isCompleted = step < 4;
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

// ── Source tile widget ─────────────────────────────────────────────────────

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
