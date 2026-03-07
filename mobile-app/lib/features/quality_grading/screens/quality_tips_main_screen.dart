import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import 'quality_tip_detail_screen.dart';

class QualityTipsMainScreen extends StatefulWidget {
  const QualityTipsMainScreen({super.key});

  @override
  State<QualityTipsMainScreen> createState() => _QualityTipsMainScreenState();
}

class _QualityTipsMainScreenState extends State<QualityTipsMainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          "Quality Tips",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(responsive.pagePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories Grid
                Text(
                  "Explore Quality Factors",
                  style: TextStyle(
                    fontSize: responsive.titleFontSize,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: responsive.value(mobile: 12, tablet: 14, desktop: 16)),
                _buildCategoriesGrid(context, responsive),

                SizedBox(height: responsive.value(mobile: 24, tablet: 28, desktop: 32)),

                // Quick Tips Section
                _buildQuickTipsSection(responsive),

                SizedBox(height: responsive.value(mobile: 24, tablet: 28, desktop: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context, Responsive responsive) {
    final categories = [
      {
        'title': 'Variety &\nPiperine',
        'icon': Icons.spa_rounded,
        'color': const Color(0xFF10B981),
        'route': 'variety',
      },
      {
        'title': 'Color\nUniformity',
        'icon': Icons.palette_rounded,
        'color': const Color(0xFFf59e0b),
        'route': 'color',
      },
      {
        'title': 'Size & Shape\nConsistency',
        'icon': Icons.straighten_rounded,
        'color': const Color(0xFF3B82F6),
        'route': 'size',
      },
      {
        'title': 'Mold\nPrevention',
        'icon': Icons.health_and_safety_rounded,
        'color': const Color(0xFFEF4444),
        'route': 'mold',
      },
      {
        'title': 'Drying\nProcess',
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFFF59E0B),
        'route': 'drying',
      },
      {
        'title': 'Storage\nTips',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF8B5CF6),
        'route': 'storage',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = responsive.value(mobile: 2, tablet: 3, desktop: 4).toInt();
        final spacing = responsive.value(mobile: 12, tablet: 14, desktop: 16);
        final itemWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final itemHeight = responsive.value(mobile: 160, tablet: 175, desktop: 180);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: categories.map((category) {
            return SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: _buildCategoryCard(
                context,
                responsive,
                title: category['title'] as String,
                icon: category['icon'] as IconData,
                color: category['color'] as Color,
                route: category['route'] as String,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Responsive responsive, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QualityTipDetailScreen(category: route),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 100,
                  color: color.withOpacity(0.08),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(responsive.value(mobile: 14, tablet: 16, desktop: 18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: responsive.value(mobile: 15, tablet: 16, desktop: 17),
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                        height: 1.2,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Learn more",
                          style: TextStyle(
                            fontSize: responsive.value(mobile: 12, tablet: 13, desktop: 14),
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: color, size: 14),
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

  Widget _buildQuickTipsSection(Responsive responsive) {
    final quickTips = [
      {
        'icon': Icons.check_circle_rounded,
        'text': 'Sun dry for 3-4 days for optimal quality',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.check_circle_rounded,
        'text': 'Remove light berries before packaging',
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.check_circle_rounded,
        'text': 'Store in cool, dry place to prevent mold',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'icon': Icons.check_circle_rounded,
        'text': 'Get GAP certification for premium prices',
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Container(
      padding: EdgeInsets.all(responsive.value(mobile: 18, tablet: 20, desktop: 22)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.tips_and_updates_rounded,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Quick Tips",
                style: TextStyle(
                  fontSize: responsive.value(mobile: 18, tablet: 20, desktop: 22),
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.value(mobile: 14, tablet: 16, desktop: 18)),
          ...quickTips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      tip['icon'] as IconData,
                      color: tip['color'] as Color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip['text'] as String,
                        style: TextStyle(
                          fontSize: responsive.value(mobile: 14, tablet: 15, desktop: 16),
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}