import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';
import '../../services/quality_check_api.dart';
import 'result_summary_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final Map<String, File?> images;
  final String qualityCheckId;
  final String batchId;

  const ProcessingScreen({
    super.key,
    required this.images,
    required this.qualityCheckId,
    required this.batchId,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  final List<String> _steps = [
    'Uploading images...',
    'Analyzing images...',
    'Detecting defects...',
    'Calculating quality score...',
    'Generating report...',
  ];

  Timer? _stepTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();
    _updateSteps();

    // Start backend call after first frame to avoid build context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        _started = true;
        _runAnalysis();
      }
    });
  }

  void _updateSteps() {
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentStep < _steps.length - 1) {
        setState(() => _currentStep++);
        _fadeController.reset();
        _fadeController.forward();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _runAnalysis() async {
    try {
      final api = QualityCheckApi();

      final result = await api.analyzeImages(
        qualityCheckId: widget.qualityCheckId,
        images: widget.images,
        textureFirst: true,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultSummaryScreen(
            qualityCheckId: widget.qualityCheckId,
            batchId: widget.batchId,
            result: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Stop animations step timer if you want
      _stepTimer?.cancel();

      // Show dialog with Retry / Back
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Analysis Failed"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // close dialog
                  Navigator.pop(context); // go back to previous screen (Review)
                },
                child: const Text("Back"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // close dialog
                  // restart analysis
                  setState(() {
                    _currentStep = 0;
                  });
                  _fadeController.forward();
                  _updateSteps();
                  _runAnalysis();
                },
                child: const Text("Retry"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    const primary = Color(0xFF2E7D32);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(responsive.pagePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      RotationTransition(
                        turns: _rotateAnimation,
                        child: Container(
                          width: responsive.value(
                            mobile: 180,
                            tablet: 220,
                            desktop: 260,
                          ),
                          height: responsive.value(
                            mobile: 180,
                            tablet: 220,
                            desktop: 260,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primary.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: responsive.value(
                            mobile: 140,
                            tablet: 170,
                            desktop: 200,
                          ),
                          height: responsive.value(
                            mobile: 140,
                            tablet: 170,
                            desktop: 200,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primary, primary.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: responsive.value(
                              mobile: 50,
                              tablet: 60,
                              desktop: 70,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: responsive.value(
                          mobile: 100,
                          tablet: 120,
                          desktop: 140,
                        ),
                        height: responsive.value(
                          mobile: 100,
                          tablet: 120,
                          desktop: 140,
                        ),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),

                  ResponsiveSpacing(mobile: 48, tablet: 56, desktop: 64),

                  Text(
                    "AI Analysis in Progress",
                    style: TextStyle(
                      fontSize: responsive.fontSize(
                        mobile: 24,
                        tablet: 26,
                        desktop: 28,
                      ),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),

                  ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),

                  Text(
                    "Please wait while we analyze your pepper quality",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: responsive.bodyFontSize,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),

                  ResponsiveSpacing(mobile: 40, tablet: 48, desktop: 56),

                  Container(
                    padding: responsive.padding(
                      mobile: const EdgeInsets.all(24),
                      tablet: const EdgeInsets.all(28),
                      desktop: const EdgeInsets.all(32),
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
                      children: List.generate(_steps.length, (index) {
                        final isActive = index == _currentStep;
                        final isCompleted = index < _currentStep;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < _steps.length - 1
                                ? responsive.value(
                                    mobile: 16,
                                    tablet: 18,
                                    desktop: 20,
                                  )
                                : 0,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: responsive.value(
                                  mobile: 32,
                                  tablet: 36,
                                  desktop: 40,
                                ),
                                height: responsive.value(
                                  mobile: 32,
                                  tablet: 36,
                                  desktop: 40,
                                ),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? primary
                                      : isActive
                                      ? primary.withOpacity(0.2)
                                      : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                  border: isActive
                                      ? Border.all(color: primary, width: 2)
                                      : null,
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: responsive.value(
                                            mobile: 18,
                                            tablet: 20,
                                            desktop: 22,
                                          ),
                                        )
                                      : isActive
                                      ? SizedBox(
                                          width: responsive.value(
                                            mobile: 16,
                                            tablet: 18,
                                            desktop: 20,
                                          ),
                                          height: responsive.value(
                                            mobile: 16,
                                            tablet: 18,
                                            desktop: 20,
                                          ),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(primary),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              ResponsiveSpacing.horizontal(
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
                              Expanded(
                                child: FadeTransition(
                                  opacity: isActive
                                      ? _fadeAnimation
                                      : const AlwaysStoppedAnimation(1.0),
                                  child: Text(
                                    _steps[index],
                                    style: TextStyle(
                                      fontSize: responsive.bodyFontSize,
                                      fontWeight: isActive || isCompleted
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isActive || isCompleted
                                          ? Colors.black87
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  const Spacer(flex: 2),

                  Container(
                    padding: responsive.padding(
                      mobile: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      tablet: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      desktop: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.blue.shade700,
                          size: responsive.smallIconSize,
                        ),
                        ResponsiveSpacing.horizontal(
                          mobile: 10,
                          tablet: 12,
                          desktop: 14,
                        ),
                        Flexible(
                          child: Text(
                            "This usually takes a few seconds",
                            style: TextStyle(
                              fontSize: responsive.bodyFontSize - 1,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
