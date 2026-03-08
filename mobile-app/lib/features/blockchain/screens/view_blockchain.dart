import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../utils/responsive.dart';
import '../../../services/blockchain_service.dart';

class ViewBlockchainScreen extends StatefulWidget {
  final Map<String, dynamic> record;

  const ViewBlockchainScreen({super.key, required this.record});

  @override
  State<ViewBlockchainScreen> createState() => _ViewBlockchainScreenState();
}

class _ViewBlockchainScreenState extends State<ViewBlockchainScreen> {
  bool _loadingQc = true;
  String? _qcError;
  Map<String, dynamic>? _qc;

  // ---------- Helpers ----------
  String _safe(dynamic v, [String fallback = '-']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _normalizeStatus(dynamic s) {
    if (s == null) return '';
    return s
        .toString()
        .trim()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .toUpperCase();
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;

    // Mongo style {"$date": "..."}
    if (v is Map && v[r'$date'] != null) {
      return DateTime.tryParse(v[r'$date'].toString());
    }

    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  // dd/MM/yyyy
  String _formatDateOnly(dynamic v) {
    final dt = _parseDate(v);
    if (dt == null) return _safe(v);

    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  double? _safeDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  String _formatNumber(dynamic v) {
    final n = _safeDouble(v);
    if (n == null) return _safe(v);
    final isInt = (n - n.roundToDouble()).abs() < 0.000001;
    return isInt ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  }

  String _prettyStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'BATCH_CREATED':
        return 'Batch Created';
      case 'MARKETPLACE_LISTED':
        return 'Listed in Marketplace';
      case 'VERIFIED':
        return 'Verified by Admin';
      case 'QR_GENERATED':
        return 'QR Generated';
      case 'RECEIVED':
        return 'Received by Exporter';
      default:
        return raw.isEmpty ? 'Unknown' : raw;
    }
  }

  IconData _statusIcon(String raw) {
    switch (raw.toUpperCase()) {
      case 'BATCH_CREATED':
        return Icons.add_box_rounded;
      case 'MARKETPLACE_LISTED':
        return Icons.storefront_rounded;
      case 'VERIFIED':
        return Icons.verified_rounded;
      case 'QR_GENERATED':
        return Icons.qr_code_2_rounded;
      case 'RECEIVED':
        return Icons.local_shipping_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _statusColor(String raw) {
    switch (raw.toUpperCase()) {
      case 'BATCH_CREATED':
        return Colors.blue;
      case 'MARKETPLACE_LISTED':
        return Colors.deepPurple;
      case 'VERIFIED':
        return Colors.green;
      case 'QR_GENERATED':
        return const Color(0xFF2E7D32);
      case 'RECEIVED':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _prettyRole(dynamic role) {
    final r = _safe(role, 'UNKNOWN').toUpperCase();
    switch (r) {
      case 'FARMER':
        return 'Farmer';
      case 'ADMIN':
        return 'Admin';
      case 'EXPORTER':
        return 'Exporter';
      default:
        final lower = r.toLowerCase();
        return lower.isEmpty
            ? 'Unknown'
            : '${lower[0].toUpperCase()}${lower.substring(1)}';
    }
  }

  // ---------- UI Building Blocks ----------
  Widget _sectionHeader(
    Responsive responsive,
    String title, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: responsive.headingFontSize,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _card(Responsive responsive, {required Widget child}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: responsive.mediumSpacing),
      padding: EdgeInsets.all(responsive.mediumSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow(
    Responsive responsive, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.smallSpacing * 0.55),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          SizedBox(width: responsive.smallSpacing),
          SizedBox(
            width: responsive.value(mobile: 120, tablet: 150, desktop: 170),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade700,
                fontSize: responsive.smallFontSize + 1,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                fontSize: responsive.bodyFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Factor Scores (Screenshot Style) ----------
  String _prettyFactorKey(String key) {
    final s = key.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    return s
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Color _factorColor(String key) {
    final k = key.toLowerCase();
    if (k.contains('density')) return Colors.green;
    if (k.contains('adulter')) return Colors.teal;
    if (k.contains('mold')) return Colors.purple;
    if (k.contains('extraneous')) return Colors.orange;
    if (k.contains('broken')) return Colors.indigo;
    if (k.contains('variety') || k.contains('piperine')) return Colors.blue;
    if (k.contains('healthy')) return Colors.lightBlue;
    if (k.contains('cert')) return Colors.green.shade700;
    return Colors.blueGrey;
  }

  Widget _factorList(Responsive responsive, Map<String, dynamic> factorScores) {
    final entries = factorScores.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: entries.map((e) {
        final label = _prettyFactorKey(e.key);
        final score = (_safeDouble(e.value) ?? 0).clamp(0, 100).toDouble();
        final color = _factorColor(e.key);

        return Container(
          margin: EdgeInsets.only(bottom: responsive.smallSpacing),
          padding: EdgeInsets.all(responsive.mediumSpacing),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.grey.shade900,
                        fontSize: responsive.bodyFontSize,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      score % 1 == 0
                          ? score.toInt().toString()
                          : score.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: color,
                        fontSize: responsive.smallFontSize + 1,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.smallSpacing),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 10,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ---------- Timeline ----------
  Widget _timelineItem(
    Responsive responsive, {
    required bool isLast,
    required String title,
    required String date,
    required String role,
    required IconData icon,
    required Color iconColor,
  }) {
    const green = Color(0xFF2E7D32);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: green,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: responsive.value(mobile: 64, tablet: 70, desktop: 76),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: responsive.smallSpacing),
            padding: EdgeInsets.all(responsive.mediumSpacing),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                SizedBox(width: responsive.mediumSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          fontSize: responsive.bodyFontSize,
                        ),
                      ),
                      SizedBox(height: responsive.smallSpacing * 0.5),
                      Text(
                        'On: $date',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: responsive.smallFontSize + 1,
                        ),
                      ),
                      SizedBox(height: responsive.smallSpacing * 0.3),
                      Text(
                        role,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: responsive.smallFontSize + 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Load Quality Checks ----------
  @override
  void initState() {
    super.initState();
    _fetchQuality();
  }

  Future<void> _fetchQuality() async {
    setState(() {
      _loadingQc = true;
      _qcError = null;
      _qc = null;
    });

    try {
      final batchId = widget.record['batchId']?.toString();
      if (batchId == null || batchId.trim().isEmpty) {
        setState(() => _loadingQc = false);
        return;
      }

      final list = await BlockchainService.getQualityChecksByBatch(batchId);
      if (list.isEmpty) {
        setState(() => _loadingQc = false);
        return;
      }

      // pick latest by results.processedAt > updatedAt > createdAt
      list.sort((a, b) {
        DateTime? da =
            _parseDate(a['results']?['processedAt']) ??
            _parseDate(a['updatedAt']) ??
            _parseDate(a['createdAt']);
        DateTime? db =
            _parseDate(b['results']?['processedAt']) ??
            _parseDate(b['updatedAt']) ??
            _parseDate(b['createdAt']);
        return (db ?? DateTime(1970)).compareTo(da ?? DateTime(1970));
      });

      setState(() {
        _qc = list.first;
        _loadingQc = false;
      });
    } catch (e) {
      setState(() {
        _qcError = e.toString();
        _loadingQc = false;
      });
    }
  }

  // ---------- Screen ----------
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final record = widget.record;

    final batchId = _safe(record['batchId'], _safe(record['_id']));
    final pepperType = _safe(record['pepperType']);
    final district = _safe(record['district']);
    final price = _formatNumber(record['pricePerKg']);
    final qty = _formatNumber(record['quantity']);
    final notes = _safe(record['notes'], 'No notes');

    final statusRaw = _normalizeStatus(record['currentStatus']);
    final statusPretty = _prettyStatus(statusRaw);
    final statusColor = _statusColor(statusRaw);

    final qrToken = _safe(record['qrToken'], '');
    final qrGeneratedOn = _formatDateOnly(record['qrGeneratedAt']);

    final historyRaw = record['statusHistory'];
    final List<Map<String, dynamic>> history = (historyRaw is List)
        ? historyRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    // ✅ IMPORTANT FIX for your error:
    // index can be int OR double depending on Mongo/JSON decoding.
    history.sort((a, b) {
      final ia = (a['index'] is num) ? (a['index'] as num).toInt() : 0;
      final ib = (b['index'] is num) ? (b['index'] as num).toInt() : 0;
      return ia.compareTo(ib);
    });

    final isMarketplaceListed = history.any(
      (b) => _normalizeStatus(b['status']) == 'MARKETPLACE_LISTED',
    );

    // Harvested date (from qualitychecks.batch.harvestDate)
    final harvestDate = _qc?['batch']?['harvestDate'];
    final harvestedOn = harvestDate != null
        ? _formatDateOnly(harvestDate)
        : null;

    // QC fields
    final qcStatus = _safe(_qc?['status'], '-');
    final qcGrade = _safe(_qc?['results']?['grade'], '-');
    final qcScore = _formatNumber(_qc?['results']?['overallScore']);
    final dryingMethod = _safe(_qc?['batch']?['dryingMethod'], '-');
    final pepperVariety = _safe(_qc?['batch']?['pepperVariety'], '-');

    final densityValue = _formatNumber(_qc?['density']?['value']);
    final densitySource = _safe(_qc?['density']?['source'], '-');
    final densityMeasuredOn = _formatDateOnly(_qc?['density']?['measuredAt']);

    final certCount = (_qc?['certificatesSnapshot']?['count'] is num)
        ? (_qc?['certificatesSnapshot']?['count'] as num).toInt()
        : 0;

    final factorScoresRaw = _qc?['results']?['factorScores'];
    final Map<String, dynamic> factorScores = (factorScoresRaw is Map)
        ? Map<String, dynamic>.from(factorScoresRaw)
        : {};

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Batch Details'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchQuality,
          child: ListView(
            padding: EdgeInsets.all(responsive.pagePadding),
            children: [
              // --------- Top Summary ---------
              _card(
                responsive,
                child: Row(
                  children: [
                    Container(
                      width: responsive.value(
                        mobile: 52,
                        tablet: 58,
                        desktop: 64,
                      ),
                      height: responsive.value(
                        mobile: 52,
                        tablet: 58,
                        desktop: 64,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _statusIcon(statusRaw),
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
                            'Batch: $batchId',
                            style: TextStyle(
                              fontSize: responsive.titleFontSize,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: responsive.smallSpacing),
                          Wrap(
                            spacing: responsive.smallSpacing,
                            runSpacing: responsive.smallSpacing,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.25),
                                  ),
                                ),
                                child: Text(
                                  statusPretty,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (isMarketplaceListed)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.deepPurple.withOpacity(
                                        0.25,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    'Also in Marketplace ✅',
                                    style: TextStyle(
                                      color: Colors.deepPurple,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --------- Batch Details (no grade) ---------
              _card(
                responsive,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(responsive, 'Batch Details'),
                    SizedBox(height: responsive.smallSpacing),
                    _infoRow(
                      responsive,
                      icon: Icons.spa_rounded,
                      label: 'Pepper Type',
                      value: pepperType,
                    ),
                    _infoRow(
                      responsive,
                      icon: Icons.location_on_rounded,
                      label: 'District',
                      value: district,
                    ),
                    _infoRow(
                      responsive,
                      icon: Icons.attach_money_rounded,
                      label: 'Price / kg',
                      value: price,
                    ),
                    _infoRow(
                      responsive,
                      icon: Icons.inventory_2_rounded,
                      label: 'Quantity',
                      value: '$qty kg',
                    ),
                    _infoRow(
                      responsive,
                      icon: Icons.sticky_note_2_rounded,
                      label: 'Additional Notes',
                      value: notes,
                    ),
                  ],
                ),
              ),

              // --------- Quality Details + factors ---------
              _card(
                responsive,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      responsive,
                      'Quality Details',
                      trailing: _loadingQc
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const SizedBox.shrink(),
                    ),
                    SizedBox(height: responsive.smallSpacing),

                    if (_qcError != null)
                      Text(
                        'Failed to load quality details: $_qcError',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else if (!_loadingQc && _qc == null)
                      Text(
                        'No quality check record found for this batch.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: responsive.bodyFontSize,
                        ),
                      )
                    else if (_qc != null) ...[
                      // Grade + score highlight
                      Container(
                        padding: EdgeInsets.all(responsive.mediumSpacing),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF2E7D32).withOpacity(0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2E7D32,
                                ).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.workspace_premium_rounded,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(width: responsive.mediumSpacing),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Grade',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w800,
                                      fontSize: responsive.smallFontSize + 1,
                                    ),
                                  ),
                                  Text(
                                    qcGrade,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w900,
                                      fontSize: responsive.bodyFontSize + 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2E7D32,
                                ).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Score: $qcScore',
                                style: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: responsive.mediumSpacing),

                      _infoRow(
                        responsive,
                        icon: Icons.fact_check_rounded,
                        label: 'QC Status',
                        value: qcStatus,
                      ),
                      _infoRow(
                        responsive,
                        icon: Icons.eco_rounded,
                        label: 'Pepper Variety',
                        value: pepperVariety,
                      ),
                      _infoRow(
                        responsive,
                        icon: Icons.wb_sunny_rounded,
                        label: 'Drying Method',
                        value: dryingMethod,
                      ),
                      _infoRow(
                        responsive,
                        icon: Icons.scale_rounded,
                        label: 'Density',
                        value: '$densityValue g/L',
                      ),
                      _infoRow(
                        responsive,
                        icon: Icons.sensors_rounded,
                        label: 'Density Source',
                        value: densitySource,
                      ),
                      _infoRow(
                        responsive,
                        icon: Icons.event_available_rounded,
                        label: 'Measured On',
                        value: densityMeasuredOn,
                      ),
                      _infoRow(
                        responsive,
                        icon: Icons.badge_rounded,
                        label: 'Certificates',
                        value: certCount.toString(),
                      ),

                      if (factorScores.isNotEmpty) ...[
                        SizedBox(height: responsive.mediumSpacing),
                        Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: Colors.grey.shade800,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Factor Scores',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                fontSize: responsive.bodyFontSize + 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.smallSpacing),
                        _factorList(responsive, factorScores),
                      ],
                    ],
                  ],
                ),
              ),

              // --------- QR Section ---------
              _card(
                responsive,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(responsive, 'QR Code'),
                    SizedBox(height: responsive.smallSpacing),
                    if (qrToken.isEmpty)
                      Text(
                        'QR not available for this record.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: responsive.bodyFontSize,
                        ),
                      )
                    else
                      Column(
                        children: [
                          Center(
                            child: QrImageView(
                              data: qrToken,
                              size: responsive.value(
                                mobile: 220,
                                tablet: 260,
                                desktop: 280,
                              ),
                            ),
                          ),
                          SizedBox(height: responsive.smallSpacing),
                          Text(
                            'Generated on: $qrGeneratedOn',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w700,
                              fontSize: responsive.bodyFontSize,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // --------- Blockchain History Timeline ---------
              _card(
                responsive,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(responsive, 'Blockchain History'),
                    SizedBox(height: responsive.smallSpacing),
                    if (history.isEmpty && harvestedOn == null)
                      Text(
                        'No history found.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else
                      Column(
                        children: [
                          if (harvestedOn != null)
                            _timelineItem(
                              responsive,
                              isLast: history.isEmpty,
                              title: 'Harvested',
                              date: harvestedOn,
                              role: 'By: ${_prettyRole('FARMER')}',
                              icon: Icons.agriculture_rounded,
                              iconColor: const Color(0xFF2E7D32),
                            ),
                          ...List.generate(history.length, (i) {
                            final block = history[i];
                            final stRaw = _normalizeStatus(block['status']);
                            final title = _prettyStatus(stRaw);
                            final date = _formatDateOnly(block['timestamp']);
                            final role =
                                'By: ${_prettyRole(block['actorRole'])}';
                            final icon = _statusIcon(stRaw);
                            final iconColor = _statusColor(stRaw);

                            final total =
                                history.length + (harvestedOn != null ? 1 : 0);
                            final currentIndex =
                                i + (harvestedOn != null ? 1 : 0);
                            final isLast = currentIndex == total - 1;

                            return _timelineItem(
                              responsive,
                              isLast: isLast,
                              title: title,
                              date: date,
                              role: role,
                              icon: icon,
                              iconColor: iconColor,
                            );
                          }),
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
