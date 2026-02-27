import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api.dart';
import '../auth_service.dart';

class ActualPriceDataService {
  final AuthService _auth = AuthService();

  // Fetch records
  Future<List<Map<String, dynamic>>> fetchActualPriceData({
    String? pepperType,
    String? grade,
    String? district,
    int? limit,
  }) async {
    final token = await _auth.storage.read(key: 'token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final queryParams = <String, String>{};
    if (pepperType != null) queryParams['pepperType'] = pepperType;
    if (grade != null) queryParams['grade'] = grade;
    if (district != null) queryParams['district'] = district;
    if (limit != null) queryParams['limit'] = limit.toString();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/market-forecast/actual-price-data',
    ).replace(queryParameters: queryParams);

    final res = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is List) {
        return body
            .whereType<Map<String, dynamic>>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    throw Exception('Failed to fetch records: ${res.statusCode} ${res.body}');
  }

  // Create a new record
  Future<Map<String, dynamic>> createActualPriceData(
    Map<String, dynamic> body,
  ) async {
    final token = await _auth.storage.read(key: 'token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/market-forecast/actual-price-data',
    );
    final res = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 201 || res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    }

    throw Exception('Failed to create record: ${res.statusCode} ${res.body}');
  }

  // Update an existing record
  Future<Map<String, dynamic>> updateActualPriceData(
    String id,
    Map<String, dynamic> body,
  ) async {
    final token = await _auth.storage.read(key: 'token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/market-forecast/actual-price-data/$id',
    );
    final res = await http
        .put(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    }

    throw Exception('Failed to update record: ${res.statusCode} ${res.body}');
  }

  // Delete a record
  Future<void> deleteActualPriceData(String id) async {
    final token = await _auth.storage.read(key: 'token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/market-forecast/actual-price-data/$id',
    );
    final res = await http
        .delete(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to delete record: ${res.statusCode} ${res.body}');
    }
  }
}
