import 'package:flutter/material.dart';
import '../../../services/blockchain_service.dart';
import '../widgets/blockchain_widgets.dart';
import '../../../utils/responsive.dart';

class VerifyBatchDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> record;

  const VerifyBatchDetailsScreen({Key? key, required this.record})
    : super(key: key);

  @override
  State<VerifyBatchDetailsScreen> createState() =>
      _VerifyBatchDetailsScreenState();
}

class _VerifyBatchDetailsScreenState extends State<VerifyBatchDetailsScreen> {
  List<Map<String, dynamic>> _qualityChecks = [];
  bool _loadingQc = true;
  String? _qcError;

  @override
  void initState() {
    super.initState();
    _fetchQualityChecks();
  }

  // Method to safely convert dynamic values to strings with a fallback
  String _safe(dynamic v, [String fallback = '-']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  // Parse various date formats into DateTime objects, returning null if invalid
  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  // Format dates to a consistent "YYYY-MM-DD" format, handling various input types
  String _formatDate(dynamic v) {
    final dt = _parseDate(v);
    if (dt == null) return _safe(v);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // Safely convert dynamic values to doubles, returning null if conversion fails
  double? _safeDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  // Format numbers to a consistent string representation, with 2 decimals if needed
  String _formatNumber(dynamic v) {
    final n = _safeDouble(v);
    if (n == null) return _safe(v);
    // Keep it simple: 2 decimals if has fraction, else no decimals
    final isInt = (n - n.roundToDouble()).abs() < 0.000001;
    return isInt ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  }

  // Convert raw status codes to user-friendly text
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

  // Determine pill color based on status
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

  // Determine icon based on status
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

  // Fetch quality checks for the batch, updating state accordingly
  Future<void> _fetchQualityChecks() async {
    setState(() {
      _loadingQc = true;
      _qcError = null;
    });

    try {
      final batchId = widget.record['batchId']?.toString();
      if (batchId == null || batchId.trim().isEmpty) {
        setState(() {
          _qualityChecks = [];
          _loadingQc = false;
        });
        return;
      }

      final checks = await BlockchainService.getQualityChecksByBatch(batchId);
      _qualityChecks = checks;
    } catch (e) {
      _qcError = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loadingQc = false);
      }
    }
  }

  Widget _qcCard(Map<String, dynamic> qc) {
    final result = _safe(qc['result'] ?? qc['grade'], 'N/A');
    final responsive = context.responsive;

    // Density details (separate lines)
    String densityValue = '-';
    String densitySource = '-';
    String densityMeasured = '-';
    final densityObj = qc['density'];
    if (densityObj is Map) {
      final val = _safeDouble(densityObj['value']);
      densityValue = val != null ? '${_formatNumber(val)} g/L' : '-';
      densitySource = _safe(densityObj['source']);
      // show date only (no time)
      densityMeasured = _formatDate(densityObj['measuredAt']);
    } else if (densityObj != null) {
      densityValue = _safe(densityObj);
    }

    final moisture = _safe(qc['moisture']);
    final defect = _safe(qc['defectRate'] ?? qc['defects']);

    final badgeColor = Colors.teal;

    return Container(
      margin: EdgeInsets.only(bottom: responsive.smallSpacing),
      child: appCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                pillWidget(
                  text: 'QC',
                  color: badgeColor,
                  icon: Icons.fact_check_rounded,
                ),
                SizedBox(width: responsive.smallSpacing),
                Expanded(
                  child: Text(
                    'Result: $result',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: responsive.bodyFontSize,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.smallSpacing),
            Padding(
              padding: EdgeInsets.symmetric(vertical: responsive.smallSpacing),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.scale_rounded,
                    size: responsive.smallIconSize,
                    color: Colors.grey.shade700,
                  ),
                  SizedBox(width: responsive.smallSpacing),
                  SizedBox(
                    width: responsive.value(
                      mobile: 120,
                      tablet: 140,
                      desktop: 160,
                    ),
                    child: Text(
                      'Density',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          densityValue,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        SizedBox(height: responsive.smallSpacing),
                        Text(
                          'Source: ${densitySource}',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: responsive.smallSpacing * 0.6),
                        Text(
                          'Measured: ${densityMeasured}',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            infoRowWidget(
              label: 'Moisture',
              value: moisture,
              icon: Icons.water_drop_rounded,
            ),
            infoRowWidget(
              label: 'Defects',
              value: defect,
              icon: Icons.warning_amber_rounded,
            ),
            SizedBox(height: responsive.smallSpacing),
          ],
        ),
      ),
    );
  }

  // -------------------- Build --------------------

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final responsive = context.responsive;
    final hPad = responsive.pagePadding;
    final vPad = responsive.mediumSpacing;

    final batchId = _safe(r['batchId'], 'Unknown');
    final farmer = _safe(r['farmerName'] ?? r['userId'], 'Unknown');
    final statusRaw = _safe(r['currentStatus'], 'Unknown');
    final statusPretty = _prettyStatus(statusRaw);
    final statusColor = _statusColor(statusRaw);
    final statusIcon = _statusIcon(statusRaw);

    final saleDate = _formatDate(r['saleDate']);
    final district = _safe(r['district']);
    final pepperType = _safe(r['pepperType']);
    final grade = _safe(r['grade']);
    final pricePerKg = _formatNumber(r['pricePerKg']);
    final quantity = _formatNumber(r['quantity']);
    final notes = _safe(r['notes'], 'No notes provided.');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Batch Details'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchQualityChecks,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            hPad,
            vPad,
            hPad,
            vPad + responsive.smallSpacing,
          ),
          children: [
            // Top Summary Card
            appCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: responsive.value(
                          mobile: 46,
                          tablet: 52,
                          desktop: 60,
                        ),
                        height: responsive.value(
                          mobile: 46,
                          tablet: 52,
                          desktop: 60,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          statusIcon,
                          color: statusColor,
                          size: responsive.mediumIconSize,
                        ),
                      ),
                      SizedBox(width: responsive.mediumSpacing),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Batch ID: $batchId',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: responsive.titleFontSize,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: responsive.smallSpacing),
                            Wrap(
                              spacing: responsive.smallSpacing,
                              runSpacing: responsive.smallSpacing,
                              children: [
                                pillWidget(
                                  text: statusPretty,
                                  color: statusColor,
                                ),
                                pillWidget(
                                  text: 'Date: $saleDate',
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.mediumSpacing),
                  infoRowWidget(
                    label: 'Farmer',
                    value: farmer,
                    icon: Icons.person_rounded,
                  ),
                ],
              ),
            ),

            sectionHeaderWidget(
              'Price & Quantity',
              icon: Icons.payments_rounded,
            ),
            appCard(
              child: Column(
                children: [
                  infoRowWidget(
                    label: 'Price / kg',
                    value: pricePerKg,
                    icon: Icons.attach_money_rounded,
                  ),
                  infoRowWidget(
                    label: 'Quantity (kg)',
                    value: quantity,
                    icon: Icons.inventory_2_rounded,
                  ),
                ],
              ),
            ),

            sectionHeaderWidget('Location & Grade', icon: Icons.place_rounded),
            appCard(
              child: Column(
                children: [
                  infoRowWidget(
                    label: 'District',
                    value: district,
                    icon: Icons.location_on_rounded,
                  ),
                  infoRowWidget(
                    label: 'Pepper Type',
                    value: pepperType,
                    icon: Icons.spa_rounded,
                  ),
                  infoRowWidget(
                    label: 'Grade',
                    value: grade,
                    icon: Icons.grade_rounded,
                  ),
                ],
              ),
            ),

            sectionHeaderWidget('Notes', icon: Icons.sticky_note_2_rounded),
            appCard(
              child: Text(
                notes,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  fontSize: responsive.bodyFontSize,
                ),
              ),
            ),

            sectionHeaderWidget(
              'Quality Checks',
              icon: Icons.fact_check_rounded,
              trailing: TextButton.icon(
                onPressed: _fetchQualityChecks,
                icon: Icon(
                  Icons.refresh_rounded,
                  size: responsive.smallIconSize,
                ),
                label: Text(
                  'Tap to Refresh',
                  style: TextStyle(fontSize: responsive.bodyFontSize),
                ),
              ),
            ),

            if (_loadingQc)
              Padding(
                padding: EdgeInsets.only(top: responsive.smallSpacing),
                child: appCard(
                  child: Row(
                    children: [
                      SizedBox(
                        width: responsive.smallIconSize,
                        height: responsive.smallIconSize,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.6,
                        ),
                      ),
                      SizedBox(width: responsive.mediumSpacing),
                      Text(
                        'Loading quality checks...',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: responsive.bodyFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_qcError != null)
              appCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade400,
                      size: responsive.mediumIconSize,
                    ),
                    SizedBox(width: responsive.smallSpacing),
                    Expanded(
                      child: Text(
                        'Error loading quality checks:\n$_qcError',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w700,
                          fontSize: responsive.bodyFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_qualityChecks.isEmpty)
              appCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      color: Colors.grey.shade700,
                      size: responsive.mediumIconSize,
                    ),
                    SizedBox(width: responsive.smallSpacing),
                    Expanded(
                      child: Text(
                        'No quality checks found for this batch.',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: responsive.bodyFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(children: _qualityChecks.map(_qcCard).toList()),

            SizedBox(height: responsive.xlargeSpacing * 0.5),

            // Bottom actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      size: responsive.mediumIconSize,
                    ),
                    label: Text(
                      'Back',
                      style: TextStyle(fontSize: responsive.bodyFontSize),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.smallSpacing,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: responsive.mediumSpacing),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verify action (connect API)'),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.verified_rounded,
                      size: responsive.mediumIconSize,
                    ),
                    label: Text(
                      'Verify',
                      style: TextStyle(fontSize: responsive.bodyFontSize),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.value(
                          mobile: 14,
                          tablet: 16,
                          desktop: 18,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
