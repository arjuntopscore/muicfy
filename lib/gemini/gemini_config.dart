import 'package:shared_preferences/shared_preferences.dart';

const String defaultGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const String geminiApiKey = defaultGeminiApiKey;

class GeminiConfig {
  static const String keyPrefKey = 'custom_gemini_api_key';

  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final customKey = prefs.getString(keyPrefKey);
    if (customKey != null && customKey.trim().isNotEmpty) {
      return customKey.trim();
    }
    return defaultGeminiApiKey;
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyPrefKey, key.trim());
  }

  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyPrefKey);
  }
}
