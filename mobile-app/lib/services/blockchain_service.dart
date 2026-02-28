import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';

class BlockchainService {
  /// Fetch quality checks for a given batchId
  static Future<List<Map<String, dynamic>>> getQualityChecksByBatch(
    String batchId,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/quality-checks/batch/$batchId',
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      } else if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        return [];
      }
    }

    throw Exception('Failed to load quality checks (${res.statusCode})');
  }
}
