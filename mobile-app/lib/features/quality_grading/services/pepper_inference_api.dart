import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class PepperInferenceApi {
  final Dio _dio;

  PepperInferenceApi(String fastApiBaseUrl)
      : _dio = Dio(BaseOptions(
          baseUrl: fastApiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(minutes: 2),
          sendTimeout: const Duration(minutes: 2),
        ));

  Future<Map<String, dynamic>> inferQuality({
    required Map<String, File?> images,
    bool textureFirst = true,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    // Validate images
    final requiredKeys = [
      'bottom_full','bottom_half','bottom_close',
      'middle_full','middle_half','middle_close',
      'top_full','top_half','top_close',
    ];

    for (final k in requiredKeys) {
      final f = images[k];
      if (f == null) {
        throw Exception("Missing image: $k");
      }
      if (!f.existsSync()) {
        throw Exception("File not found for: $k");
      }
    }

    final form = FormData();

    for (final k in requiredKeys) {
      final file = images[k]!;
      form.files.add(
        MapEntry(
          k,
          await MultipartFile.fromFile(
            file.path,
            filename: "${k}.jpg",
            contentType: MediaType("image", "jpeg"),
          ),
        ),
      );
    }

    final res = await _dio.post(
      "/infer/quality",
      queryParameters: {"texture_first": textureFirst},
      data: form,
      options: Options(contentType: "multipart/form-data"),
      onSendProgress: onSendProgress,
    );

    if (res.statusCode != 200) {
      throw Exception("Inference failed: ${res.statusCode} ${res.data}");
    }

    if (res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    return Map<String, dynamic>.from(res.data);
  }
}