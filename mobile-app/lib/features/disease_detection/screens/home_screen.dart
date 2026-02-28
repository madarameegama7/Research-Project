import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'image_picker_screen.dart';
import 'posts_view_screen.dart';
import 'complaint_screen.dart';
import 'complaint_list_screen.dart';
import 'analyze_plants_screen.dart';
import '../../../utils/localization.dart';
import '../../../utils/language_prefs.dart';

class HomeScreen extends StatefulWidget {
  final User? user;
  const HomeScreen({super.key, this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller for fade-in effect on screen load
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    // Initialize animation controller with 800ms duration
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    // Create fade animation from 0.0 to 1.0 opacity
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    // Start the animation
    _animationController.forward();

    // Load saved language preference
    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) {
        setState(() {
          _currentLanguage = lang;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openCamera(BuildContext context) async {
    final image = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (context) => const ImagePickerScreen()),
    );

    if (image != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_translate('photo_captured')),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToPosts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PostsViewScreen()),
    );
  }

  void _navigateToComplaint(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ComplaintScreen()),
    );
  }

  void _navigateToComplaintManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ComplaintListScreen()),
    );
  }

  void _navigateToAnalyzePlants(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyzePlantsScreen()),
    );
  }

  String _getUserDisplayName() {
    return 'Farmer';
  }

  String _getUserEmail() {
    return widget.user?.email ?? '';
  }

  final Color primary = const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // ---------------- FIXED HEADER ----------------
            Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  0,
                  MediaQuery.of(context).padding.top + 20,
                  0,
                  30,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _translate('hello_user').replaceAll('{name}', _getUserDisplayName()),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _translate('disease_detection_title'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (_getUserEmail().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _getUserEmail(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

            // ----------- SCROLLABLE CONTENT -----------
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description card
                    _buildDescriptionCard(),

                    const SizedBox(height: 28),

                    // Section title
                    Text(
                      _translate('explore_features'),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Features List
                    // View Posts
                    _buildNavigationCard(
                      title: _translate('view_posts'),
                      subtitle: _translate('view_posts_subtitle'),
                      icon: Icons.dynamic_feed_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF2196F3)],
                      ),
                      onTap: () => _navigateToPosts(context),
                    ),

                    const SizedBox(height: 16),

                    // Make a Complaint
                    _buildNavigationCard(
                      title: _translate('make_complaint'),
                      subtitle: _translate('make_complaint_subtitle'),
                      icon: Icons.report_problem_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                      ),
                      onTap: () => _navigateToComplaint(context),
                    ),

                    const SizedBox(height: 16),

                    // Manage Complaints
                    _buildNavigationCard(
                      title: _translate('manage_complaints'),
                      subtitle: _translate('manage_complaints_subtitle'),
                      icon: Icons.admin_panel_settings_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFBA68C8), Color(0xFF9C27B0)],
                      ),
                      onTap: () => _navigateToComplaintManagement(context),
                    ),

                   const SizedBox(height: 16),

                    // // Analyze Plants
                    // _buildNavigationCard(
                    //   title: _translate('analyze_plants'),
                    //   subtitle: _translate('analyze_plants_subtitle'),
                    //   icon: Icons.eco_rounded,
                    //   gradient: const LinearGradient(
                    //     colors: [Color(0xFF26A69A), Color(0xFF009688)],
                    //   ),
                    //   onTap: () => _navigateToAnalyzePlants(context),
                    // ),

                    // const SizedBox(height: 16),

                    // Open Camera
                    _buildNavigationCard(
                      title: _translate('detection_camera'),
                      subtitle: _translate('detection_camera_subtitle'),
                      icon: Icons.camera_alt_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                      ),
                      onTap: () => _openCamera(context),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC8E6C9), Color(0xFFA5D6A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.black87,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _translate('smart_farming_tools'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _translate('disease_description'),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                bottom: -12,
                child: Icon(
                  icon,
                  size: 65,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white.withOpacity(0.95),
                              size: 14,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _translate(String key) {
    return AppLocalizations.translate(_currentLanguage, key);
  }
}