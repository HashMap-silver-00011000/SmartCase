import 'package:http/http.dart' as http;

import 'api_constants.dart';
import 'jwt_session.dart';
import 'session_persistence.dart';
import 'session_store.dart';

/// Cliente HTTP compartido: envía la cookie `smart_session` en cada petición.
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = _trimTrailingSlash(baseUrl ?? ApiConstants.baseUrl);

  final http.Client _client;
  final String _baseUrl;

  String? _sessionCookie;

  bool get hasSession => _sessionCookie != null;

  /// Cookie lista para el header `Cookie` (p. ej. `smart_session=...`).
  String? get sessionCookie => _sessionCookie;

  static String _trimTrailingSlash(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  Uri uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, String> get jsonHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  /// Restaura sesión guardada tras reiniciar la app.
  Future<void> loadSavedSession() async {
    final token = await SessionPersistence.loadToken();
    if (token == null) return;
    _applyToken(token);
    _syncSessionStoreFromToken(token);
  }

  void setSessionToken(String token) {
    _applyToken(token);
    SessionPersistence.saveToken(_tokenFromCookie(_sessionCookie!)!);
    _syncSessionStoreFromToken(token);
  }

  void clearSession() {
    _sessionCookie = null;
    SessionPersistence.clear();
    SessionStore.instance.clear();
  }

  void _applyToken(String token) {
    _sessionCookie = 'smart_session=$token';
  }

  static String? _tokenFromCookie(String cookie) {
    const prefix = 'smart_session=';
    if (cookie.startsWith(prefix)) {
      return cookie.substring(prefix.length);
    }
    return cookie.isEmpty ? null : cookie;
  }

  void _syncSessionStoreFromToken(String token) {
    final rol = JwtSession.claim(token, 'rol');
    if (rol != null && rol.isNotEmpty) {
      SessionStore.instance.setRol(rol.trim());
    }
    final sub = JwtSession.claim(token, 'sub');
    if (sub != null && sub.isNotEmpty) {
      SessionStore.instance.setIdUsuario(sub);
    }
  }

  void absorbSessionFromResponse(http.Response response, {String? tokenFromBody}) {
    if (tokenFromBody != null && tokenFromBody.isNotEmpty) {
      setSessionToken(tokenFromBody);
      return;
    }
    _absorbSessionCookie(response);
  }

  void _absorbSessionCookie(http.Response response) {
    final candidates = <String>[];

    for (final entry in response.headers.entries) {
      if (entry.key.toLowerCase() == 'set-cookie') {
        candidates.add(entry.value);
      }
    }

    try {
      candidates.addAll(response.headersSplitValues['set-cookie'] ?? const []);
    } catch (_) {
      // headersSplitValues no disponible en versiones antiguas de http.
    }

    final raw = response.headers['set-cookie'];
    if (raw != null) candidates.add(raw);

    final cookiePattern = RegExp(r'smart_session=([^;]+)');
    for (final header in candidates) {
      final match = cookiePattern.firstMatch(header);
      if (match != null) {
        setSessionToken(match.group(1)!.trim());
        return;
      }
    }
  }

  Future<http.Response> post(
    String path, {
    required String body,
  }) async {
    final response = await _client.post(
      uri(path),
      headers: jsonHeaders,
      body: body,
    );
    _absorbSessionCookie(response);
    return response;
  }

  Future<http.Response> get(String path) async {
    final response = await _client.get(uri(path), headers: jsonHeaders);
    _absorbSessionCookie(response);
    return response;
  }

  Future<http.Response> put(
    String path, {
    required String body,
  }) async {
    final response = await _client.put(
      uri(path),
      headers: jsonHeaders,
      body: body,
    );
    _absorbSessionCookie(response);
    return response;
  }

  Future<http.Response> sendJson(
    String method,
    String path, {
    String? body,
  }) async {
    final request = http.Request(method, uri(path))
      ..headers.addAll(jsonHeaders);
    if (body != null) {
      request.body = body;
    }
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _absorbSessionCookie(response);
    return response;
  }

  void close() => _client.close();
}
