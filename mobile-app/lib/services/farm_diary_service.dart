import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api.dart';
import '../models/farm_diary.dart';

class FarmDiaryService {
  static const String _baseUrl = '${ApiConfig.baseUrl}/api/farm-diary';
  static const String _offlineEntriesKey = 'offline_diary_entries';
  static const String _syncQueueKey = 'diary_sync_queue';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  FarmDiaryService({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  }) : _secureStorage = secureStorage,
       _prefs = prefs;

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'token');
  }

  Map<String, String> _getHeaders(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // GET all diary entries for a farm plot
  Future<List<FarmDiary>> getDiaryEntries({
    String? farmPlotId,
    DateTime? startDate,
    DateTime? endDate,
    String? activityType,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse(_baseUrl).replace(
        path: '${Uri.parse(_baseUrl).path}/entries',
        queryParameters: {
          if (farmPlotId != null) 'farmPlotId': farmPlotId,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
          if (activityType != null) 'activityType': activityType,
        },
      );

      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => FarmDiary.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to load diary entries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting diary entries: $e');
      // Return offline entries if network fails
      return _getOfflineEntries();
    }
  }

  // GET single diary entry
  Future<FarmDiary?> getDiaryEntry(String id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http
          .get(Uri.parse('$_baseUrl/entries/$id'), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return FarmDiary.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load diary entry: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting diary entry: $e');
      return null;
    }
  }

  // CREATE new diary entry
  Future<FarmDiary?> createDiaryEntry(FarmDiary entry) async {
    try {
      final token = await _getToken();
      if (token == null) {
        // Save offline if not authenticated
        await _saveOfflineEntry(entry);
        return entry.copyWith(syncStatus: 'pending');
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl/entries'),
            headers: _getHeaders(token),
            body: jsonEncode(entry.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return FarmDiary.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        // Save offline if unauthorized
        await _saveOfflineEntry(entry);
        return entry.copyWith(syncStatus: 'pending');
      } else {
        throw Exception('Failed to create diary entry: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating diary entry: $e');
      // Save offline on error
      await _saveOfflineEntry(entry);
      return entry.copyWith(syncStatus: 'pending');
    }
  }

  // UPDATE diary entry
  Future<FarmDiary?> updateDiaryEntry(String id, FarmDiary entry) async {
    try {
      final token = await _getToken();
      if (token == null) {
        await _saveOfflineEntry(entry.copyWith(id: id));
        return entry.copyWith(id: id, syncStatus: 'pending');
      }

      final response = await http
          .put(
            Uri.parse('$_baseUrl/entries/$id'),
            headers: _getHeaders(token),
            body: jsonEncode(entry.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return FarmDiary.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        await _saveOfflineEntry(entry.copyWith(id: id));
        return entry.copyWith(id: id, syncStatus: 'pending');
      } else {
        throw Exception('Failed to update diary entry: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating diary entry: $e');
      await _saveOfflineEntry(entry.copyWith(id: id));
      return entry.copyWith(id: id, syncStatus: 'pending');
    }
  }

  // DELETE diary entry
  Future<bool> deleteDiaryEntry(String id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http
          .delete(Uri.parse('$_baseUrl/entries/$id'), headers: _getHeaders(token))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting diary entry: $e');
      return false;
    }
  }

  // GET diary statistics
  Future<Map<String, dynamic>> getDiaryStats({
    required String farmPlotId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final uri = Uri.parse(_baseUrl).replace(
        path: '${Uri.parse(_baseUrl).path}/stats',
        queryParameters: {
          'farmPlotId': farmPlotId,
          if (startDate != null) 'startDate': startDate.toIso8601String(),
          if (endDate != null) 'endDate': endDate.toIso8601String(),
        },
      );

      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load diary stats: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting diary stats: $e');
      return {};
    }
  }

  // SYNC offline entries
  Future<bool> syncOfflineEntries() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final offlineEntries = _getOfflineEntries();
      if (offlineEntries.isEmpty) return true;

      final entriesToSync = offlineEntries
          .map((e) => {...e.toJson(), 'offlineSyncId': e.offlineSyncId})
          .toList();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/sync'),
            headers: _getHeaders(token),
            body: jsonEncode({'entries': entriesToSync}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        await _clearOfflineEntries();
        return true;
      } else {
        throw Exception('Sync failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error syncing offline entries: $e');
      return false;
    }
  }

  // OFFLINE STORAGE METHODS

  Future<void> _saveOfflineEntry(FarmDiary entry) async {
    final offlineEntries = _getOfflineEntries();
    final entryWithSyncId = entry.copyWith(
      offlineSyncId:
          entry.offlineSyncId ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      syncStatus: 'pending',
    );

    offlineEntries.add(entryWithSyncId);
    await _prefs.setString(
      _offlineEntriesKey,
      jsonEncode(offlineEntries.map((e) => e.toJson()).toList()),
    );
  }

  List<FarmDiary> _getOfflineEntries() {
    try {
      final jsonString = _prefs.getString(_offlineEntriesKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => FarmDiary.fromJson(json)).toList();
    } catch (e) {
      print('Error reading offline entries: $e');
      return [];
    }
  }

  Future<void> _clearOfflineEntries() async {
    await _prefs.remove(_offlineEntriesKey);
  }

  // Check if there are pending entries to sync
  bool hasPendingEntries() {
    return _getOfflineEntries().isNotEmpty;
  }

  int getPendingEntriesCount() {
    return _getOfflineEntries().length;
  }
}
