import 'package:flutter/material.dart';
import '../../utils/responsive.dart';
import '../../../widgets/bottom_navigation.dart';
import 'weekly_price_forecast.dart';
import 'export_price_trends.dart';
import 'export_details_by_country.dart';
import 'actual_price_data.dart';

class PriceNavigation extends StatefulWidget {
  const PriceNavigation({Key? key}) : super(key: key);

  @override
  State<PriceNavigation> createState() => _PriceNavigationState();
}

class _PriceNavigationState extends State<PriceNavigation>
    with SingleTickerProviderStateMixin {
  // Animation controller for fade-in effect on screen load
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final Color primary = const Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Market Forecast",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      // Main body with fade transition animation
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: responsive.mediumSpacing),

                // Top description card explaining the feature
                _buildDescriptionCard(responsive),

                SizedBox(height: responsive.largeSpacing),

                // Section title for navigation options
                Text(
                  "Explore Market Data",
                  style: TextStyle(
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(
                  height: responsive.value(mobile: 10, tablet: 12, desktop: 16),
                ),

                // First Navigation Card: Weekly Price Forecast
                _buildNavigationCard(
                  responsive,
                  title: "Weekly Local Price Forecast",
                  subtitle: "View weekly predictions",
                  icon: Icons.trending_up_rounded,
                  gradient: LinearGradient(
                    colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WeeklyPriceForecast(),
                      ),
                    );
                  },
                ),

                SizedBox(height: responsive.mediumSpacing),

                // Second Navigation Card: Export Price Trends
                _buildNavigationCard(
                  responsive,
                  title: "Past Export Price Trends",
                  subtitle: "Analyze trends",
                  icon: Icons.assessment_rounded,
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExportPriceTrends(),
                      ),
                    );
                  },
                ),

                SizedBox(height: responsive.mediumSpacing),

                // Third Navigation Card: Export Details by Country
                _buildNavigationCard(
                  responsive,
                  title: "Export Details by Country",
                  subtitle: "Track global exports",
                  icon: Icons.public_rounded,
                  gradient: LinearGradient(
                    colors: [Color(0xFF81C784), Color(0xFF66BB6A)],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExportDetailsByCountry(),
                      ),
                    );
                  },
                ),

                SizedBox(height: responsive.mediumSpacing),

                // Fourth Navigation Card: Actual Price Data
                _buildNavigationCard(
                  responsive,
                  title: "Actual Market Prices",
                  subtitle: "Enter price details of your pepper batch",
                  icon: Icons.receipt_long_rounded,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActualPriceData(),
                      ),
                    );
                  },
                ),

                SizedBox(height: responsive.largeSpacing),
              ],
            ),
          ),
        ),
      ),
      // Bottom navigation bar for navigating between app sections
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0,
        onTabSelected: (index) {
          // Handle navigation based on index
          if (index != 1) {
            // If not already on Market Forecast tab
            Navigator.pop(
              context,
            ); // Go back and let NavigationWrapper handle it
          }
        },
      ),
    );
  }

  Widget _buildDescriptionCard(Responsive responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFC8E6C9), const Color(0xFFA5D6A7)],
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
              Icons.analytics_rounded,
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
                  'Market Forecast',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize + 2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explore weekly predictions, historical trends, and global export data to make informed trading decisions.',
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize - 1,
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

  Widget _buildNavigationCard(
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
          responsive.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(
              responsive.value(mobile: 16, tablet: 18, desktop: 20),
            ),
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
                  size: responsive.value(mobile: 65, tablet: 75, desktop: 85),
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(
                  responsive.value(mobile: 16, tablet: 18, desktop: 20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        responsive.value(mobile: 8, tablet: 9, desktop: 10),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: responsive.value(
                          mobile: 22,
                          tablet: 26,
                          desktop: 30,
                        ),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(
                      height: responsive.value(
                        mobile: 16,
                        tablet: 18,
                        desktop: 20,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: responsive.value(
                              mobile: 20,
                              tablet: 22,
                              desktop: 24,
                            ),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(
                          height: responsive.value(
                            mobile: 6,
                            tablet: 8,
                            desktop: 10,
                          ),
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: responsive.value(
                                    mobile: 14,
                                    tablet: 15,
                                    desktop: 16,
                                  ),
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Forward arrow icon
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white.withOpacity(0.95),
                              size: responsive.value(
                                mobile: 14,
                                tablet: 16,
                                desktop: 18,
                              ),
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
}
