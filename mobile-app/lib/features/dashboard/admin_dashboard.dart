import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import '../blockchain/screens/pepper_batches.dart';

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

  String _userName = 'Admin';

  final AuthService _authService = AuthService();

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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
    _loadUserName();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Convert string to title case
  String _titleCase(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    return parts
        .map((p) {
          if (p.isEmpty) return '';
          final lower = p.toLowerCase();
          return lower.length == 1
              ? lower.toUpperCase()
              : '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .where((p) => p.isNotEmpty)
        .join(' ');
  }

  // Display user name in header
  Future<void> _loadUserName() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final firstRaw =
            (user['firstName'] ?? user['first_name'] ?? user['name'] ?? '')
                .toString();
        final lastRaw = (user['lastName'] ?? user['last_name'] ?? '')
            .toString();
        final first = _titleCase(firstRaw);
        final last = _titleCase(lastRaw);
        final name = (first + (last.isNotEmpty ? ' $last' : '')).trim();
        if (mounted && name.isNotEmpty) {
          setState(() => _userName = name);
          return;
        }
      }
    } catch (e) {
      // Keep default "Admin" if error occurs
    }
  }

  Color _colorWithOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final primary = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(responsive, primary),

                  ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                  // Section Title
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.pagePadding,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: responsive.value(
                            mobile: 4,
                            tablet: 5,
                            desktop: 6,
                          ),
                          height: responsive.value(
                            mobile: 22,
                            tablet: 24,
                            desktop: 26,
                          ),
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
                          'Management Tools',
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

                  // Notices
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.pagePadding,
                    ),
                    child: Text(
                      'System Notices',
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
                    title: 'Pending Verification',
                    icon: Icons.pending_actions_rounded,
                    color: Colors.deepOrange,
                  ),
                  _noticeCard(
                    responsive,
                    title: 'Server Running',
                    icon: Icons.check_circle_rounded,
                    color: Colors.green,
                  ),
                  _noticeCard(
                    responsive,
                    title: 'New Registrations',
                    icon: Icons.person_add_rounded,
                    color: Colors.blue,
                  ),

                  ResponsiveSpacing(mobile: 24, tablet: 32, desktop: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build Header (English only)
  Widget _buildHeader(Responsive responsive, Color primary) {
    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        tablet: const EdgeInsets.fromLTRB(32, 24, 32, 36),
        desktop: const EdgeInsets.fromLTRB(40, 28, 40, 42),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, _colorWithOpacity(primary, 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            responsive.value(mobile: 28, tablet: 36, desktop: 40),
          ),
          bottomRight: Radius.circular(
            responsive.value(mobile: 28, tablet: 36, desktop: 40),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: _colorWithOpacity(primary, 0.3),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $_userName 👋",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: responsive.fontSize(
                          mobile: 13,
                          tablet: 15,
                          desktop: 16,
                        ),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    ResponsiveSpacing(mobile: 4, tablet: 6, desktop: 8),
                    Text(
                      'System Control Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.fontSize(
                          mobile: 22,
                          tablet: 26,
                          desktop: 30,
                        ),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Container(
                  padding: EdgeInsets.all(
                    responsive.value(mobile: 2, tablet: 3, desktop: 4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: responsive.value(
                      mobile: 18,
                      tablet: 22,
                      desktop: 26,
                    ),
                    backgroundColor: _colorWithOpacity(primary, 0.1),
                    child: Icon(
                      Icons.person_rounded,
                      color: primary,
                      size: responsive.value(
                        mobile: 20,
                        tablet: 24,
                        desktop: 28,
                      ),
                    ),
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await AuthService().logout();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: responsive.smallIconSize,
                        ),
                        ResponsiveSpacing.horizontal(
                          mobile: 10,
                          tablet: 12,
                          desktop: 14,
                        ),
                        const Text('Profile'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          size: responsive.smallIconSize,
                        ),
                        ResponsiveSpacing.horizontal(
                          mobile: 10,
                          tablet: 12,
                          desktop: 14,
                        ),
                        const Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: responsive.smallIconSize,
                        ),
                        ResponsiveSpacing.horizontal(
                          mobile: 10,
                          tablet: 12,
                          desktop: 14,
                        ),
                        const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),
          _systemStatusCard(responsive),
        ],
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
        border: Border.all(color: Colors.white.withOpacity(0.2)),
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
            'System Status',
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
        title: 'Users Management',
        icon: Icons.group_rounded,
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
        ),
        onTap: () {},
      ),
      _featureCard(
        responsive,
        title: 'View Reports',
        icon: Icons.insert_chart_rounded,
        gradient: LinearGradient(
          colors: [Colors.teal.shade400, Colors.teal.shade700],
        ),
        onTap: () {},
      ),
      _featureCard(
        responsive,
        title: 'System Analytics',
        icon: Icons.analytics_rounded,
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.orange.shade700],
        ),
        onTap: () {},
      ),
      _featureCard(
        responsive,
        title: 'Verify Pepper Batches',
        icon: Icons.verified_rounded,
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade700],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VerifyBatchesScreen(),
            ),
          );
        },
      ),
      _featureCard(
        responsive,
        title: 'Market Control',
        icon: Icons.trending_up_rounded,
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade700],
        ),
        onTap: () {},
      ),
      _featureCard(
        responsive,
        title: 'Blockchain Logs',
        icon: Icons.link_rounded,
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade700],
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 20, tablet: 22, desktop: 24),
        ),
        onTap: onTap,
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
                        size: responsive.value(
                          mobile: 28,
                          tablet: 32,
                          desktop: 36,
                        ),
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
