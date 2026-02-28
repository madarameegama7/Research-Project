import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/responsive.dart';
import '../auth/login_page.dart';
import '../onboarding/onboarding_screen_two.dart';

class OnboardingScreenOne extends StatefulWidget {
  const OnboardingScreenOne({super.key});

  @override
  State<OnboardingScreenOne> createState() => _OnboardingScreenOneState();
}

class _OnboardingScreenOneState extends State<OnboardingScreenOne>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final primary = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
          child: Column(
            children: [
              // Skip button
              SizedBox(
                height: responsive.value(mobile: 60, tablet: 64),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool("seenOnboarding", true);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: Text(
                      "Skip",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: responsive.bodyFontSize,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Title section
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [primary, primary.withOpacity(0.7)],
                            ).createShader(bounds),
                            child: Text(
                              "Predict Your",
                              style: TextStyle(
                                fontSize: responsive.value(mobile: 32, tablet: 40),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [primary, primary.withOpacity(0.7)],
                            ).createShader(bounds),
                            child: Text(
                              "Harvest",
                              style: TextStyle(
                                fontSize: responsive.value(mobile: 32, tablet: 40),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),

                      // Illustration
                      Flexible(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final size = constraints.maxHeight * 0.85;
                            return Image.asset(
                              "assets/images/onboarding/onboard1.png",
                              height: size,
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),

                      // Subtitle
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.value(mobile: 16, tablet: 32),
                        ),
                        child: Text(
                          "Get harvest estimation and identify factors affecting your yield",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsive.value(mobile: 15, tablet: 17),
                            height: 1.5,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDot(true, primary, responsive),
                      SizedBox(width: responsive.smallSpacing / 2),
                      _buildDot(false, primary, responsive),
                      SizedBox(width: responsive.smallSpacing / 2),
                      _buildDot(false, primary, responsive),
                      SizedBox(width: responsive.smallSpacing / 2),
                      _buildDot(false, primary, responsive),
                    ],
                  ),

                  SizedBox(height: responsive.value(mobile: 32, tablet: 40)),

                  // Next button
                  Container(
                    width: double.infinity,
                    height: responsive.buttonHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(responsive.buttonHeight / 2),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OnboardingScreenTwo(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(responsive.buttonHeight / 2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Next",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: responsive.titleFontSize,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: responsive.smallSpacing),
                          Icon(Icons.arrow_forward_rounded, size: 22),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: responsive.value(mobile: 32, tablet: 40)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool active, Color primary, Responsive responsive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? responsive.value(mobile: 24, tablet: 28) : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? primary : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}