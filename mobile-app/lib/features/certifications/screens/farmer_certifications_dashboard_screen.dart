import 'package:flutter/material.dart';
import '../../../config/api.dart';
import '../models/certification_model.dart';
import '../services/certification_api.dart';
import 'farmer_add_certifications_screen.dart';
import 'farmer_certification_details_screen.dart';
import '../../../utils/responsive.dart';

// Helper to create a Color from an existing Color with a custom opacity (0.0-1.0)
Color colorWithOpacity(Color c, double opacity) {
  final alpha = (opacity * 255).round().clamp(0, 255);
  return c.withAlpha(alpha);
}

class FarmerCertificationsDashboardScreen extends StatefulWidget {
  const FarmerCertificationsDashboardScreen({super.key});

  @override
  State<FarmerCertificationsDashboardScreen> createState() =>
      _FarmerCertificationsDashboardScreenState();
}

class _FarmerCertificationsDashboardScreenState
    extends State<FarmerCertificationsDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF2E7D32);

  final _searchCtrl = TextEditingController();
  String _statusFilter = 'All';
  String _sortMode = 'Newest';

  bool _loading = true;
  String? _error;
  List<CertificationModel> _items = [];

  late final CertificationApi _api;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _api = CertificationApi(baseUrl: ApiConfig.baseUrl);

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

    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  String _mapUiStatusToApiStatus(String ui) {
    final s = ui.toLowerCase();
    if (s == 'pending' || s == 'verified' || s == 'rejected') return s;
    return 'all';
  }

  String _mapUiSortToApiSort(String ui) {
    final s = ui.toLowerCase();
    if (s.contains('oldest')) return 'oldest';
    if (s.contains('expiry')) return 'expiry';
    return 'newest';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final apiStatus = _mapUiStatusToApiStatus(_statusFilter);
      final sort = _mapUiSortToApiSort(_sortMode);

      final list = await _api.getMyCertifications(
        status: apiStatus == 'all' ? null : apiStatus,
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        sort: sort,
      );

      List<CertificationModel> finalList = list;

      final status = _statusFilter.toLowerCase();

      if (status == 'expired') {
        finalList = list.where((e) => e.isExpired).toList();
      } else if (status == 'all') {
        finalList = list;
      } else if (['pending', 'verified', 'rejected'].contains(status)) {
        finalList = list
            .where((e) => !e.isExpired && e.status == status)
            .toList();
      }

      setState(() {
        _items = finalList;
        _loading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openAdd() async {
    final created = await Navigator.push<CertificationModel>(
      context,
      MaterialPageRoute(
        builder: (_) => FarmerAddCertificationScreen(api: _api),
      ),
    );

    if (created != null) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Certificate submitted'),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _openDetails(CertificationModel model) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FarmerCertificationDetailsScreen(certId: model.id, api: _api),
      ),
    );
    if (changed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header matching dashboard style
            _buildHeader(responsive),

            // Search + filters
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.value(mobile: 16, tablet: 24, desktop: 32),
                responsive.value(mobile: 16, tablet: 20, desktop: 24),
                responsive.value(mobile: 16, tablet: 24, desktop: 32),
                0,
              ),
              child: _buildSearchAndFilters(responsive),
            ),

            ResponsiveSpacing(mobile: 12, tablet: 16, desktop: 20),

            // Content
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_primary),
                      ),
                    )
                  : _error != null
                  ? _errorState(responsive)
                  : _items.isEmpty
                  ? _emptyState(responsive)
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: RefreshIndicator(
                          onRefresh: _load,
                          color: _primary,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.value(
                                mobile: 16,
                                tablet: 24,
                                desktop: 32,
                              ),
                              vertical: responsive.value(
                                mobile: 4,
                                tablet: 6,
                                desktop: 8,
                              ),
                            ),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => ResponsiveSpacing(
                              mobile: 12,
                              tablet: 14,
                              desktop: 16,
                            ),
                            itemBuilder: (context, index) {
                              final c = _items[index];
                              return _certCard(
                                c,
                                responsive,
                                () => _openDetails(c),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add New',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: responsive.fontSize(mobile: 14, tablet: 15, desktop: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Responsive responsive) {
    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        tablet: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        desktop: const EdgeInsets.fromLTRB(40, 28, 40, 36),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primary, colorWithOpacity(_primary, 0.85)],
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
            color: colorWithOpacity(_primary, 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(
                responsive.value(mobile: 8, tablet: 10, desktop: 12),
              ),
              decoration: BoxDecoration(
                color: colorWithOpacity(Colors.white, 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
              ),
            ),
          ),

          ResponsiveSpacing.horizontal(mobile: 14, tablet: 16, desktop: 18),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Certifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.fontSize(
                      mobile: 20,
                      tablet: 24,
                      desktop: 28,
                    ),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_items.length} certificate${_items.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: colorWithOpacity(Colors.white, 0.8),
                    fontSize: responsive.fontSize(
                      mobile: 12,
                      tablet: 13,
                      desktop: 14,
                    ),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Refresh button
          GestureDetector(
            onTap: _load,
            child: Container(
              padding: EdgeInsets.all(
                responsive.value(mobile: 8, tablet: 10, desktop: 12),
              ),
              decoration: BoxDecoration(
                color: colorWithOpacity(Colors.white, 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(Responsive responsive) {
    return Column(
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              responsive.value(mobile: 14, tablet: 16, desktop: 18),
            ),
            boxShadow: [
              BoxShadow(
                color: colorWithOpacity(Colors.black, 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchCtrl,
            onSubmitted: (_) => _load(),
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 14,
                tablet: 15,
                desktop: 16,
              ),
            ),
            decoration: InputDecoration(
              hintText: 'Search by type, number, issuing body...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: responsive.fontSize(
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _primary,
                size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
              ),
              suffixIcon: GestureDetector(
                onTap: _load,
                child: Icon(
                  Icons.tune_rounded,
                  color: _primary,
                  size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
                ),
              ),
              filled: false,
              contentPadding: EdgeInsets.symmetric(
                vertical: responsive.value(mobile: 14, tablet: 16, desktop: 18),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.value(mobile: 14, tablet: 16, desktop: 18),
                ),
                borderSide: BorderSide(
                  color: colorWithOpacity(_primary, 0.15),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.value(mobile: 14, tablet: 16, desktop: 18),
                ),
                borderSide: BorderSide(
                  color: colorWithOpacity(_primary, 0.15),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  responsive.value(mobile: 14, tablet: 16, desktop: 18),
                ),
                borderSide: const BorderSide(color: _primary, width: 2),
              ),
            ),
          ),
        ),

        ResponsiveSpacing(mobile: 10, tablet: 12, desktop: 14),

        // Filter dropdowns
        Row(
          children: [
            Expanded(
              child: _dropdownBox(
                responsive,
                value: _statusFilter,
                items: const [
                  'All',
                  'Pending',
                  'Verified',
                  'Rejected',
                  'Expired',
                ],
                icon: Icons.filter_list_rounded,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _statusFilter = v);
                  _load();
                },
              ),
            ),
            ResponsiveSpacing.horizontal(mobile: 10, tablet: 12, desktop: 14),
            Expanded(
              child: _dropdownBox(
                responsive,
                value: _sortMode,
                items: const ['Newest', 'Oldest', 'Expiry soon'],
                icon: Icons.sort_rounded,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _sortMode = v);
                  _load();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dropdownBox(
    Responsive responsive, {
    required String value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(mobile: 10, tablet: 12, desktop: 14),
        vertical: responsive.value(mobile: 2, tablet: 3, desktop: 4),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 12, tablet: 14, desktop: 16),
        ),
        border: Border.all(color: colorWithOpacity(_primary, 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorWithOpacity(Colors.black, 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _primary,
            size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
          ),
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: responsive.fontSize(mobile: 13, tablet: 14, desktop: 15),
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: colorWithOpacity(_primary, 0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(e),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _errorState(Responsive responsive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          responsive.value(mobile: 24, tablet: 32, desktop: 40),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(
                responsive.value(mobile: 20, tablet: 24, desktop: 28),
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: responsive.value(mobile: 48, tablet: 56, desktop: 64),
                color: Colors.red.shade400,
              ),
            ),
            ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),
            Text(
              'Failed to load',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: responsive.fontSize(
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: responsive.fontSize(
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
              ),
            ),
            ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.value(
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                  vertical: responsive.value(
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
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

  Widget _emptyState(Responsive responsive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          responsive.value(mobile: 24, tablet: 32, desktop: 40),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(
                responsive.value(mobile: 20, tablet: 24, desktop: 28),
              ),
              decoration: BoxDecoration(
                color: colorWithOpacity(_primary, 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_outlined,
                size: responsive.value(mobile: 48, tablet: 56, desktop: 64),
                color: colorWithOpacity(_primary, 0.5),
              ),
            ),
            ResponsiveSpacing(mobile: 16, tablet: 20, desktop: 24),
            Text(
              'No certifications found',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: responsive.fontSize(
                  mobile: 18,
                  tablet: 20,
                  desktop: 22,
                ),
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first certificate to get started',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: responsive.fontSize(
                  mobile: 13,
                  tablet: 14,
                  desktop: 15,
                ),
              ),
            ),
            ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),
            ElevatedButton.icon(
              onPressed: _openAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add New Certificate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.value(
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                  vertical: responsive.value(
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
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

  Widget _certCard(
    CertificationModel c,
    Responsive responsive,
    VoidCallback onTap,
  ) {
    final displayStatus = c.effectiveStatus;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          responsive.value(mobile: 16, tablet: 18, desktop: 20),
        ),
        child: Container(
          padding: responsive.padding(
            mobile: const EdgeInsets.all(14),
            tablet: const EdgeInsets.all(18),
            desktop: const EdgeInsets.all(20),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              responsive.value(mobile: 16, tablet: 18, desktop: 20),
            ),
            border: Border.all(
              color: colorWithOpacity(_primary, 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colorWithOpacity(Colors.black, 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(
                  responsive.value(mobile: 10, tablet: 12, desktop: 14),
                ),
                decoration: BoxDecoration(
                  color: colorWithOpacity(_primary, 0.08),
                  borderRadius: BorderRadius.circular(
                    responsive.value(mobile: 12, tablet: 14, desktop: 16),
                  ),
                ),
                child: Icon(
                  Icons.verified_outlined,
                  color: _primary,
                  size: responsive.value(mobile: 22, tablet: 24, desktop: 26),
                ),
              ),

              ResponsiveSpacing.horizontal(mobile: 12, tablet: 14, desktop: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            c.certificationType,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: responsive.fontSize(
                                mobile: 14,
                                tablet: 15,
                                desktop: 16,
                              ),
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusChip(displayStatus, responsive),
                      ],
                    ),

                    ResponsiveSpacing(mobile: 6, tablet: 7, desktop: 8),

                    // Certificate number
                    Text(
                      'No: ${c.certificateNumber}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: responsive.fontSize(
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Issuing body
                    Text(
                      c.issuingBody,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: responsive.fontSize(
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    ResponsiveSpacing(mobile: 10, tablet: 12, desktop: 14),

                    // Meta chips
                    Wrap(
                      spacing: responsive.value(
                        mobile: 6,
                        tablet: 8,
                        desktop: 10,
                      ),
                      runSpacing: responsive.value(
                        mobile: 6,
                        tablet: 8,
                        desktop: 10,
                      ),
                      children: [
                        _metaChip(
                          Icons.schedule_outlined,
                          'Submitted: ${_formatDate(c.createdAt)}',
                          responsive,
                        ),
                        _metaChip(
                          Icons.event_available_outlined,
                          'Expiry: ${_formatDate(c.expiryDate)}',
                          responsive,
                        ),
                        if (c.rejectionReason != null &&
                            c.rejectionReason!.isNotEmpty &&
                            c.status == 'rejected')
                          _metaChip(
                            Icons.info_outline,
                            'Reason: ${c.rejectionReason}',
                            responsive,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text, Responsive responsive) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(mobile: 9, tablet: 10, desktop: 12),
        vertical: responsive.value(mobile: 5, tablet: 6, desktop: 7),
      ),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: responsive.value(mobile: 13, tablet: 14, desktop: 15),
            color: Colors.grey[600],
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 11,
                tablet: 12,
                desktop: 13,
              ),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, Responsive responsive) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;

    if (s.contains('pending')) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    } else if (s.contains('verified')) {
      bg = colorWithOpacity(_primary, 0.08);
      fg = _primary;
    } else if (s.contains('expired')) {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
    } else {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.value(mobile: 9, tablet: 10, desktop: 12),
        vertical: responsive.value(mobile: 4, tablet: 5, desktop: 6),
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorWithOpacity(fg, 0.3)),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: fg,
          fontSize: responsive.fontSize(mobile: 11, tablet: 12, desktop: 13),
        ),
      ),
    );
  }
}
