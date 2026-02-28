import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../utils/responsive.dart';
import '../../widgets/navigation_wrapper.dart';
import '../auth/login_page.dart';
import '../dashboard/admin_dashboard.dart';
import '../onboarding/onboarding_screen_one.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shimmerAnimation;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startNavigation();
  }

  void _initAnimations() {
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 100), () {
        _scaleController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          _slideController.forward();
          _shimmerController.repeat(reverse: true);
        });
      });
    });
  }

  void _startNavigation() {
    Timer(const Duration(milliseconds: 3000), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      bool seenOnboarding = prefs.getBool("seenOnboarding") ?? false;

      if (!seenOnboarding) {
        _go(const OnboardingScreenOne());
        return;
      }

      var userData = await _authService.getCurrentUser();

      if (userData == null) {
        _go(const LoginPage());
        return;
      }

      // String role = userData["role"];

      // if (role == "farmer") {
      //   _go(const FarmerDashboard());
      // } else if (role == "exporter") {
      //   _go(const ExporterDashboard());
      // } else if (role == "admin") {
      //   _go(const AdminDashboard());
      // } else {
      //   _go(const LoginPage());
      // }

      final String role = (userData["role"] ?? "").toString();

      if (role == "admin") {
        _go(const AdminDashboard());
      } else {
        // farmer or exporter (and any unknown non-admin role)
        _go(const NavigationWrapper());
      }
    });
  }

  void _go(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => page,
        transitionsBuilder: (_, a, b, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    // Responsive sizing using utility
    final logoSize = responsive.value(mobile: 100, tablet: 120, desktop: 140);
    final logoPadding = responsive.value(mobile: 16, tablet: 20, desktop: 24);
    final titleFontSize = responsive.value(mobile: 36, tablet: 42, desktop: 48);
    final subtitleFontSize = responsive.value(
      mobile: 14,
      tablet: 16,
      desktop: 18,
    );
    final verticalSpacing = responsive.value(
      mobile: 40,
      tablet: 50,
      desktop: 60,
    );
    final loadingSize = responsive.value(mobile: 40, tablet: 45, desktop: 50);
    final particleCount = responsive.isDesktop ? 30 : 20;
    final particleSize = responsive.value(mobile: 4, tablet: 5, desktop: 6);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE8F5E9),
              const Color(0xFFF1F8E9),
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(particleCount, (index) {
              return AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Positioned(
                    left: (index * 50.0) % responsive.width,
                    top: (index * 80.0) % responsive.height,
                    child: Opacity(
                      opacity: 0.15 + (_shimmerAnimation.value.abs() * 0.15),
                      child: Container(
                        width: particleSize,
                        height: particleSize,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Main content
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: responsive.padding(
                        mobile: EdgeInsets.symmetric(
                          horizontal: responsive.width * 0.08,
                          vertical: responsive.height * 0.05,
                        ),
                        tablet: EdgeInsets.symmetric(
                          horizontal: responsive.width * 0.12,
                          vertical: responsive.height * 0.06,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with scale animation and glow
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              padding: EdgeInsets.all(
                                responsive.value(
                                  mobile: 20,
                                  tablet: 24,
                                  desktop: 28,
                                ),
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4CAF50,
                                    ).withOpacity(0.3),
                                    blurRadius: responsive.value(
                                      mobile: 50,
                                      tablet: 60,
                                      desktop: 70,
                                    ),
                                    spreadRadius: responsive.value(
                                      mobile: 20,
                                      tablet: 25,
                                      desktop: 30,
                                    ),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: EdgeInsets.all(logoPadding),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFF4CAF50,
                                    ).withOpacity(0.3),
                                    width: responsive.value(
                                      mobile: 2,
                                      tablet: 2.5,
                                      desktop: 3,
                                    ),
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    "assets/images/logos/logo.png",
                                    height: logoSize,
                                    width: logoSize,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: verticalSpacing),

                          // App name with slide animation
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _slideController,
                              child: Column(
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) {
                                      return LinearGradient(
                                        colors: [
                                          const Color(0xFF4CAF50),
                                          const Color(0xFF66BB6A),
                                          const Color(0xFF4CAF50),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ).createShader(bounds);
                                    },
                                    child: Text(
                                      "CeylonPepper",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: titleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: responsive.smallSpacing),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsive.width * 0.05,
                                    ),
                                    child: Text(
                                      "Grow Together, Thrive Together",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: subtitleFontSize,
                                        color: const Color(
                                          0xFF4CAF50,
                                        ).withOpacity(0.7),
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(
                            height: responsive.value(
                              mobile: 60,
                              tablet: 70,
                              desktop: 80,
                            ),
                          ),

                          // Loading indicator
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SizedBox(
                              width: loadingSize,
                              height: loadingSize,
                              child: CircularProgressIndicator(
                                strokeWidth: responsive.value(
                                  mobile: 3,
                                  tablet: 3.5,
                                  desktop: 4,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF4CAF50).withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
