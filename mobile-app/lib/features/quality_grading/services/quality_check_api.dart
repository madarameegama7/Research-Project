import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

import '../../../config/api.dart';

class QualityCheckApi {
  final FirebaseAuth _auth;

  QualityCheckApi({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Future<Map<String, dynamic>> createQualityCheck({
    required String pepperType, // "black" | "white"
    required String pepperVariety, // "ceylon_pepper" ...
    required DateTime harvestDate, // Date
    required String dryingMethod, // "sun_dried" ...
    required int batchWeightKg,
    required int batchWeightG,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Not logged in");
    }

    final token = await user.getIdToken();
    final url = Uri.parse("${ApiConfig.baseUrl}/api/quality-checks");

    final body = {
      "pepperType": pepperType,
      "pepperVariety": pepperVariety,
      "harvestDate": harvestDate
          .toIso8601String()
          .split('T')
          .first, // yyyy-MM-dd
      "dryingMethod": dryingMethod,
      "batchWeightKg": batchWeightKg,
      "batchWeightG": batchWeightG,
    };

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded as Map<String, dynamic>;
    }

    final msg = (decoded is Map && decoded["message"] != null)
        ? decoded["message"].toString()
        : "Request failed (${res.statusCode})";

    throw Exception(msg);
  }

  Future<Map<String, dynamic>> updateDensity({
    required String qualityCheckId,
    required double value, // density g/L
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Not logged in");
    }

    final token = await user.getIdToken();
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/quality-checks/$qualityCheckId/density",
    );

    final body = {"value": value};

    final res = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded as Map<String, dynamic>;
    }

    final msg = (decoded is Map && decoded["message"] != null)
        ? decoded["message"].toString()
        : "Request failed (${res.statusCode})";

    throw Exception(msg);
  }

  Future<List<Map<String, dynamic>>> getMyVerifiedCertifications() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Not logged in");
    }

    final token = await user.getIdToken();
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/certifications/me?status=verified&sort=newest",
    );

    final res = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final decoded = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      throw Exception("Unexpected response format");
    }

    final msg = (decoded is Map && decoded["message"] != null)
        ? decoded["message"].toString()
        : "Request failed (${res.statusCode})";

    throw Exception(msg);
  }

  Future<Map<String, dynamic>> analyzeImages({
    required String qualityCheckId,
    required Map<String, File?> images,
    bool textureFirst = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Not logged in");
    }

    // Must have all 9 images
    final missing = images.entries
        .where((e) => e.value == null)
        .map((e) => e.key)
        .toList();
    if (missing.isNotEmpty) {
      throw Exception("Missing images: ${missing.join(', ')}");
    }

    final token = await user.getIdToken();
    final uri = Uri.parse(
      "${ApiConfig.baseUrl}/api/quality-checks/$qualityCheckId/analyze",
    );

    final req = http.MultipartRequest("POST", uri);

    req.headers["Authorization"] = "Bearer $token";
    req.fields["texture_first"] = textureFirst ? "true" : "false";

    // Attach files with the exact backend field names
    for (final entry in images.entries) {
      final field = entry.key;
      final file = entry.value!;
      req.files.add(await http.MultipartFile.fromPath(field, file.path));
    }

    final streamed = await req.send();

    final body = await streamed.stream.bytesToString();

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw Exception("Server returned invalid JSON (${streamed.statusCode})");
    }

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return decoded as Map<String, dynamic>;
    }

    final msg = (decoded is Map && decoded["message"] != null)
        ? decoded["message"].toString()
        : "Request failed (${streamed.statusCode})";

    throw Exception(msg);
  }

  Future<Uint8List> downloadPdfBytes({required String qualityCheckId}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Not logged in");
    }

    final token = await user.getIdToken();
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/quality-checks/$qualityCheckId/report/pdf",
    );

    final res = await http.get(
      url,
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.bodyBytes;
    }

    // backend might return JSON error, but PDF endpoint may return plain text
    try {
      final decoded = jsonDecode(res.body);
      final msg = (decoded is Map && decoded["message"] != null)
          ? decoded["message"].toString()
          : "Request failed (${res.statusCode})";
      throw Exception(msg);
    } catch (_) {
      throw Exception("PDF download failed (${res.statusCode})");
    }
  }

  /// Saves the PDF to a file (mobile/desktop) and returns the file path.
  /// For web, you should not use this. Web uses browser download.
  Future<String> savePdfToFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$fileName");
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<Map<String, dynamic>> getQualityCheckById({
    required String qualityCheckId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Not logged in");
    }

    final token = await user.getIdToken();
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/quality-checks/$qualityCheckId",
    );

    final res = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (_) {
      throw Exception("Server returned invalid JSON (${res.statusCode})");
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception("Unexpected response format");
    }

    final msg = (decoded is Map && decoded["message"] != null)
        ? decoded["message"].toString()
        : "Request failed (${res.statusCode})";

    throw Exception(msg);
  }
}
