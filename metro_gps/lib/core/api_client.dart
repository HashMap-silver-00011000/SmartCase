import 'package:http/http.dart' as http;

import 'api_constants.dart';

/// Cliente HTTP compartido que conserva la cookie `smart_session` del login.
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

  void clearSession() => _sessionCookie = null;

  void _absorbSessionCookie(http.Response response) {
    final candidates = <String>[
      ...?response.headersSplitValues['set-cookie'],
      if (response.headers['set-cookie'] != null) response.headers['set-cookie']!,
    ];
    for (final raw in candidates) {
      final part = raw.split(';').first.trim();
      if (part.startsWith('smart_session=')) {
        _sessionCookie = part;
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
