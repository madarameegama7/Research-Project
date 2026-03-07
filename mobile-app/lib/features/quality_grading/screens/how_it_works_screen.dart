import 'package:flutter/material.dart';

class HowItWorksScreen extends StatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<HowItWorksPage> _pages = [
    HowItWorksPage(
      title: "Welcome to AI-Powered Quality Grading",
      description: "Our system combines IoT technology and artificial intelligence to provide accurate, transparent quality assessment for your pepper samples.",
      icon: Icons.auto_awesome,
      color: Colors.purple,
      details: [
        "Real-time bulk density measurement",
        "AI-powered visual analysis",
        "Comprehensive quality scoring",
        "Instant certification reports",
      ],
    ),
    HowItWorksPage(
      title: "Step 1: Bulk Density Measurement",
      description: "Connect your ESP32 IoT device via Bluetooth to measure the physical density of your pepper sample.",
      icon: Icons.scale_rounded,
      color: Colors.blue,
      details: [
        "Pour 1L of pepper into the measuring container",
        "Load cell measures weight with high precision",
        "ESP32 calculates bulk density (g/L)",
        "Data transmitted to app via Bluetooth",
        "Grade I: ≥550 g/L (black) / ≥600 g/L (white)",
      ],
    ),
    HowItWorksPage(
      title: "Step 2: Visual Capture",
      description: "Take 8 photos of your pepper sample following our standardized guidelines for accurate AI analysis.",
      icon: Icons.camera_alt_rounded,
      color: Colors.teal,
      details: [
        "Spread pepper on white A4 sheet",
        "Ensure good natural lighting",
        "Hold camera 20-30 cm above sample",
        "Capture from multiple angles",
        "5 overhead shots + 3 close-ups",
        "Avoid shadows and reflections",
      ],
    ),
    HowItWorksPage(
      title: "Step 3: Piperine Content Estimation",
      description: "Select your pepper variety to estimate piperine content based on research data.",
      icon: Icons.science_rounded,
      color: Colors.orange,
      details: [
        "Ceylon Pepper: 10-12% (100 points)",
        "Bootawe Rala: 6.3% (70 points)",
        "Kohukumbure Rala: 6% (65 points)",
        "Dingi Rala: 5.6% (60 points)",
        "Panniyur-1: 4.9% (50 points)",
        "Higher piperine = better quality & value",
      ],
    ),
    HowItWorksPage(
      title: "AI Visual Analysis - Defects",
      description: "Advanced detection of mold, adulteration, and quality issues using trained neural networks.",
      icon: Icons.bug_report_rounded,
      color: Colors.red,
      details: [
        "Mold detection: White/grey fuzzy patches",
        "Adulteration: Papaya seeds, foreign items",
        "Extraneous matter: Stones, sticks, debris",
        "Insect damage: Holes and bite marks",
        "Each defect reduces overall grade",
        "Zero tolerance for adulterants",
      ],
    ),
    HowItWorksPage(
      title: "Surface Texture Recognition",
      description: "AI evaluates surface texture to confirm proper processing and drying.",
      icon: Icons.texture_rounded,
      color: Colors.brown,
      details: [
        "Black pepper: Should be wrinkled",
        "White pepper: Smooth or slightly pitted",
        "Texture indicates drying quality",
        "Classifier trained on texture patterns",
        "≥95% conformity = full points",
        "Poor texture = processing issues",
      ],
    ),
    HowItWorksPage(
      title: "Weighted Scoring System",
      description: "All factors are weighted and combined into a comprehensive quality score.",
      icon: Icons.calculate_rounded,
      color: Colors.green,
      details: [
        "Bulk Density: 18% weight",
        "Adulteration: 15% weight",
        "Piperine Content: 10% weight",
        "Color, Size, Mold: 10% each",
        "Texture, Extraneous: 8-10%",
        "Final score: 0-100 points",
      ],
    ),
    HowItWorksPage(
      title: "Quality Grades & Certification",
      description: "Your final grade is determined by the weighted score and blocking rules.",
      icon: Icons.workspace_premium_rounded,
      color: Colors.amber,
      details: [
        "Premium Quality: ≥92 points",
        "Gold: 80-91 points",
        "Silver: 65-79 points",
        "Bronze: 50-64 points",
        "Reject: <50 points",
        "GAP certification adds bonus points",
      ],
    ),
    HowItWorksPage(
      title: "Your Complete Report",
      description: "Receive a detailed PDF report with QR code for buyer verification and traceability.",
      icon: Icons.description_rounded,
      color: Colors.deepPurple,
      details: [
        "Overall quality grade (A/B/C)",
        "Factor-by-factor breakdown",
        "Visual evidence of detections",
        "Improvement recommendations",
        "Shareable QR code",
        "Full transparency for buyers",
      ],
    ),
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
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "How It Works",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _buildPageContent(_pages[index]);
              },
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildPageContent(HowItWorksPage page) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: page.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.icon,
                size: 80,
                color: page.color,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.grey[900],
                height: 1.2,
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            // Details
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: page.details.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: page.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: page.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            detail,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 32 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF2E7D32)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 20),

            // Navigation buttons
            Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text("Previous"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                if (_currentPage > 0) const SizedBox(width: 12),

                Expanded(
                  flex: _currentPage == 0 ? 1 : 1,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    icon: Icon(
                      _currentPage < _pages.length - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                    ),
                    label: Text(
                      _currentPage < _pages.length - 1 ? "Next" : "Got It",
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HowItWorksPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> details;

  HowItWorksPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.details,
  });
}