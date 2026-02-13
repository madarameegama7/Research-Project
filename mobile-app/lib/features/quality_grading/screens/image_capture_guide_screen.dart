import 'package:flutter/material.dart';

// Main selection page - choose instruction type
class ImageCaptureGuideScreen extends StatelessWidget {
  const ImageCaptureGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Image Capture Guide",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                "Choose Your Learning Style",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Text + Images Option
              Expanded(
                child: _InstructionCard(
                  icon: Icons.menu_book_rounded,
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  title: "Step-by-Step Guide",
                  subtitle: "Written instructions with detailed images",
                  features: const [
                    "Clear step-by-step process",
                    "Detailed images for each step",
                    "Easy to follow at your own pace",
                    "Best for careful preparation",
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TextInstructionsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Video Option
              Expanded(
                child: _InstructionCard(
                  icon: Icons.play_circle_filled_rounded,
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  title: "Video Tutorial",
                  subtitle: "Watch and learn visually",
                  features: const [
                    "Complete demonstration",
                    "Real-time capture walkthrough",
                    "Pause and replay anytime",
                    "See it in action",
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VideoInstructionsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Instruction card widget
class _InstructionCard extends StatelessWidget {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final List<String> features;
  final VoidCallback onTap;

  const _InstructionCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 16),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Start Learning",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Text + Images Instructions Screen
class TextInstructionsScreen extends StatefulWidget {
  const TextInstructionsScreen({super.key});

  @override
  State<TextInstructionsScreen> createState() => _TextInstructionsScreenState();
}

class _TextInstructionsScreenState extends State<TextInstructionsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Prepare Your Sample',
      'description': 'Take samples from three different positions of the gunny bag: top, middle, and bottom.',
      'icon': Icons.inventory_2_rounded,
      'color': Colors.blue,
      'details': [
        'Open your gunny bag of pepper carefully',
        'Take a handful from the TOP layer',
        'Take a handful from the MIDDLE section',
        'Take a handful from the BOTTOM of the bag',
        'Mix these three samples together thoroughly',
      ],
      'tips': 'This ensures your sample represents the entire batch, not just one section.',
    },
    {
      'title': 'Prepare A4 Paper & Background',
      'description': 'Use a clean white A4 paper on a flat, well-lit surface.',
      'icon': Icons.description_rounded,
      'color': Colors.green,
      'details': [
        'Place a clean, white A4 paper on a flat table',
        'Ensure good natural lighting (near window) or use bright LED light',
        'Avoid direct sunlight or harsh shadows',
        'Make sure the surface is stable and level',
      ],
      'tips': 'White background helps the AI accurately detect pepper color and defects.',
    },
    {
      'title': 'Sample 1 - Full A4 Image',
      'description': 'Spread pepper evenly on the FULL A4 paper and take a photo.',
      'icon': Icons.crop_square_rounded,
      'color': Colors.purple,
      'details': [
        'Spread pepper from your first sample evenly',
        'Cover the ENTIRE A4 paper',
        'Keep berries in a single layer (no overlapping)',
        'Hold phone 25-30 cm above the paper',
        'Ensure the whole A4 fits in frame',
        'Take the photo straight down (perpendicular)',
      ],
      'tips': 'This full spread helps detect overall color uniformity and large defects.',
    },
    {
      'title': 'Sample 1 - Half A4 Image',
      'description': 'Move pepper to HALF of the A4 paper and take a photo.',
      'icon': Icons.view_column_rounded,
      'color': Colors.orange,
      'details': [
        'Gather pepper to cover only HALF the A4 (left or right side)',
        'Keep density even and single layer',
        'Hold phone at same distance (25-30 cm)',
        'Frame the half A4 area clearly',
        'Take the photo',
      ],
      'tips': 'Half spread gives better visibility of individual berries for size analysis.',
    },
    {
      'title': 'Sample 1 - Close-Up Image',
      'description': 'Take a close-up photo showing pepper details clearly.',
      'icon': Icons.zoom_in_rounded,
      'color': Colors.red,
      'details': [
        'Move phone closer (10-15 cm from paper)',
        'Focus on a small cluster of berries',
        'Tap screen to ensure sharp focus',
        'Capture texture, wrinkles, and surface details',
        'Make sure image is not blurry',
      ],
      'tips': 'Close-ups help detect mold, insect damage, and surface texture quality.',
    },
    {
      'title': 'Repeat for Sample 2',
      'description': 'Take the SECOND sample and capture 3 images (full, half, close-up).',
      'icon': Icons.repeat_rounded,
      'color': Colors.cyan,
      'details': [
        'Clear the A4 paper',
        'Take pepper from your second mixed sample',
        'Repeat: Full A4 photo',
        'Repeat: Half A4 photo',
        'Repeat: Close-up photo',
      ],
      'tips': 'Multiple samples ensure accurate representation of your entire batch.',
    },
    {
      'title': 'Repeat for Sample 3',
      'description': 'Take the THIRD sample and capture 3 images (full, half, close-up).',
      'icon': Icons.looks_3_rounded,
      'color': Colors.indigo,
      'details': [
        'Clear the A4 paper again',
        'Take pepper from your third mixed sample',
        'Repeat: Full A4 photo',
        'Repeat: Half A4 photo',
        'Repeat: Close-up photo',
      ],
      'tips': 'You should now have 9 total images ready for upload!',
    },
    {
      'title': 'Review & Upload',
      'description': 'Check all 9 images meet quality standards before uploading.',
      'icon': Icons.check_circle_rounded,
      'color': Colors.teal,
      'details': [
        'Verify you have exactly 9 images',
        'Check all images are clear and not blurry',
        'Ensure good lighting in all photos',
        'Confirm white A4 background is visible',
        'Tap "Upload Images" in the app',
        'Wait for AI analysis to complete',
      ],
      'tips': 'Quality images = accurate grading. Retake any blurry or poorly lit photos.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Step-by-Step Instructions",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Step ${_currentPage + 1} of ${_steps.length}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      "${((_currentPage + 1) / _steps.length * 100).toInt()}%",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / _steps.length,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: (step['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            step['icon'] as IconData,
                            size: 64,
                            color: step['color'] as Color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        step['title'] as String,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        step['description'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Details
                      Container(
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Detailed Steps:",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...(step['details'] as List<String>).asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: (step['color'] as Color).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${entry.key + 1}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: step['color'] as Color,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tips
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              color: Colors.amber.shade700,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Pro Tip",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    step['tips'] as String,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.amber.shade900,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Navigation buttons
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Previous",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  flex: _currentPage == 0 ? 1 : 1,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _steps.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Great! You're ready to capture images."),
                            backgroundColor: Color(0xFF2E7D32),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage < _steps.length - 1 ? "Next" : "Done",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Video Instructions Screen
class VideoInstructionsScreen extends StatelessWidget {
  const VideoInstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Video Tutorial",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Video Player Placeholder
            Container(
              width: double.infinity,
              height: 220,
              color: Colors.black87,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.play_circle_filled_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "0:00 / 4:15",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Icon(Icons.fullscreen, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    "Complete Image Capture Guide",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "4 min 15 sec",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.visibility_rounded, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "1.8K views",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Video chapters
                  Text(
                    "Video Chapters",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),

                  const _VideoChapter(
                    time: "0:00",
                    title: "Introduction & Overview",
                    icon: Icons.waving_hand_rounded,
                    color: Colors.blue,
                  ),
                  const _VideoChapter(
                    time: "0:30",
                    title: "Sampling from Gunny Bag",
                    icon: Icons.inventory_2_rounded,
                    color: Colors.green,
                  ),
                  const _VideoChapter(
                    time: "1:15",
                    title: "Preparing A4 Background",
                    icon: Icons.description_rounded,
                    color: Colors.purple,
                  ),
                  const _VideoChapter(
                    time: "1:45",
                    title: "Capturing Full A4 Images",
                    icon: Icons.crop_square_rounded,
                    color: Colors.orange,
                  ),
                  const _VideoChapter(
                    time: "2:30",
                    title: "Capturing Half A4 Images",
                    icon: Icons.view_column_rounded,
                    color: Colors.cyan,
                  ),
                  const _VideoChapter(
                    time: "3:10",
                    title: "Taking Close-Up Photos",
                    icon: Icons.zoom_in_rounded,
                    color: Colors.red,
                  ),
                  const _VideoChapter(
                    time: "3:50",
                    title: "Review & Upload Tips",
                    icon: Icons.cloud_upload_rounded,
                    color: Color(0xFF2E7D32),
                  ),

                  const SizedBox(height: 24),

                  // Quick Reference Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.summarize_rounded, color: Colors.white, size: 32),
                        const SizedBox(height: 12),
                        const Text(
                          "Quick Reference Guide",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Download a PDF with all image capture steps",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Downloading PDF guide...")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.file_download_rounded),
                              SizedBox(width: 8),
                              Text(
                                "Download PDF",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Image Requirements Summary
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: Colors.teal.shade700, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "Remember",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _RequirementItem(
                          text: "Take 3 samples: Top, Middle, Bottom",
                          icon: Icons.check_circle_outline,
                        ),
                        _RequirementItem(
                          text: "9 total images: 3 photos per sample",
                          icon: Icons.check_circle_outline,
                        ),
                        _RequirementItem(
                          text: "Full A4, Half A4, and Close-up for each",
                          icon: Icons.check_circle_outline,
                        ),
                        _RequirementItem(
                          text: "Use white A4 paper background",
                          icon: Icons.check_circle_outline,
                        ),
                        _RequirementItem(
                          text: "Ensure good lighting (no shadows)",
                          icon: Icons.check_circle_outline,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Need help section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.support_agent_rounded, size: 32, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text(
                          "Need Help?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Contact our support team for guidance",
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Opening support chat...")),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          label: const Text("Contact Support"),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoChapter extends StatelessWidget {
  final String time;
  final String title;
  final IconData icon;
  final Color color;

  const _VideoChapter({
    required this.time,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Seeking to $time - $title")),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_arrow_rounded, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String text;
  final IconData icon;

  const _RequirementItem({
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.teal.shade600,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}