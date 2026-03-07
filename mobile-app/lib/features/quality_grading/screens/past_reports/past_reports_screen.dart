import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/language_prefs.dart';
import '../../services/quality_check_api.dart';
import 'detailed_report_screen.dart';
import '../../../../utils/quality_grading/past_reports_screen_si.dart';

class PastReportsScreen extends StatefulWidget {
  const PastReportsScreen({super.key});

  @override
  State<PastReportsScreen> createState() => _PastReportsScreenState();
}

class _PastReportsScreenState extends State<PastReportsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _sortBy = 'Newest First';
  String _filterGrade = 'All Grades';
  String _currentLanguage = 'en';

  final QualityCheckApi _api = QualityCheckApi();
  List<Map<String, dynamic>> _allReports = [];
  bool _isLoading = true;
  String? _error;

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

    // Load saved language preference
    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) setState(() => _currentLanguage = lang);
    });

    _fetchReports();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ─── Language helper ─────────────────────────────────────────────

  bool get _isSi => _currentLanguage == 'si';

  String _t(String enText, String siText) => _isSi ? siText : enText;

  // Sort / filter option keys (internal, language-independent)
  static const _sortNewest = 'Newest First';
  static const _sortOldest = 'Oldest First';
  static const _sortHighest = 'Highest Score';
  static const _sortLowest = 'Lowest Score';
  static const _filterAllGrades = 'All Grades';

  String _localizedSortOption(String key) {
    if (!_isSi) return key;
    switch (key) {
      case _sortNewest:
        return PastReportsScreenSi.newestFirst;
      case _sortOldest:
        return PastReportsScreenSi.oldestFirst;
      case _sortHighest:
        return PastReportsScreenSi.highestScore;
      case _sortLowest:
        return PastReportsScreenSi.lowestScore;
      default:
        return key;
    }
  }

  String _localizedGradeOption(String key) {
    if (!_isSi) return key;
    if (key == _filterAllGrades) return PastReportsScreenSi.allGrades;
    return key; // grade labels like "Premium", "Gold" stay as-is
  }

  // ─── Fetch ───────────────────────────────────────────────────────

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rawList = await _api.getMyQualityChecks();
      final List<Map<String, dynamic>> enriched = [];
      for (final item in rawList) {
        try {
          final id = item['_id']?.toString() ?? '';
          if (id.isEmpty) continue;
          final full = await _api.getQualityCheckById(qualityCheckId: id);
          if (full['status'] == 'completed') enriched.add(full);
        } catch (_) {}
      }
      setState(() {
        _allReports = enriched;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  String _shortGrade(String? fullGrade) {
    if (fullGrade == null || fullGrade.isEmpty) return 'Unknown';
    final parts = fullGrade.split(' - ');
    return parts.length >= 2 ? parts.last : fullGrade;
  }

  String _displayGrade(Map<String, dynamic> report) =>
      report['results']?['grade'] as String? ?? 'Unknown';

  int _score(Map<String, dynamic> report) =>
      ((report['results']?['overallScore'] as num?)?.round()) ?? 0;

  String _variety(Map<String, dynamic> report) {
    final raw = report['batch']?['pepperVariety'] as String? ?? '';
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _pepperType(Map<String, dynamic> report) {
    final raw = report['batch']?['pepperType'] as String? ?? '';
    return raw.isEmpty ? '' : raw[0].toUpperCase() + raw.substring(1);
  }

  String _dateString(Map<String, dynamic> report) {
    final raw = report['createdAt'] as String?;
    if (raw == null) return '';
    return raw.split('T').first;
  }

  String _density(Map<String, dynamic> report) {
    final val = report['density']?['value'];
    return val == null ? '—' : '${val.toString()} g/L';
  }

  String _weight(Map<String, dynamic> report) {
    final grams = report['batch']?['batchWeightGrams'] as num?;
    if (grams == null) return '—';
    return '${(grams / 1000).toStringAsFixed(2)} kg';
  }

  // ─── Filtering & sorting ─────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredReports {
    var reports = List<Map<String, dynamic>>.from(_allReports);
    if (_filterGrade != _filterAllGrades) {
      reports = reports
          .where((r) => _shortGrade(_displayGrade(r)) == _filterGrade)
          .toList();
    }
    switch (_sortBy) {
      case _sortNewest:
        reports.sort((a, b) => _dateString(b).compareTo(_dateString(a)));
        break;
      case _sortOldest:
        reports.sort((a, b) => _dateString(a).compareTo(_dateString(b)));
        break;
      case _sortHighest:
        reports.sort((a, b) => _score(b).compareTo(_score(a)));
        break;
      case _sortLowest:
        reports.sort((a, b) => _score(a).compareTo(_score(b)));
        break;
    }
    return reports;
  }

  // ─── Stats ───────────────────────────────────────────────────────

  int get _totalReports => _allReports.length;
  int get _premiumCount => _allReports
      .where((r) => _shortGrade(_displayGrade(r)) == 'Premium')
      .length;
  double get _avgScore {
    if (_allReports.isEmpty) return 0;
    return _allReports.map((r) => _score(r)).reduce((a, b) => a + b) /
        _allReports.length;
  }

  // ─── Build ───────────────────────────────────────────────────────

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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('Quality Reports', PastReportsScreenSi.qualityReports),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchReports,
            tooltip: _t('Refresh', PastReportsScreenSi.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? _loadingState()
          : _error != null
          ? _errorState(responsive, primary)
          : _allReports.isEmpty
          ? _emptyState(responsive)
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.pagePadding,
                      ),
                      child: _buildStatsGrid(responsive),
                    ),
                    ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.pagePadding,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildFilterChip(
                              responsive,
                              primary,
                              _t('Filter', PastReportsScreenSi.filter),
                              Icons.filter_list_rounded,
                              _localizedGradeOption(_filterGrade),
                              () => _showFilterDialog(
                                context,
                                responsive,
                                primary,
                              ),
                            ),
                          ),
                          ResponsiveSpacing.horizontal(
                            mobile: 10,
                            tablet: 12,
                            desktop: 14,
                          ),
                          Expanded(
                            child: _buildFilterChip(
                              responsive,
                              primary,
                              _t('Sort', PastReportsScreenSi.sort),
                              Icons.sort_rounded,
                              _localizedSortOption(_sortBy),
                              () =>
                                  _showSortDialog(context, responsive, primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ResponsiveSpacing(mobile: 16, tablet: 18, desktop: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.pagePadding,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_filteredReports.length} ${_filteredReports.length == 1 ? _t('Report', PastReportsScreenSi.report) : _t('Reports', PastReportsScreenSi.reports)}',
                            style: TextStyle(
                              fontSize: responsive.bodyFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ResponsiveSpacing(mobile: 12, tablet: 14, desktop: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.pagePadding,
                      ),
                      itemCount: _filteredReports.length,
                      itemBuilder: (context, index) {
                        return _reportCard(
                          context,
                          responsive,
                          primary,
                          _filteredReports[index],
                        );
                      },
                    ),
                    ResponsiveSpacing(mobile: 32, tablet: 40, desktop: 48),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Loading State ───────────────────────────────────────────────

  Widget _loadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
      ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────

  Widget _errorState(Responsive responsive, Color primary) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                responsive.value(mobile: 24, tablet: 28, desktop: 32),
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: responsive.value(mobile: 56, tablet: 64, desktop: 72),
                color: Colors.red.shade400,
              ),
            ),
            ResponsiveSpacing(mobile: 20, tablet: 24, desktop: 28),
            Text(
              _t('Failed to Load Reports', PastReportsScreenSi.failedToLoad),
              style: TextStyle(
                fontSize: responsive.headingFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            ResponsiveSpacing(mobile: 8, tablet: 10, desktop: 12),
            Text(
              _error ??
                  _t(
                    'An unexpected error occurred.',
                    PastReportsScreenSi.unexpectedError,
                  ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
            ElevatedButton.icon(
              onPressed: _fetchReports,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_t('Try Again', PastReportsScreenSi.tryAgain)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
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

  // ─── Stats Grid ──────────────────────────────────────────────────

  Widget _buildStatsGrid(Responsive responsive) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            responsive,
            _t('Total Reports', PastReportsScreenSi.totalReports),
            _totalReports.toString(),
            Icons.assignment_rounded,
            Colors.blue,
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 10, tablet: 12, desktop: 14),
        Expanded(
          child: _statCard(
            responsive,
            _t('Premium Grades', PastReportsScreenSi.premiumGrades),
            _premiumCount.toString(),
            Icons.star_rounded,
            Colors.amber,
          ),
        ),
        ResponsiveSpacing.horizontal(mobile: 10, tablet: 12, desktop: 14),
        Expanded(
          child: _statCard(
            responsive,
            _t('Avg Score', PastReportsScreenSi.avgScore),
            _avgScore.toStringAsFixed(1),
            Icons.trending_up_rounded,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    Responsive responsive,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: responsive.padding(
        mobile: const EdgeInsets.all(12),
        tablet: const EdgeInsets.all(14),
        desktop: const EdgeInsets.all(16),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(
              responsive.value(mobile: 6, tablet: 7, desktop: 8),
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
            ),
          ),
          ResponsiveSpacing(mobile: 8, tablet: 9, desktop: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              fontWeight: FontWeight.w800,
              color: Colors.grey[800],
            ),
          ),
          ResponsiveSpacing(mobile: 2, tablet: 3, desktop: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(
                mobile: 10,
                tablet: 11,
                desktop: 12,
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

  // ─── Filter Chip ─────────────────────────────────────────────────

  Widget _buildFilterChip(
    Responsive responsive,
    Color primary,
    String label,
    IconData icon,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: responsive.padding(
          mobile: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          tablet: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          desktop: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primary,
              size: responsive.value(mobile: 18, tablet: 20, desktop: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: responsive.fontSize(
                        mobile: 11,
                        tablet: 12,
                        desktop: 13,
                      ),
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: responsive.fontSize(
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                      ),
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: Colors.grey[600],
              size: responsive.value(mobile: 20, tablet: 22, desktop: 24),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Report Card ─────────────────────────────────────────────────

  Widget _reportCard(
    BuildContext context,
    Responsive responsive,
    Color primary,
    Map<String, dynamic> report,
  ) {
    final fullGrade = _displayGrade(report);
    final gradeColor = _getGradeColor(fullGrade);
    final score = _score(report);
    final qualityCheckId =
        report['qualityCheckId']?.toString() ?? report['_id']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailedReportScreen(
              qualityCheckId: qualityCheckId,
              reportData: report,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(
          bottom: responsive.value(mobile: 12, tablet: 14, desktop: 16),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
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
            // Header
            Container(
              padding: responsive.padding(
                mobile: const EdgeInsets.all(14),
                tablet: const EdgeInsets.all(16),
                desktop: const EdgeInsets.all(18),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradeColor.withOpacity(0.1),
                    gradeColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Score badge
                  Container(
                    width: responsive.value(
                      mobile: 56,
                      tablet: 60,
                      desktop: 64,
                    ),
                    height: responsive.value(
                      mobile: 56,
                      tablet: 60,
                      desktop: 64,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gradeColor, gradeColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gradeColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          score.toString(),
                          style: TextStyle(
                            fontSize: responsive.fontSize(
                              mobile: 20,
                              tablet: 22,
                              desktop: 24,
                            ),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: responsive.fontSize(
                              mobile: 10,
                              tablet: 11,
                              desktop: 12,
                            ),
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveSpacing.horizontal(
                    mobile: 14,
                    tablet: 16,
                    desktop: 18,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grade badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.value(
                              mobile: 10,
                              tablet: 11,
                              desktop: 12,
                            ),
                            vertical: responsive.value(
                              mobile: 4,
                              tablet: 5,
                              desktop: 6,
                            ),
                          ),
                          decoration: BoxDecoration(
                            color: gradeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _shortGrade(fullGrade),
                            style: TextStyle(
                              fontSize: responsive.fontSize(
                                mobile: 11,
                                tablet: 12,
                                desktop: 13,
                              ),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ResponsiveSpacing(mobile: 6, tablet: 7, desktop: 8),
                        Text(
                          _variety(report),
                          style: TextStyle(
                            fontSize: responsive.titleFontSize,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[800],
                          ),
                        ),
                        ResponsiveSpacing(mobile: 2, tablet: 3, desktop: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.grass_rounded,
                              size: responsive.value(
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_pepperType(report)} ${_t('Pepper', PastReportsScreenSi.pepper)}',
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize - 2,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '·',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              report['batchId']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize - 2,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        ResponsiveSpacing(mobile: 2, tablet: 3, desktop: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: responsive.value(
                                mobile: 12,
                                tablet: 13,
                                desktop: 14,
                              ),
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(_dateString(report)),
                              style: TextStyle(
                                fontSize: responsive.bodyFontSize - 2,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey[400],
                    size: responsive.value(mobile: 28, tablet: 30, desktop: 32),
                  ),
                ],
              ),
            ),
            // Footer: weight + density
            Padding(
              padding: responsive.padding(
                mobile: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                tablet: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                desktop: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              child: Row(
                children: [
                  _infoChip(responsive, Icons.scale_rounded, _weight(report)),
                  const SizedBox(width: 10),
                  _infoChip(
                    responsive,
                    Icons.compress_rounded,
                    _density(report),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(Responsive responsive, IconData icon, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: responsive.value(mobile: 13, tablet: 14, desktop: 15),
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(mobile: 11, tablet: 12, desktop: 13),
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────

  Widget _emptyState(Responsive responsive) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                responsive.value(mobile: 28, tablet: 32, desktop: 36),
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.insert_drive_file_outlined,
                size: responsive.value(mobile: 64, tablet: 72, desktop: 80),
                color: Colors.grey[400],
              ),
            ),
            ResponsiveSpacing(mobile: 24, tablet: 28, desktop: 32),
            Text(
              _t('No Reports Yet', PastReportsScreenSi.noReportsYet),
              style: TextStyle(
                fontSize: responsive.headingFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            ResponsiveSpacing(mobile: 8, tablet: 10, desktop: 12),
            Text(
              _t(
                'Start your first quality check to see\nyour grading reports here',
                PastReportsScreenSi.startFirstCheck,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.bodyFontSize,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sort / Filter dialogs ───────────────────────────────────────

  void _showSortDialog(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    final sortOptions = [_sortNewest, _sortOldest, _sortHighest, _sortLowest];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(
          responsive.value(mobile: 20, tablet: 24, desktop: 28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sort_rounded, color: primary),
                const SizedBox(width: 12),
                Text(
                  _t('Sort By', PastReportsScreenSi.sort),
                  style: TextStyle(
                    fontSize: responsive.headingFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...sortOptions.map(
              (option) => RadioListTile<String>(
                title: Text(_localizedSortOption(option)),
                value: option,
                groupValue: _sortBy,
                activeColor: primary,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(
    BuildContext context,
    Responsive responsive,
    Color primary,
  ) {
    final grades = {
      _filterAllGrades,
      ...(_allReports.map((r) => _shortGrade(_displayGrade(r)))),
    }.toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(
          responsive.value(mobile: 20, tablet: 24, desktop: 28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list_rounded, color: primary),
                const SizedBox(width: 12),
                Text(
                  _t('Filter by Grade', PastReportsScreenSi.filterByGrade),
                  style: TextStyle(
                    fontSize: responsive.headingFontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...grades.map(
              (option) => RadioListTile<String>(
                title: Text(_localizedGradeOption(option)),
                value: option,
                groupValue: _filterGrade,
                activeColor: primary,
                onChanged: (value) {
                  setState(() => _filterGrade = value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Utilities ───────────────────────────────────────────────────

  Color _getGradeColor(String fullGrade) {
    final lower = fullGrade.toLowerCase();
    if (lower.contains('premium') || lower.contains('grade 1'))
      return Colors.green.shade600;
    if (lower.contains('gold') || lower.contains('grade 2'))
      return Colors.amber.shade700;
    if (lower.contains('silver') || lower.contains('grade 3'))
      return Colors.blueGrey.shade600;
    if (lower.contains('basic') || lower.contains('grade 4'))
      return Colors.orange.shade600;
    if (lower.contains('reject')) return Colors.red.shade600;
    return Colors.grey.shade600;
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${parts[2]} ${months[int.parse(parts[1]) - 1]} ${parts[0]}';
  }
}
