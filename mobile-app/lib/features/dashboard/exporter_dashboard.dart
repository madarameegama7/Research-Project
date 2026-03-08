import 'package:CeylonPepper/features/market_forecast/screens/export_price_prediction.dart';
import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../blockchain/screens/dashboard.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';

// Helper to create a Color from an existing Color with a custom opacity (0.0-1.0)
Color colorWithOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

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
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _totalBatches = 12;
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
      final fb = _authService.currentUser;
      if (fb != null && fb.displayName != null && fb.displayName!.isNotEmpty) {
        if (mounted) setState(() => _userName = fb.displayName!);
      }
    } catch (e) {
      print("Failed to load user name: $e");
    }
  }

  // ── Logout Confirmation Dialog (same as Farmer Dashboard) ────────────────
  void _showLogoutDialog(BuildContext context, Color primary) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorWithOpacity(primary, 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_rounded, color: primary, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                _userName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to log out?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _authService.logout();
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                  _buildHeader(responsive, primary),
                  ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),
                  _buildQuickStats(responsive, primary),
                  ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
                  _buildSectionTitle(
                    responsive,
                    primary,
                    "Export Services",
                    Icons.local_shipping_rounded,
                  ),
                  ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildMainFeatureGrid(context, responsive, primary),
                  ),
                  ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
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
          colors: [primary, colorWithOpacity(primary, 0.85)],
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
            color: colorWithOpacity(primary, 0.3),
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
                      "Welcome 👋",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
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

              // ── Avatar → tapping shows logout dialog (same as Farmer Dashboard) ──
              GestureDetector(
                onTap: () => _showLogoutDialog(context, primary),
                child: Container(
                  padding: EdgeInsets.all(
                    responsive.value(mobile: 2, tablet: 3, desktop: 4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: responsive.value(
                      mobile: 22,
                      tablet: 26,
                      desktop: 30,
                    ),
                    backgroundColor: colorWithOpacity(primary, 0.1),
                    child: Icon(
                      Icons.person_rounded,
                      color: primary,
                      size: responsive.value(
                        mobile: 26,
                        tablet: 30,
                        desktop: 34,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

          // Location and temperature strip
          Container(
            padding: responsive.padding(
              mobile: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              tablet: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              desktop: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            decoration: BoxDecoration(
              color: colorWithOpacity(Colors.white, 0.15),
              borderRadius: BorderRadius.circular(
                responsive.value(mobile: 16, tablet: 18, desktop: 20),
              ),
              border: Border.all(
                color: colorWithOpacity(Colors.white, 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
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
                    color: Colors.white.withValues(alpha: 0.9),
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
      child: _buildStatsRow(responsive, primary),
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
            color: colorWithOpacity(Colors.black, 0.05),
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
          crossAxisCount: 2, // Only 2 cards now, so 2 columns looks better
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
        iconColor: Colors.green.shade700,
        iconBgColor: Colors.green.shade50,
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
        title: "Traceability",
        subtitle: "Blockchain",
        icon: Icons.qr_code_rounded,
        iconColor: Colors.teal.shade700,
        iconBgColor: Colors.teal.shade50,
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
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 20, desktop: 24),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 248, 250, 248),
                Color.fromARGB(255, 239, 242, 239),
              ],
            ),
            borderRadius: BorderRadius.circular(
              responsive.value(mobile: 16, tablet: 20, desktop: 24),
            ),
            boxShadow: [
              BoxShadow(
                color: colorWithOpacity(Colors.black, 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: responsive.padding(
              mobile: const EdgeInsets.all(12),
              tablet: const EdgeInsets.all(16),
              desktop: const EdgeInsets.all(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container — colored background like farmer dashboard
                    Container(
                      padding: responsive.padding(
                        mobile: const EdgeInsets.all(8),
                        tablet: const EdgeInsets.all(10),
                        desktop: const EdgeInsets.all(12),
                      ),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: responsive.value(
                          mobile: 32,
                          tablet: 42,
                          desktop: 48,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: responsive.value(
                        mobile: 8,
                        tablet: 10,
                        desktop: 12,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                          mobile: 13,
                          tablet: 15,
                          desktop: 16,
                        ),
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(
                      height: responsive.value(
                        mobile: 3,
                        tablet: 4,
                        desktop: 5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: responsive.fontSize(
                          mobile: 10,
                          tablet: 11,
                          desktop: 12,
                        ),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: responsive.value(mobile: 16, tablet: 18, desktop: 20),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
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
        border: Border.all(color: colorWithOpacity(iconColor, 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(Colors.black, 0.05),
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
                  color: colorWithOpacity(iconColor, 0.2),
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
