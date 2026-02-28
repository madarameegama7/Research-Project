import 'dart:io';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/disease_detection_service.dart';
import '../../../utils/localization.dart';
import '../../../utils/language_prefs.dart';

class DiseaseResultScreen extends StatefulWidget {
  final File imageFile;
  final DiseaseDetectionResult? result;

  const DiseaseResultScreen({
    Key? key,
    required this.imageFile,
    this.result,
  }) : super(key: key);

  @override
  State<DiseaseResultScreen> createState() => _DiseaseResultScreenState();
}

class _DiseaseResultScreenState extends State<DiseaseResultScreen>
    with TickerProviderStateMixin {
  late DiseaseDetectionResult? _result;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  String _currentLanguage = 'en';

  String _translate(String key) {
    return AppLocalizations.translate(_currentLanguage, key);
  }

  @override
  void initState() {
    super.initState();
    _result = widget.result;

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Load language preference
    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) {
        setState(() {
          _currentLanguage = lang;
        });
      }
    });

    if (_result == null) {
      _detectDisease();
    } else {
      _isLoading = false;
      _slideController.forward();
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _detectDisease() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final result = await DiseaseDetectionService.detectDisease(widget.imageFile);

      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
        _slideController.forward();
        _fadeController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getSeverityColor() {
    if (_result == null) return Colors.grey;

    switch (_result!.severity.toLowerCase()) {
      case 'high':
        return const Color(0xFFFF6B6B);
      case 'medium':
        return const Color(0xFFFFA500);
      case 'low':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _getSeverityIcon() {
    if (_result == null) return Icons.help;

    switch (_result!.severity.toLowerCase()) {
      case 'high':
        return Icons.error_rounded;
      case 'medium':
        return Icons.warning_rounded;
      case 'low':
        return Icons.info_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _translate('disease_detection_result'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _errorMessage != null
              ? _buildErrorScreen()
              : (_result == null ? _buildErrorScreen() : _buildResultScreen()),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
            ),
            child: const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _translate('analyzing_image'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _translate('using_cnn_model'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _translate('detection_failed'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _detectDisease,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _translate('retry'),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    return FadeTransition(
      opacity: Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview with animated entry
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut)),
              child: _buildImagePreview(),
            ),
            const SizedBox(height: 24),

            // Disease card with animated entry
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut)),
              child: _buildDiseaseCard(),
            ),
            const SizedBox(height: 20),

            // Confidence meter
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut)),
              child: _buildConfidenceMeter(),
            ),
            const SizedBox(height: 20),

            // Description
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut)),
              child: _buildDescriptionSection(),
            ),
            const SizedBox(height: 20),

            // Treatment
            if (!_result!.isHealthy) ...[
              SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                    .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut)),
                child: _buildTreatmentSection(),
              ),
              const SizedBox(height: 20),
            ],

            // Prevention
            if (_result!.prevention.isNotEmpty) ...[
              SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                    .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut)),
                child: _buildPreventionSection(),
              ),
              const SizedBox(height: 20),
            ],

            // All predictions
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut)),
              child: _buildPredictionsChart(),
            ),
            const SizedBox(height: 32),

            // Action buttons
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut)),
              child: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.file(
              widget.imageFile,
              fit: BoxFit.cover,
            ),
            // Add a subtle shine effect
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiseaseCard() {
    final severityColor = _getSeverityColor();
    final severityIcon = _getSeverityIcon();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            severityColor.withValues(alpha: 0.15),
            severityColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: severityColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: severityColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              severityIcon,
              color: severityColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _result!.disease,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: severityColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _result!.severity.isEmpty ? 'None' : _result!.severity,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
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

  Widget _buildConfidenceMeter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _translate('confidence_level'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_result!.confidence.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _result!.confidence / 100,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _translate('model_confidence'),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_rounded,
              color: Colors.blue.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _translate('description'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            _result!.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.medical_services_rounded,
              color: Colors.red.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _translate('treatment'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            _result!.treatment,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreventionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shield_rounded,
              color: Colors.orange.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _translate('prevention'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            _result!.prevention,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionsChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.analytics_rounded,
              color: Colors.purple.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _translate('all_predictions'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: _result!.allPredictions.entries.map((entry) {
              final disease = entry.key;
              final probability = (entry.value as num).toDouble() * 100;
              final isHighest = disease == _result!.disease;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            disease,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isHighest ? FontWeight.w700 : FontWeight.w600,
                              color: isHighest ? Colors.grey[900] : Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isHighest
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${probability.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isHighest
                                ? const Color(0xFF2E7D32)
                                : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: probability / 100,
                        minHeight: 6,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isHighest
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[400]!,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              shadowColor: const Color(0xFF2E7D32).withValues(alpha: 0.4),
            ),
            child: Text(
              _translate('analyze_another_image'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _translate('go_back'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

