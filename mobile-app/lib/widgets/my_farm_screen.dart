import 'package:flutter/material.dart';
import '../services/farmer_service.dart';
import '../models/farm_plot.dart';
import '../utils/responsive.dart';

Color colorWithOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

class MyFarmScreen extends StatefulWidget {
  const MyFarmScreen({super.key});

  @override
  State<MyFarmScreen> createState() => _MyFarmScreenState();
}

class _MyFarmScreenState extends State<MyFarmScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF2E7D32);

  final FarmerService _service = FarmerService();
  bool _loading = true;
  String? _error;
  List<FarmPlot> _plots = [];

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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _loadPlots();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPlots() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchPlots();
      if (mounted) {
        setState(() => _plots = data);
        _animationController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load plots: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadPlots,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showPlotForm([FarmPlot? plot]) async {
    final nameCtrl = TextEditingController(text: plot?.name ?? '');
    final cropCtrl = TextEditingController(text: plot?.crop ?? '');
    final areaCtrl = TextEditingController(
      text: plot != null ? plot.area.toString() : '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorWithOpacity(_primary, 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                plot == null
                    ? Icons.add_location_alt_outlined
                    : Icons.edit_outlined,
                color: _primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              plot == null ? 'Add New Plot' : 'Edit Plot',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(
                  nameCtrl,
                  'Plot Location',
                  Icons.label_outline,
                  hint: 'e.g., Kegalle',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Plot name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                _dialogField(
                  cropCtrl,
                  'Crop Type',
                  Icons.grass_outlined,
                  hint: 'e.g., Black Pepper',
                ),
                const SizedBox(height: 14),
                _dialogField(
                  areaCtrl,
                  'Area (hectares)',
                  Icons.straighten_outlined,
                  hint: '0.0',
                  suffixText: 'ha',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Area is required';
                    final n = double.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Enter a valid area';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final body = {
                'name': nameCtrl.text.trim(),
                'crop': cropCtrl.text.trim(),
                'area': double.tryParse(areaCtrl.text.trim()) ?? 0.0,
              };
              Navigator.pop(ctx);
              try {
                if (plot == null) {
                  await _service.createPlot(body);
                } else {
                  await _service.updatePlot(plot.id, body);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        plot == null
                            ? 'Plot added successfully'
                            : 'Plot updated successfully',
                      ),
                      backgroundColor: _primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                  await _loadPlots();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(plot == null ? 'Add Plot' : 'Save'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    cropCtrl.dispose();
    areaCtrl.dispose();
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    String? suffixText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffixText,
        prefixIcon: Icon(icon, color: _primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  Future<void> _confirmDelete(FarmPlot plot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Plot',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('Are you sure you want to delete "${plot.name}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // await _service.deletePlot(plot.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Plot deleted'),
              backgroundColor: _primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          await _loadPlots();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  double get _totalArea => _plots.fold(0.0, (sum, p) => sum + p.area);

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            onRefresh: _loadPlots,
            color: _primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────
                  _buildHeader(r),

                  ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),

                  // ── Content ──────────────────────────────────────────
                  _buildContent(r),

                  ResponsiveSpacing(mobile: 80, tablet: 88, desktop: 96),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _plots.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showPlotForm(),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text(
                'Add Plot',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(Responsive r) {
    return Container(
      padding: r.padding(
        mobile: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        tablet: const EdgeInsets.fromLTRB(32, 24, 32, 36),
        desktop: const EdgeInsets.fromLTRB(40, 28, 40, 42),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, colorWithOpacity(_primary, 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(
            r.value(mobile: 28, tablet: 36, desktop: 40),
          ),
          bottomRight: Radius.circular(
            r.value(mobile: 28, tablet: 36, desktop: 40),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(_primary, 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Farm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: r.fontSize(mobile: 26, tablet: 30, desktop: 34),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your farm plots',
                  style: TextStyle(
                    color: colorWithOpacity(Colors.white, 0.80),
                    fontSize: r.fontSize(mobile: 13, tablet: 14, desktop: 15),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.agriculture_rounded,
            size: r.value(mobile: 64, tablet: 80, desktop: 96),
            color: colorWithOpacity(Colors.white, 0.15),
          ),
        ],
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────

  Widget _buildSectionTitle(Responsive r, String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: r.value(mobile: 16, tablet: 24, desktop: 32),
      ),
      child: Row(
        children: [
          Container(
            width: r.value(mobile: 4, tablet: 5, desktop: 6),
            height: r.value(mobile: 20, tablet: 22, desktop: 24),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ResponsiveSpacing.horizontal(mobile: 10, tablet: 12, desktop: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: r.fontSize(mobile: 17, tablet: 20, desktop: 22),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          Icon(
            icon,
            color: _primary,
            size: r.value(mobile: 22, tablet: 24, desktop: 26),
          ),
        ],
      ),
    );
  }

  // ── Content states ─────────────────────────────────────────────────────

  Widget _buildContent(Responsive r) {
    if (_loading) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primary),
          ),
        ),
      );
    }
    if (_error != null) return _buildErrorState(r);
    if (_plots.isEmpty) return _buildEmptyState(r);

    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary cards ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.value(mobile: 16, tablet: 24, desktop: 32),
            ),
            child: _buildSummaryRow(r),
          ),

          ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),

          // ── Section title ────────────────────────────────────────
          _buildSectionTitle(r, 'Farm Plots', Icons.grid_view_rounded),

          ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),

          // ── Plot list ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: r.value(mobile: 16, tablet: 24, desktop: 32),
            ),
            child: Column(
              children: _plots.map((plot) => _buildPlotCard(plot, r)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary row — matches Dashboard's quick-stats row ──────────────────

  Widget _buildSummaryRow(Responsive r) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            r,
            Icons.grid_on_rounded,
            'Total Plots',
            _plots.length.toString(),
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 12, tablet: 16, desktop: 20),
        Expanded(
          child: _buildStatCard(
            r,
            Icons.landscape_rounded,
            'Total Area',
            '${_totalArea.toStringAsFixed(1)} ha',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    Responsive r,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: r.padding(
        mobile: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        tablet: const EdgeInsets.all(18),
        desktop: const EdgeInsets.all(20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          r.value(mobile: 14, tablet: 18, desktop: 20),
        ),
        border: Border.all(color: colorWithOpacity(_primary, 0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              r.value(mobile: 10, tablet: 12, desktop: 14),
            ),
            decoration: BoxDecoration(
              color: colorWithOpacity(_primary, 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _primary,
              size: r.value(mobile: 22, tablet: 24, desktop: 26),
            ),
          ),
          SizedBox(width: r.value(mobile: 12, tablet: 14, desktop: 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: r.fontSize(mobile: 20, tablet: 22, desktop: 24),
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: r.fontSize(mobile: 11, tablet: 12, desktop: 13),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Plot card ──────────────────────────────────────────────────────────

  Widget _buildPlotCard(FarmPlot plot, Responsive r) {
    return Container(
      margin: EdgeInsets.only(
        bottom: r.value(mobile: 12, tablet: 14, desktop: 16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          r.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        border: Border.all(color: colorWithOpacity(_primary, 0.12), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(Colors.black, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            r.value(mobile: 16, tablet: 18, desktop: 20),
          ),
          onTap: () => _showPlotForm(plot),
          child: Padding(
            padding: EdgeInsets.all(
              r.value(mobile: 14, tablet: 16, desktop: 18),
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  padding: EdgeInsets.all(
                    r.value(mobile: 12, tablet: 14, desktop: 16),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary, colorWithOpacity(_primary, 0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(
                      r.value(mobile: 14, tablet: 16, desktop: 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorWithOpacity(_primary, 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.agriculture_rounded,
                    size: r.value(mobile: 28, tablet: 32, desktop: 36),
                    color: Colors.white,
                  ),
                ),

                SizedBox(width: r.value(mobile: 14, tablet: 16, desktop: 18)),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plot.name,
                        style: TextStyle(
                          fontSize: r.fontSize(
                            mobile: 15,
                            tablet: 16,
                            desktop: 17,
                          ),
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.grass_outlined,
                            size: r.value(mobile: 14, tablet: 15, desktop: 16),
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              plot.crop.isNotEmpty ? plot.crop : 'No crop',
                              style: TextStyle(
                                fontSize: r.fontSize(
                                  mobile: 12,
                                  tablet: 13,
                                  desktop: 14,
                                ),
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(
                            width: r.value(mobile: 12, tablet: 14, desktop: 16),
                          ),
                          Icon(
                            Icons.straighten_outlined,
                            size: r.value(mobile: 14, tablet: 15, desktop: 16),
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${plot.area} ha',
                            style: TextStyle(
                              fontSize: r.fontSize(
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                              color: _primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionBtn(
                      icon: Icons.edit_outlined,
                      color: _primary,
                      bgColor: colorWithOpacity(_primary, 0.08),
                      size: r.value(mobile: 18, tablet: 20, desktop: 22),
                      onPressed: () => _showPlotForm(plot),
                    ),
                    SizedBox(
                      height: r.value(mobile: 6, tablet: 8, desktop: 10),
                    ),
                    _actionBtn(
                      icon: Icons.delete_outline,
                      color: Colors.redAccent,
                      bgColor: colorWithOpacity(Colors.redAccent, 0.08),
                      size: r.value(mobile: 18, tablet: 20, desktop: 22),
                      onPressed: () => _confirmDelete(plot),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double size,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }

  // ── Error state ────────────────────────────────────────────────────────

  Widget _buildErrorState(Responsive r) {
    return Padding(
      padding: EdgeInsets.all(r.largeSpacing),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(
                r.value(mobile: 20, tablet: 24, desktop: 28),
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: r.value(mobile: 48, tablet: 56, desktop: 64),
                color: Colors.red.shade300,
              ),
            ),
            SizedBox(height: r.mediumSpacing),
            Text(
              'Failed to load farm data',
              style: TextStyle(
                fontSize: r.titleFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: r.smallSpacing),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: r.bodyFontSize,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: r.largeSpacing),
            ElevatedButton.icon(
              onPressed: _loadPlots,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Try Again',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: r.largeSpacing,
                  vertical: r.mediumSpacing,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────

  Widget _buildEmptyState(Responsive r) {
    return Padding(
      padding: EdgeInsets.all(r.largeSpacing),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(
                r.value(mobile: 24, tablet: 28, desktop: 32),
              ),
              decoration: BoxDecoration(
                color: colorWithOpacity(_primary, 0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.park_outlined,
                size: r.value(mobile: 56, tablet: 68, desktop: 80),
                color: colorWithOpacity(_primary, 0.4),
              ),
            ),
            SizedBox(height: r.largeSpacing),
            Text(
              'No plots yet',
              style: TextStyle(
                fontSize: r.headingFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: r.smallSpacing),
            Text(
              'Start by adding your first plot',
              style: TextStyle(
                fontSize: r.bodyFontSize,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: r.largeSpacing),
            ElevatedButton.icon(
              onPressed: () => _showPlotForm(),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text(
                'Add Plot',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: r.largeSpacing,
                  vertical: r.mediumSpacing,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
