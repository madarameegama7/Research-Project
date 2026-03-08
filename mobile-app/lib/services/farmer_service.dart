import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api.dart';
import 'auth_service.dart';
import '../models/farm_plot.dart';

class FarmerService {
  final AuthService _auth = AuthService();

  Future<List<FarmPlot>> fetchPlots() async {
    final token = await _auth.storage.read(key: 'token');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/farm/plots');
    final res = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body is List) {
        return body
            .map((e) => FarmPlot.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // some APIs wrap response in { data: [...] }
      final list = body['data'] ?? body['plots'] ?? [];
      if (list is List)
        return list
            .map((e) => FarmPlot.fromJson(e as Map<String, dynamic>))
            .toList();
    }

    throw Exception('Failed to load farm plots: ${res.statusCode}');
  }

  Future<T> _retry<T>(Future<T> Function() fn, {int attempts = 3}) async {
    int i = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        i++;
        if (i >= attempts) rethrow;
        await Future.delayed(Duration(milliseconds: 200 * (1 << i)));
      }
    }
  }

  Future<FarmPlot> createPlot(Map<String, dynamic> body) async {
    return _retry(() async {
      final token = await _auth.storage.read(key: 'token');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/farm/plots');
      final res = await http
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 201 || res.statusCode == 200) {
        return FarmPlot.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw Exception('Failed to create plot: ${res.statusCode} ${res.body}');
    });
  }

  Future<FarmPlot> updatePlot(String id, Map<String, dynamic> body) async {
    return _retry(() async {
      final token = await _auth.storage.read(key: 'token');
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token != null) headers['Authorization'] = 'Bearer $token';

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/farm/plots/$id');
      final res = await http
          .put(uri, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return FarmPlot.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
      }
      throw Exception('Failed to update plot: ${res.statusCode} ${res.body}');
    });
  }
}
