import 'dart:convert';

/// Lectura ligera del payload JWT (sin verificar firma) para obtener claims de sesión.
abstract final class JwtSession {
  static String? rolFromSessionCookie(String? cookie) {
    if (cookie == null || cookie.isEmpty) return null;
    final token = cookie.startsWith('smart_session=')
        ? cookie.substring('smart_session='.length)
        : cookie;
    return claim(token, 'rol');
  }

  static String? claim(String jwt, String name) {
    final parts = jwt.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        final value = decoded[name];
        if (value is String && value.isNotEmpty) return value;
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}
