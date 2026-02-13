import 'package:shared_preferences/shared_preferences.dart';

class LanguagePrefs {
  static const _key = 'app_language_code';

  static Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'en';
  }
}

