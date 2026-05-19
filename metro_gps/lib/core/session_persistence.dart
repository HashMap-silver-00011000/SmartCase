import 'package:shared_preferences/shared_preferences.dart';

/// Guarda el JWT de `smart_session` en disco (móvil / escritorio).
abstract final class SessionPersistence {
  static const _keyToken = 'smart_session_token';

  static Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }
}
