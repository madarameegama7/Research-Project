import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api.dart';
import '../auth_service.dart';

class ActualPriceDataService {
  final AuthService _auth = AuthService();

  // Fetch records
  // Fetch records
  Future<List<Map<String, dynamic>>> fetchActualPriceData({
    String? pepperType,
    String? grade,
    String? district,
    int? limit,
  }) async {
    final token = await _auth.storage.read(key: 'token');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Make sure token is not empty
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    final queryParams = <String, String>{};
    if (pepperType != null && pepperType.isNotEmpty) {
      queryParams['pepperType'] = pepperType;
    }
    if (grade != null && grade.isNotEmpty) queryParams['grade'] = grade;
    if (district != null && district.isNotEmpty) {
      queryParams['district'] = district;
    }
    if (limit != null && limit > 0) queryParams['limit'] = limit.toString();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/market-forecast/actual-price-data',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final res = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      if (decoded is List) {
        // Safe conversion
        return decoded
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
      }

      // If backend returns {message: ...} by mistake
      throw Exception('Unexpected response format (not a List): ${res.body}');
    }

    // Show the real error
    throw Exception('Failed to fetch records: ${res.statusCode} ${res.body}');
  }

  // Create a new record
  Future<Map<String, dynamic>> createActualPriceData(
    Map<String, dynamic> body,
  ) async {
    final token = await _auth.storage.read(key: 'token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    // Ensure backend knows the user's role when creating a record.
    // Fetch current user from backend and attach role as `userRole` to the payload.
    try {
      if (token != null) {
        final meUri = Uri.parse('${ApiConfig.baseUrl}/api/users/me');
        final meRes = await http
            .get(meUri, headers: headers)
            .timeout(const Duration(seconds: 10));
        if (meRes.statusCode == 200) {
          final meDecoded = jsonDecode(meRes.body);
          if (meDecoded is Map && meDecoded['role'] != null) {
            body['userRole'] = meDecoded['role'];
          }
        }
      }
    } catch (_) {
      // ignore failures here; backend will fallback if role not provided
    }

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
