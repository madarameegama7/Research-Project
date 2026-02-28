import 'package:flutter/material.dart';
import '../../../services/market_forecast/actual_price_data_service.dart';
import 'verify_batch_details.dart';
import '../../../utils/responsive.dart';

class VerifyBatchesScreen extends StatefulWidget {
  const VerifyBatchesScreen({Key? key}) : super(key: key);

  @override
  State<VerifyBatchesScreen> createState() => _VerifyBatchesScreenState();
}

class _VerifyBatchesScreenState extends State<VerifyBatchesScreen> {
  final ActualPriceDataService _service = ActualPriceDataService();
  late Future<List<Map<String, dynamic>>> _recordsFuture;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // Filters
  String _statusFilter = 'ALL';
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _load() {
    _recordsFuture = _service.fetchActualPriceData();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _recordsFuture;
  }

  void _clearAllFilters() {
    setState(() {
      _statusFilter = 'ALL';
      _searchText = '';
      _searchController.clear(); // ✅ clears search UI text
    });
    _searchFocus.unfocus();
  }

  // ---------------- Helpers ----------------

  String _safeStr(dynamic v, [String fallback = '-']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'BATCH_CREATED':
        return Colors.blue;
      case 'MARKETPLACE_LISTED':
        return Colors.deepPurple;
      case 'VERIFIED':
        return Colors.green;
      case 'RECEIVED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'BATCH_CREATED':
        return Icons.add_box_rounded;
      case 'MARKETPLACE_LISTED':
        return Icons.storefront_rounded;
      case 'VERIFIED':
        return Icons.verified_rounded;
      case 'RECEIVED':
        return Icons.local_shipping_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _prettyStatus(String status) {
    switch (status.toUpperCase()) {
      case 'BATCH_CREATED':
        return 'Batch Created';
      case 'MARKETPLACE_LISTED':
        return 'Listed in Marketplace';
      case 'VERIFIED':
        return 'Verified';
      case 'RECEIVED':
        return 'Received';
      default:
        return status.isEmpty ? 'Unknown' : status;
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> all) {
    final search = _searchText.trim().toLowerCase();

    return all.where((r) {
      final status = _safeStr(r['currentStatus'], '').toUpperCase();
      final batchId = _safeStr(r['batchId'], '').toLowerCase();
      final district = _safeStr(r['district'], '').toLowerCase();
      final pepperType = _safeStr(r['pepperType'], '').toLowerCase();
      final farmerName = _safeStr(r['farmerName'], '').toLowerCase();

      final matchStatus = _statusFilter == 'ALL'
          ? true
          : status == _statusFilter;

      final matchSearch = search.isEmpty
          ? true
          : batchId.contains(search) ||
                district.contains(search) ||
                pepperType.contains(search) ||
                farmerName.contains(search);

      return matchStatus && matchSearch;
    }).toList();
  }

  // ---------------- UI Pieces ----------------

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.pagePadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: context.responsive.value(
                mobile: 58,
                tablet: 72,
                desktop: 88,
              ),
              color: Colors.grey.shade500,
            ),
            SizedBox(height: context.responsive.smallSpacing),
            Text(
              title,
              style: TextStyle(
                fontSize: context.responsive.headingFontSize,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsive.smallSpacing * 0.75),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: context.responsive.bodyFontSize,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsive.mediumSpacing),
            OutlinedButton.icon(
              onPressed: () => setState(_load),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reload'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchBar() {
    final primary = const Color(0xFF2E7D32);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        textInputAction: TextInputAction.search,
        onChanged: (v) => setState(() => _searchText = v),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: 'Search',
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(context.responsive.smallSpacing),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.search_rounded,
              color: primary,
              size: context.responsive.smallIconSize,
            ),
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;
              if (!hasText) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.manage_search_rounded,
                    color: Colors.grey.shade500,
                  ),
                );
              }
              return IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchText = '');
                  _searchFocus.unfocus();
                },
              );
            },
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.responsive.mediumSpacing,
            vertical: context.responsive.smallSpacing,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.6),
          ),
        ),
      ),
    );
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final hPad = responsive.pagePadding;
    final vPad = responsive.mediumSpacing;
    final hasActiveFilters =
        _statusFilter != 'ALL' || _searchText.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text('Verify Pepper Batches'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(_load),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _recordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _emptyState(
                icon: Icons.error_outline_rounded,
                title: 'Something went wrong',
                subtitle:
                    'We couldn’t load batches. Pull down to refresh or tap Reload.',
              );
            }

            final all = snapshot.data ?? [];
            if (all.isEmpty) {
              return _emptyState(
                icon: Icons.inbox_rounded,
                title: 'No batches yet',
                subtitle:
                    'Once farmers create pepper batches, they will appear here for verification.',
              );
            }

            final filtered = _applyFilters(all);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad * 0.75),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Total records: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                TextSpan(
                                  text: '${all.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                if (hasActiveFilters) ...[
                                  TextSpan(
                                    text: '  •  Showing: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${filtered.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasActiveFilters)
                          TextButton.icon(
                            onPressed: _clearAllFilters,
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            label: const Text('Clear'),
                          ),
                      ],
                    ),
                  ),
                ),

                // Search box
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _buildEnhancedSearchBar(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(height: context.responsive.smallSpacing),
                ),

                // Chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad * 0.5),
                    child: Wrap(
                      spacing: context.responsive.smallSpacing,
                      runSpacing: context.responsive.smallSpacing,
                      children: [
                        _StatusChip(
                          label: 'All',
                          selected: _statusFilter == 'ALL',
                          color: Colors.grey,
                          onTap: () => setState(() => _statusFilter = 'ALL'),
                        ),
                        _StatusChip(
                          label: 'Batch Created',
                          selected: _statusFilter == 'BATCH_CREATED',
                          color: Colors.blue,
                          onTap: () =>
                              setState(() => _statusFilter = 'BATCH_CREATED'),
                        ),
                        _StatusChip(
                          label: 'Listed',
                          selected: _statusFilter == 'MARKETPLACE_LISTED',
                          color: Colors.deepPurple,
                          onTap: () => setState(
                            () => _statusFilter = 'MARKETPLACE_LISTED',
                          ),
                        ),
                        _StatusChip(
                          label: 'Verified',
                          selected: _statusFilter == 'VERIFIED',
                          color: Colors.green,
                          onTap: () =>
                              setState(() => _statusFilter = 'VERIFIED'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                // Results
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _InfoCard(
                        icon: Icons.filter_alt_off_rounded,
                        title: 'No results',
                        subtitle: 'Try changing filters or search keywords.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, vPad),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: context.responsive.smallSpacing),
                      itemBuilder: (context, index) {
                        final r = filtered[index];

                        final batchId = _safeStr(r['batchId'], 'Unknown');
                        final statusRaw = _safeStr(
                          r['currentStatus'],
                          'Unknown',
                        );
                        final saleDate = _formatDate(_parseDate(r['saleDate']));
                        final statusColor = _statusColor(statusRaw);
                        final farmerName = _safeStr(r['farmerName'], '-');

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    VerifyBatchDetailsScreen(record: r),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(
                              context.responsive.mediumSpacing,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: context.responsive.value(
                                    mobile: 44,
                                    tablet: 52,
                                    desktop: 60,
                                  ),
                                  height: context.responsive.value(
                                    mobile: 44,
                                    tablet: 52,
                                    desktop: 60,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _statusIcon(statusRaw),
                                    color: statusColor,
                                    size: context.responsive.mediumIconSize,
                                  ),
                                ),
                                SizedBox(
                                  width: context.responsive.smallSpacing,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Batch ID: $batchId',
                                              style: TextStyle(
                                                fontSize: context
                                                    .responsive
                                                    .titleFontSize,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            color: Colors.grey,
                                            size: context
                                                .responsive
                                                .smallIconSize,
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: context.responsive.smallSpacing,
                                      ),
                                      Wrap(
                                        spacing:
                                            context.responsive.smallSpacing,
                                        runSpacing:
                                            context.responsive.smallSpacing,
                                        children: [
                                          _MiniPill(
                                            label: _prettyStatus(statusRaw),
                                            color: statusColor,
                                          ),
                                          _MiniPill(
                                            label: 'Date: $saleDate',
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: context.responsive.smallSpacing,
                                      ),
                                      Text(
                                        'Farmer: $farmerName',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------- Small widgets ----------------

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive.smallSpacing * 1.5,
          vertical: context.responsive.smallSpacing,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color.withOpacity(0.45) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? color : Colors.grey.shade800,
            fontSize: context.responsive.smallFontSize,
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive.smallSpacing,
        vertical: context.responsive.smallSpacing * 0.75,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: color == Colors.grey ? Colors.grey.shade800 : color,
          fontSize: context.responsive.smallFontSize,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.grey.shade700,
            size: context.responsive.largeIconSize,
          ),
          SizedBox(width: context.responsive.smallSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: context.responsive.titleFontSize,
                  ),
                ),
                SizedBox(height: context.responsive.smallSpacing * 0.5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: context.responsive.bodyFontSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
