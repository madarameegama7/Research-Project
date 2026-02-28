import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';
import 'image_upload_screen.dart';
import '../iot_device_setup_screen.dart';

class BulkDensityScreen extends StatefulWidget {
  final String qualityCheckId;
  final String batchId;
  const BulkDensityScreen({
    super.key,
    required this.qualityCheckId,
    required this.batchId,
  });

  @override
  State<BulkDensityScreen> createState() => _BulkDensityScreenState();
}

class _BulkDensityScreenState extends State<BulkDensityScreen>
    with SingleTickerProviderStateMixin {
  // IoT State Management
  bool _isIoTConnected = false;
  bool _isReading = false;
  double? _densityValue; // null = not read yet

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

    // Check IoT connection on startup
    _checkIoTConnection();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // TODO: Replace with actual Bluetooth/WiFi connection check
  Future<void> _checkIoTConnection() async {
    setState(() => _isReading = true);

    await Future.delayed(const Duration(seconds: 1)); // Simulate connection check

    setState(() {
      _isIoTConnected = true; // Simulated - replace with actual check
      _isReading = false;
    });
  }

  // TODO: Replace with actual IoT device reading
  Future<void> _readFromIoT() async {
    if (!_isIoTConnected) {
      _showSnackBar('Please connect IoT device first', Colors.red);
      return;
    }

    setState(() => _isReading = true);

    try {
      // Simulate reading from IoT device
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Replace with actual Bluetooth/API call
      // Example: final value = await BluetoothService.readDensity();
      final simulatedValue = 642.5; // Replace with actual IoT reading

      setState(() {
        _densityValue = simulatedValue;
        _isReading = false;
      });

      _showSnackBar('Density reading successful!', Colors.green);
    } catch (e) {
      setState(() => _isReading = false);
      _showSnackBar('Failed to read from device: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
          'Bulk Density',
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
                        _buildStepLine(false, primary, responsive),
                        _buildStepIndicator(3, false, primary, responsive),
                      ],
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Density Measurement",
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
                                "Read density from IoT device",
                                style: TextStyle(
                                  fontSize: responsive.bodyFontSize,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // IoT Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.value(mobile: 12, tablet: 14, desktop: 16),
                            vertical: responsive.value(mobile: 8, tablet: 9, desktop: 10),
                          ),
                          decoration: BoxDecoration(
                            color: _isIoTConnected
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isIoTConnected
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isIoTConnected ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isIoTConnected ? 'Connected' : 'Disconnected',
                                style: TextStyle(
                                  fontSize: responsive.bodyFontSize - 2,
                                  fontWeight: FontWeight.w600,
                                  color: _isIoTConnected
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
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
                      // Instructions Card
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
                                    'Measurement Instructions',
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
                              '1. Ensure IoT device is connected\n2. Place pepper sample in the device\n3. Click "Read from Device" button\n4. Wait for the reading to complete',
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
                                    builder: (_) => const IotDeviceSetupScreen(),
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

                      // Connection Warning (if not connected)
                      if (!_isIoTConnected)
                        Container(
                          padding: responsive.padding(
                            mobile: const EdgeInsets.all(16),
                            tablet: const EdgeInsets.all(18),
                            desktop: const EdgeInsets.all(20),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange.shade700,
                                size: responsive.mediumIconSize,
                              ),
                              ResponsiveSpacing.horizontal(
                                mobile: 12,
                                tablet: 14,
                                desktop: 16,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'IoT Device Not Connected',
                                      style: TextStyle(
                                        fontSize: responsive.bodyFontSize,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Please connect your bulk density measuring device via Bluetooth or WiFi to proceed.',
                                      style: TextStyle(
                                        fontSize: responsive.bodyFontSize - 1,
                                        color: Colors.orange.shade800,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (!_isIoTConnected)
                        ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                      // Density Display Card (Read-only)
                      Center(
                        child: Container(
                          padding: responsive.padding(
                            mobile: const EdgeInsets.all(20),
                            tablet: const EdgeInsets.all(24),
                            desktop: const EdgeInsets.all(28),
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.grey.shade50,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _densityValue != null
                                  ? Colors.green.shade200
                                  : Colors.grey.shade200,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row
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
                                      color: _densityValue != null
                                          ? Colors.green.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.straighten_rounded,
                                      color: _densityValue != null
                                          ? primary
                                          : Colors.grey.shade400,
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
                                      'Bulk Density Reading',
                                      style: TextStyle(
                                        fontSize: responsive.titleFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                              // Main Content - Reading Display
                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      _densityValue == null
                                          ? 'Not ready yet'
                                          : '${_densityValue!.toStringAsFixed(1)} g/L',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(
                                          mobile: 32,
                                          tablet: 38,
                                          desktop: 44,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        color: _densityValue != null
                                            ? primary
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                    ResponsiveSpacing(mobile: 6, tablet: 8, desktop: 10),
                                    Text(
                                      _densityValue == null
                                          ? 'Click "Read from Device" to measure'
                                          : 'Measurement complete',
                                      style: TextStyle(
                                        fontSize: responsive.bodyFontSize,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                              // Status Badge at Bottom
                              if (_densityValue != null)
                                Center(
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
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.green.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade700,
                                          size: responsive.smallIconSize,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Reading Complete',
                                          style: TextStyle(
                                            fontSize: responsive.bodyFontSize - 2,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Center(
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
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.pending_rounded,
                                          color: Colors.grey.shade600,
                                          size: responsive.smallIconSize,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Waiting for reading',
                                          style: TextStyle(
                                            fontSize: responsive.bodyFontSize - 2,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                      // Read from Device Button
                      Container(
                        width: double.infinity,
                        height: responsive.buttonHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            if (_isIoTConnected && !_isReading)
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isIoTConnected && !_isReading
                              ? _readFromIoT
                              : null,
                          icon: _isReading
                              ? SizedBox(
                            width: responsive.value(
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                            height: responsive.value(
                              mobile: 18,
                              tablet: 20,
                              desktop: 22,
                            ),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                              : Icon(
                            Icons.sensors_rounded,
                            size: responsive.smallIconSize,
                          ),
                          label: Text(
                            _isReading
                                ? 'Reading from device...'
                                : 'Read from Device',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: responsive.titleFontSize,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),

                      // Continue Button (only enabled after reading)
                      Container(
                        width: double.infinity,
                        height: responsive.buttonHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            if (_densityValue != null)
                              BoxShadow(
                                color: primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _densityValue != null
                              ? () {
                            // Pass density value to next screen if needed
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ImageUploadScreen(qualityCheckId: '', batchId: '',),
                              ),
                            );
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Continue to Image Upload",
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

  Widget _buildStepIndicator(int step, bool isActive, Color primary, Responsive responsive) {
    final isCompleted = step < 2;

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