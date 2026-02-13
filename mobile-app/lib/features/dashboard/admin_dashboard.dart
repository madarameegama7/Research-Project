import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../utils/localization.dart';
import '../../utils/language_prefs.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _currentLanguage = 'en';

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

  void _switchLanguage(String languageCode) {
    setState(() {
      _currentLanguage = languageCode;
    });
    LanguagePrefs.setLanguage(languageCode);
  }

  String _translate(String key) {
    return AppLocalizations.translate(_currentLanguage, key);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final primary = const Color(0xFF2E7D32);
    final lightGreen = const Color(0xFFE8F5E9);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language Switch Button
                Padding(
                  padding: EdgeInsets.all(responsive.pagePadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _languageButton('EN', 'en', responsive),
                            Container(
                              width: 1,
                              height: 24,
                              color: primary,
                            ),
                            _languageButton('සි', 'si', responsive),
                            Container(
                              width: 1,
                              height: 24,
                              color: primary,
                            ),
                            _languageButton('தமிழ்', 'ta', responsive),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Header
                Container(
                  padding: responsive.padding(
                    mobile: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                    tablet: const EdgeInsets.fromLTRB(32, 24, 32, 36),
                    desktop: const EdgeInsets.fromLTRB(40, 28, 40, 42),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, primary.withOpacity(0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(
                        responsive.value(mobile: 32, tablet: 36, desktop: 40),
                      ),
                      bottomRight: Radius.circular(
                        responsive.value(mobile: 32, tablet: 36, desktop: 40),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _translate('hello_admin'),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: responsive.bodyFontSize,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              ResponsiveSpacing(mobile: 4, tablet: 6, desktop: 8),
                              Text(
                                _translate('system_control_panel'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: responsive.fontSize(
                                    mobile: 26,
                                    tablet: 28,
                                    desktop: 32,
                                  ),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: responsive.value(
                                mobile: 26,
                                tablet: 28,
                                desktop: 32,
                              ),
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.admin_panel_settings,
                                color: primary,
                                size: responsive.value(
                                  mobile: 28,
                                  tablet: 32,
                                  desktop: 36,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),
                      _systemStatusCard(responsive),
                    ],
                  ),
                ),

                ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                // Section Title
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.pagePadding,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: responsive.value(mobile: 4, tablet: 5, desktop: 6),
                        height: responsive.value(mobile: 22, tablet: 24, desktop: 26),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      ResponsiveSpacing.horizontal(
                        mobile: 12,
                        tablet: 14,
                        desktop: 16,
                      ),
                      Text(
                        _translate('management_tools'),
                        style: TextStyle(
                          fontSize: responsive.headingFontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                // Feature Grid
                SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.pagePadding,
                    ),
                    child: ResponsiveBuilder(
                      mobile: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.95,
                        children: _buildFeatureCards(responsive),
                      ),
                      tablet: GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.95,
                        children: _buildFeatureCards(responsive),
                      ),
                      desktop: GridView.count(
                        crossAxisCount: 6,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: 0.85,
                        children: _buildFeatureCards(responsive),
                      ),
                    ),
                  ),
                ),

                ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                // Tips or Notices
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.pagePadding,
                  ),
                  child: Text(
                    _translate('system_notices'),
                    style: TextStyle(
                      fontSize: responsive.headingFontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ),

                ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                _noticeCard(
                  responsive,
                  title: _translate('pending_verification'),
                  icon: Icons.pending_actions_rounded,
                  color: Colors.deepOrange,
                ),
                _noticeCard(
                  responsive,
                  title: _translate('server_running'),
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),
                _noticeCard(
                  responsive,
                  title: _translate('new_registrations'),
                  icon: Icons.person_add_rounded,
                  color: Colors.blue,
                ),

                ResponsiveSpacing(mobile: 24, tablet: 32, desktop: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageButton(String label, String languageCode, Responsive responsive) {
    final isSelected = _currentLanguage == languageCode;
    final primary = const Color(0xFF2E7D32);

    return GestureDetector(
      onTap: () => _switchLanguage(languageCode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isSelected ? primary : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _systemStatusCard(Responsive responsive) {
    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(18),
        desktop: const EdgeInsets.all(20),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.speed_rounded,
            color: Colors.white,
            size: responsive.value(mobile: 26, tablet: 28, desktop: 30),
          ),
          ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
          Text(
            _translate('system_status'),
            style: TextStyle(
              color: Colors.white,
              fontSize: responsive.titleFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.check_circle,
            color: Colors.greenAccent,
            size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureCards(Responsive responsive) {
    return [
      _featureCard(
        responsive,
        title: _translate('users_management'),
        icon: Icons.group_rounded,
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade700,
          ],
        ),
        onTap: () {},
      ),
      _featureCard(
        responsive,
        title: _translate('view_reports'),
        icon: Icons.insert_chart_rounded,
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade400,
            Colors.teal.shade700,
          ],
        ),
        onTap: () {},
      ),
      _featureCard(
        responsive,
        title: _translate('system_analytics'),
        icon: Icons.analytics_rounded,
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.orange.shade700,
          ],
        ),
        onTap: () {},
      ),
      _featureCard(
        responsive,
        title: _translate('verify_products'),
        icon: Icons.verified_rounded,
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400,
            Colors.green.shade700,
          ],
        ),
        onTap: () {},
      ),
      _featureCard(
        responsive,
        title: _translate('market_control'),
        icon: Icons.trending_up_rounded,
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.purple.shade700,
          ],
        ),
        onTap: () {},
      ),
      _featureCard(
        responsive,
        title: _translate('blockchain_logs'),
        icon: Icons.link_rounded,
        gradient: LinearGradient(
          colors: [
            Colors.red.shade400,
            Colors.red.shade700,
          ],
        ),
        onTap: () {},
      ),
    ];
  }

  Widget _featureCard(
      Responsive responsive, {
        required String title,
        required IconData icon,
        required Gradient gradient,
        required Function onTap,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 20, tablet: 22, desktop: 24),
        ),
        onTap: () => onTap(),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(
              responsive.value(mobile: 20, tablet: 22, desktop: 24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.09),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  icon,
                  size: responsive.value(mobile: 70, tablet: 80, desktop: 90),
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              Padding(
                padding: responsive.padding(
                  mobile: const EdgeInsets.all(18),
                  tablet: const EdgeInsets.all(20),
                  desktop: const EdgeInsets.all(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: responsive.padding(
                        mobile: const EdgeInsets.all(10),
                        tablet: const EdgeInsets.all(12),
                        desktop: const EdgeInsets.all(14),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: responsive.value(mobile: 28, tablet: 32, desktop: 36),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    ResponsiveSpacing(mobile: 4, tablet: 6, desktop: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withOpacity(0.8),
                      size: responsive.smallIconSize,
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

  Widget _noticeCard(
      Responsive responsive, {
        required String title,
        required IconData icon,
        required Color color,
      }) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        responsive.pagePadding,
        0,
        responsive.pagePadding,
        responsive.value(mobile: 12, tablet: 14, desktop: 16),
      ),
      padding: responsive.padding(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(18),
        desktop: const EdgeInsets.all(20),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: responsive.value(mobile: 28, tablet: 30, desktop: 32),
          ),
          ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade900,
                fontSize: responsive.bodyFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: responsive.value(mobile: 14, tablet: 16, desktop: 18),
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
