import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
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
    if (user == null) throw Exception("Not logged in");

    final token = await user.getIdToken();
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };

    // ── Try the direct endpoint first ──
    final directUrl = Uri.parse(
      "${ApiConfig.baseUrl}/api/quality-checks/$qualityCheckId",
    );

    final directRes = await http.get(directUrl, headers: headers);

    // If the direct route exists and succeeded, use it
    if (directRes.statusCode >= 200 && directRes.statusCode < 300) {
      dynamic decoded;
      try {
        decoded = jsonDecode(directRes.body);
      } catch (_) {
        throw Exception(
          "Server returned invalid JSON (${directRes.statusCode})",
        );
      }
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception("Unexpected response format");
    }

    // ── If 404/405 (route not yet added), fall back to /report ──
    // The /report endpoint returns the same shape and is already in routes.
    if (directRes.statusCode == 404 || directRes.statusCode == 405) {
      final reportUrl = Uri.parse(
        "${ApiConfig.baseUrl}/api/quality-checks/$qualityCheckId/report",
      );

      final reportRes = await http.get(reportUrl, headers: headers);

      dynamic decoded;
      try {
        decoded = jsonDecode(reportRes.body);
      } catch (_) {
        throw Exception(
          "Server returned invalid JSON (${reportRes.statusCode})",
        );
      }

      if (reportRes.statusCode >= 200 && reportRes.statusCode < 300) {
        if (decoded is Map<String, dynamic>) return decoded;
        throw Exception("Unexpected response format");
      }

      // /report only works for completed checks — handle "not ready" gracefully
      if (reportRes.statusCode == 400 &&
          decoded is Map &&
          (decoded["message"] as String?)?.contains("not ready") == true) {
        // Return a minimal stub so the Review screen can still render
        // batch data passed from earlier steps won't be available here,
        // but at least we won't crash. The screen shows '—' for missing values.
        throw Exception(
          "Quality check is still being processed. Status: ${decoded["message"]}",
        );
      }

      final msg = (decoded is Map && decoded["message"] != null)
          ? decoded["message"].toString()
          : "Request failed (${reportRes.statusCode})";
      throw Exception(msg);
    }

    // ── Any other error from the direct call ──
    dynamic decoded;
    try {
      decoded = jsonDecode(directRes.body);
    } catch (_) {
      throw Exception("Server returned invalid JSON (${directRes.statusCode})");
    }
    final msg = (decoded is Map && decoded["message"] != null)
        ? decoded["message"].toString()
        : "Request failed (${directRes.statusCode})";
    throw Exception(msg);
  }

  //GET /api/quality-checks/batchdetails
  // Returns: [{ _id, batchId, batch, grade }] for the authenticated user
  Future<List<Map<String, dynamic>>> getMyQualityChecks() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final token = await user.getIdToken();
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/quality-checks/batchdetails",
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

  /// GET /api/quality-checks/dashboard-stats
  /// Returns { totalReports, premiumGrades }
  Future<Map<String, int>> getDashboardStats() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final token = await user.getIdToken();
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/quality-checks/dashboard-stats",
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
      return {
        "totalReports": (decoded["totalReports"] as num).toInt(),
        "premiumGrades": (decoded["premiumGrades"] as num).toInt(),
      };
    }

    final msg = (decoded is Map && decoded["message"] != null)
        ? decoded["message"].toString()
        : "Request failed (${res.statusCode})";

    throw Exception(msg);
  }

  // POST /api/quality-checks/validate-image
  // Used in Step 3 before final submission, to validate a single image (e.g. top view) and show a warning if it's not good enough.
  Future<void> validateImage({required File image}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final token = await user.getIdToken();
    final uri = Uri.parse(
      "${ApiConfig.baseUrl}/api/quality-checks/validate-image",
    );

    final req = http.MultipartRequest("POST", uri);
    req.headers["Authorization"] = "Bearer $token";
    req.files.add(await http.MultipartFile.fromPath("image", image.path));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      return; // ok
    }

    try {
      final decoded = jsonDecode(body);
      final msg = (decoded is Map && decoded["message"] != null)
          ? decoded["message"].toString()
          : "Invalid image";
      throw Exception(msg);
    } catch (_) {
      throw Exception("Invalid image");
    }
  }
}
