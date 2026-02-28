import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_page.dart';
import '../../utils/responsive.dart';

class OnboardingScreenFour extends StatefulWidget {
  const OnboardingScreenFour({super.key});

  @override
  State<OnboardingScreenFour> createState() => _OnboardingScreenFourState();
}

class _OnboardingScreenFourState extends State<OnboardingScreenFour>
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
    final lightGreen = const Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
          child: Column(
            children: [
              // Back button only (no skip on last screen)
              SizedBox(
                height: responsive.value(mobile: 60, tablet: 64),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios_rounded, color: primary, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: lightGreen,
                        padding: EdgeInsets.zero,
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
                              "Market Prices &",
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
                              "Traceability",
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
                              "assets/images/onboarding/onboard4.png",
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
                          "Get weekly pepper prices, forecast market trends, and analyze blockchain to gain trust",
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
                      _buildDot(false, primary, responsive),
                      SizedBox(width: responsive.smallSpacing / 2),
                      _buildDot(false, primary, responsive),
                      SizedBox(width: responsive.smallSpacing / 2),
                      _buildDot(false, primary, responsive),
                      SizedBox(width: responsive.smallSpacing / 2),
                      _buildDot(true, primary, responsive),
                    ],
                  ),

                  SizedBox(height: responsive.value(mobile: 32, tablet: 40)),

                  // Get Started button with gradient
                  Container(
                    width: double.infinity,
                    height: responsive.buttonHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(responsive.buttonHeight / 2),
                      gradient: LinearGradient(
                        colors: [primary, primary.withOpacity(0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool("seenOnboarding", true);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(responsive.buttonHeight / 2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Get Started",
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