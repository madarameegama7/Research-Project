import 'package:CeylonPepper/features/market_forecast/screens/export_price_prediction.dart';
import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../widgets/profile_screen.dart';
import '../blockchain/dashboard.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';

class ExporterDashboard extends StatefulWidget {
  const ExporterDashboard({super.key});

  @override
  State<ExporterDashboard> createState() => _ExporterDashboardState();
}

class _ExporterDashboardState extends State<ExporterDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _userName = "Exporter";
  final AuthService _authService = AuthService();

  // Mock data for dashboard statistics
  int _totalBatches = 0;
  int _pendingOrders = 0;
  double _exportRevenue = 0.0;

  @override
  void initState() {
    _loadUserName();
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

    // Load initial data
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadDashboardStats();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardStats() async {
    // Simulate loading dashboard statistics
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _totalBatches = 12; // Mock data - replace with actual data
        _pendingOrders = 3;
        _exportRevenue = 85000.0;
      });
    }
  }

  Future<void> _loadUserName() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final first =
            (user['firstName'] ?? user['first_name'] ?? user['name'] ?? '')
                .toString();
        final last = (user['lastName'] ?? user['last_name'] ?? '').toString();
        final name = (first + (last.isNotEmpty ? ' $last' : '')).trim();
        if (mounted && name.isNotEmpty) {
          setState(() => _userName = name);
          return;
        }
      }
      // fallback to Firebase displayName
      final fb = _authService.currentUser;
      if (fb != null && fb.displayName != null && fb.displayName!.isNotEmpty) {
        if (mounted) setState(() => _userName = fb.displayName!);
      }
    } catch (e) {
      // keep fallback name
      print("Failed to load user name: $e");
    }
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
              await _loadDashboardStats();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced Header
                  _buildHeader(responsive, primary),

                  ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                  // Quick Stats Cards
                  _buildQuickStats(responsive, primary),

                  ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

                  // Section: Export Services
                  _buildSectionTitle(
                    responsive,
                    primary,
                    "Export Services",
                    Icons.local_shipping_rounded,
                  ),

                  ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                  // Main Feature Grid
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildMainFeatureGrid(context, responsive, primary),
                  ),

                  ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),

                  // Section: Export Tips
                  _buildSectionTitle(
                    responsive,
                    primary,
                    "Export Best Practices",
                    Icons.lightbulb_rounded,
                    iconColor: Colors.amber[700],
                  ),

                  ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

                  _buildTipsSection(responsive),

                  ResponsiveSpacing(mobile: 24, tablet: 32, desktop: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Responsive responsive, Color primary) {
    return Container(
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
              // Welcome text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, $_userName 👋",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: responsive.bodyFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    ResponsiveSpacing(mobile: 4, tablet: 6, desktop: 8),
                    Text(
                      "Ceylon Pepper",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.fontSize(
                          mobile: 24,
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

              // Avatar with PopupMenu
              PopupMenuButton<String>(
                offset: Offset(
                  0,
                  responsive.value(mobile: 56, tablet: 60, desktop: 68),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
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
                      Icons.account_circle,
                      color: primary,
                      size: responsive.value(
                        mobile: 32,
                        tablet: 36,
                        desktop: 42,
                      ),
                    ),
                  ),
                ),
                onSelected: (value) async {
                  if (value == 'profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                    return;
                  }

                  if (value == 'logout') {
                    await _authService.logout();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        SizedBox(width: 12),
                        Text("Profile"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20),
                        SizedBox(width: 12),
                        Text("Settings"),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text("Logout", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

          // Location and temperature
          Container(
            padding: responsive.padding(
              mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              tablet: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              desktop: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(
                responsive.value(mobile: 16, tablet: 18, desktop: 20),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: responsive.smallIconSize,
                ),
                ResponsiveSpacing.horizontal(
                  mobile: 8,
                  tablet: 10,
                  desktop: 12,
                ),
                Text(
                  "Sri Lanka",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: responsive.bodyFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.wb_sunny_rounded,
                  color: Colors.amber[300],
                  size: responsive.smallIconSize,
                ),
                ResponsiveSpacing.horizontal(
                  mobile: 8,
                  tablet: 10,
                  desktop: 12,
                ),
                Text(
                  "29°C",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.bodyFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Responsive responsive, Color primary) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
      child: ResponsiveBuilder(
        mobile: _buildStatsRow(responsive, primary),
        tablet: _buildStatsRow(responsive, primary),
        desktop: _buildStatsRow(responsive, primary),
      ),
    );
  }

  Widget _buildStatsRow(Responsive responsive, Color primary) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            responsive,
            "Export Batches",
            _totalBatches.toString(),
            Icons.inventory_2_rounded,
            Colors.indigo.shade600,
            Colors.indigo.shade50,
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 12, tablet: 16, desktop: 20),
        Expanded(
          child: _buildStatCard(
            responsive,
            "Pending Orders",
            _pendingOrders.toString(),
            Icons.pending_actions_rounded,
            Colors.orange.shade600,
            Colors.orange.shade50,
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 12, tablet: 16, desktop: 20),
        Expanded(
          child: _buildStatCard(
            responsive,
            "Total Revenue",
            "\$${(_exportRevenue / 1000).toStringAsFixed(1)}K",
            Icons.attach_money_rounded,
            Colors.green.shade600,
            Colors.green.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    Responsive responsive,
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(18),
        desktop: const EdgeInsets.all(20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(
              responsive.value(mobile: 8, tablet: 10, desktop: 12),
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: responsive.mediumIconSize,
            ),
          ),
          ResponsiveSpacing(mobile: 8, tablet: 10, desktop: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.titleFontSize,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          ResponsiveSpacing(mobile: 2, tablet: 4, desktop: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 12,
                tablet: 13,
                desktop: 14,
              ),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    Responsive responsive,
    Color primary,
    String title,
    IconData icon, {
    Color? iconColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
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
          ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: responsive.headingFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          Icon(
            icon,
            color: iconColor ?? primary,
            size: responsive.mediumIconSize,
          ),
        ],
      ),
    );
  }

  Widget _buildMainFeatureGrid(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
      child: ResponsiveBuilder(
        mobile: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.95,
          physics: const NeverScrollableScrollPhysics(),
          children: _buildMainFeatureCards(context, responsive),
        ),
        tablet: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.0,
          physics: const NeverScrollableScrollPhysics(),
          children: _buildMainFeatureCards(context, responsive),
        ),
        desktop: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          crossAxisSpacing: 22,
          mainAxisSpacing: 22,
          childAspectRatio: 0.95,
          physics: const NeverScrollableScrollPhysics(),
          children: _buildMainFeatureCards(context, responsive),
        ),
      ),
    );
  }

  List<Widget> _buildMainFeatureCards(
    BuildContext context,
    Responsive responsive,
  ) {
    return [
      _featureCard(
        context,
        responsive,
        title: "Export\nPrices",
        subtitle: "Market trends",
        icon: Icons.trending_up_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExportPricePrediction(),
            ),
          );
        },
      ),
      _featureCard(
        context,
        responsive,
        title: "Quality\nRequests",
        subtitle: "Certifications",
        icon: Icons.verified_user_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        onTap: () {},
      ),
      _featureCard(
        context,
        responsive,
        title: "Export\nBatches",
        subtitle: "Shipments",
        icon: Icons.inventory_2_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF81C784), Color(0xFF66BB6A)],
        ),
        onTap: () {},
      ),
      _featureCard(
        context,
        responsive,
        title: "Traceability",
        subtitle: "Blockchain",
        icon: Icons.qr_code_rounded,
        gradient: LinearGradient(
          colors: [Color(0xFF388E3C), Color(0xFF2E7D32)],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BlockchainDashboard(),
            ),
          );
        },
      ),
    ];
  }

  Widget _featureCard(
    BuildContext context,
    Responsive responsive, {
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
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 20, tablet: 22, desktop: 24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(
              responsive.value(mobile: 20, tablet: 22, desktop: 24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(
                  icon,
                  size: responsive.value(mobile: 80, tablet: 90, desktop: 100),
                  color: Colors.white.withOpacity(0.12),
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
                        size: responsive.value(
                          mobile: 28,
                          tablet: 32,
                          desktop: 36,
                        ),
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    ResponsiveSpacing(mobile: 4, tablet: 5, desktop: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    ResponsiveSpacing(mobile: 8, tablet: 10, desktop: 12),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withOpacity(0.9),
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

  Widget _buildTipsSection(Responsive responsive) {
    return SizedBox(
      height: responsive.value(mobile: 140, tablet: 160, desktop: 180),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
        children: [
          _tipCard(
            "Maintain strict quality standards",
            Icons.verified_rounded,
            Colors.green.shade50,
            Colors.green.shade700,
            responsive,
          ),
          _tipCard(
            "Check global market demand",
            Icons.public_rounded,
            Colors.blue.shade50,
            Colors.blue.shade700,
            responsive,
          ),
          _tipCard(
            "Ensure export documentation accuracy",
            Icons.assignment_rounded,
            Colors.orange.shade50,
            Colors.orange.shade700,
            responsive,
          ),
          _tipCard(
            "Monitor competitor pricing weekly",
            Icons.trending_up_rounded,
            Colors.purple.shade50,
            Colors.purple.shade700,
            responsive,
          ),
        ],
      ),
    );
  }

  Widget _tipCard(
    String text,
    IconData icon,
    Color bgColor,
    Color iconColor,
    Responsive responsive,
  ) {
    return Container(
      margin: EdgeInsets.only(
        right: responsive.value(mobile: 16, tablet: 18, desktop: 20),
      ),
      padding: responsive.padding(
        mobile: const EdgeInsets.all(18),
        tablet: const EdgeInsets.all(20),
        desktop: const EdgeInsets.all(24),
      ),
      width: responsive.value(mobile: 200, tablet: 220, desktop: 240),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 20, tablet: 22, desktop: 24),
        ),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: responsive.padding(
              mobile: const EdgeInsets.all(10),
              tablet: const EdgeInsets.all(11),
              desktop: const EdgeInsets.all(12),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: responsive.mediumIconSize,
            ),
          ),
          ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: responsive.bodyFontSize,
              color: Colors.grey[800],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
