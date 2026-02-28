import 'package:CeylonPepper/utils/language_prefs.dart';
import 'package:flutter/material.dart';
import '../../../utils/responsive.dart';
import '../../../services/market_forecast/actual_price_data_service.dart';
import '../widgets/summary_statistics_card.dart';
import '../widgets/price_report_card.dart';
import '../widgets/empty_reports_view.dart';
import '../widgets/error_view.dart';
import 'actual_price_data.dart';
import '../../../utils/market forecast/actual_price_data_si.dart';
import '../widgets/marketplace_prompt_dialog.dart';

class PastPriceReportsScreen extends StatefulWidget {
  const PastPriceReportsScreen({super.key});

  @override
  State<PastPriceReportsScreen> createState() => _PastPriceReportsScreenState();
}

class _PastPriceReportsScreenState extends State<PastPriceReportsScreen> {
  String _currentLanguage = 'en';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load language preference
    LanguagePrefs.getLanguage().then((lang) {
      if (mounted) {
        setState(() {
          _currentLanguage = lang;
        });
      }
    });
  }

  final ActualPriceDataService _service = ActualPriceDataService();
  List<Map<String, dynamic>> pastReports = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  // Load past sales reports
  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _service.fetchActualPriceData();
      if (mounted) {
        setState(() {
          pastReports = records;
          _sortReports();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load reports: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Sort reports by date (most recent first by default)
  void _sortReports() {
    pastReports.sort((a, b) {
      DateTime? dateA =
          _parseDate(a['saleDate'] ?? a['date'] ?? a['createdAt'] ?? a['reportDate']);
      DateTime? dateB =
          _parseDate(b['saleDate'] ?? b['date'] ?? b['createdAt'] ?? b['reportDate']);

      if (dateA == null || dateB == null) return 0;
      return _sortAscending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
  }

  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
      _sortReports();
    });
  }

  // Delete a report with confirmation prompt
  Future<void> _deleteReport(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _currentLanguage == 'si'
              ? ActualPriceDataSi.deleteRecord
              : 'Delete Record',
        ),
        content: Text(
          _currentLanguage == 'si'
              ? ActualPriceDataSi.deleteConfirm
              : 'Are you sure you want to delete this record?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              _currentLanguage == 'si' ? ActualPriceDataSi.cancel : 'Cancel',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              _currentLanguage == 'si' ? ActualPriceDataSi.delete : 'Delete',
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteActualPriceData(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _currentLanguage == 'si'
                    ? ActualPriceDataSi.recordDeleted
                    : 'Record deleted successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadReports();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _currentLanguage == 'si'
                    ? ActualPriceDataSi.failedToDelete
                    : 'Failed to delete record: $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Navigate to update report screen
  Future<void> _navigateToUpdateReport(Map<String, dynamic> report) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ActualPriceData(reportData: report),
      ),
    );

    if (result == true && mounted) {
      _loadReports();
    }
  }

  // Add to Marketplace flow
  Future<void> _promptAddToMarketplace(Map<String, dynamic> report) async {
    final id = (report['_id'] as String?) ?? (report['id'] as String?) ?? '';
    if (id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentLanguage == 'si'
                ? ActualPriceDataSi.cannotDeleteNoId
                : 'Cannot update: Report ID not found',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MarketplacePromptDialog(
        language: _currentLanguage,
        onNoThanks: () => Navigator.pop(context),
        onYesAdd: () async {
          Navigator.pop(context);

          try {
            await _service.updateActualPriceData(id, {
              'currentStatus': 'MARKETPLACE_LISTED',
            });

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _currentLanguage == 'si'
                      ? 'වෙළඳපලට යොමු කරන ලදී. අනුමැතිය අවශ්‍ය වේ.'
                      : 'Sent to marketplace. Approval is required.',
                ),
                backgroundColor: Colors.green,
              ),
            );

            _loadReports();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _currentLanguage == 'si'
                      ? 'වෙළඳපලට යැවීම අසාර්ථකයි: $e'
                      : 'Failed to send to marketplace: $e',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _currentLanguage == 'si'
              ? ActualPriceDataSi.pastPriceDetails
              : 'Pepper Batch Details',
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? ErrorView(errorMessage: _errorMessage!, onRetry: _loadReports)
              : pastReports.isEmpty
                  ? EmptyReportsView(language: _currentLanguage)
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(responsive.mediumSpacing),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SummaryStatisticsCard(
                            reports: pastReports,
                            language: _currentLanguage,
                          ),
                          SizedBox(height: responsive.largeSpacing),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _currentLanguage == 'si'
                                    ? ActualPriceDataSi.recentSales
                                    : 'Recent Pepper Batches',
                                style: TextStyle(
                                  fontSize: responsive.bodyFontSize + 2,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.sort),
                                tooltip: _currentLanguage == 'si'
                                    ? (_sortAscending
                                        ? ActualPriceDataSi.oldestFirst
                                        : ActualPriceDataSi.newestFirst)
                                    : (_sortAscending
                                        ? 'Oldest first'
                                        : 'Newest first'),
                                onPressed: _toggleSortOrder,
                              ),
                            ],
                          ),
                          SizedBox(height: responsive.smallSpacing + 4),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pastReports.length,
                            itemBuilder: (context, index) {
                              final report = pastReports[index];

                              return PriceReportCard(
                                report: report,
                                onUpdate: () => _navigateToUpdateReport(report),
                                onDelete: () {
                                  final id = report['_id'] as String? ??
                                      report['id'] as String? ??
                                      '';
                                  if (id.isNotEmpty) {
                                    _deleteReport(id);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _currentLanguage == 'si'
                                              ? ActualPriceDataSi.cannotDeleteNoId
                                              : 'Cannot delete: Report ID not found',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                // ✅ NEW button callback
                                onAddToMarketplace: () =>
                                    _promptAddToMarketplace(report),
                                language: _currentLanguage,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }
}