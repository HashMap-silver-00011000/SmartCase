import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_constants.dart';
import 'auth_response.dart';
import 'models/auth_models.dart';

/// Cliente de las rutas públicas de autenticación del backend.
class AuthApi {
  AuthApi({
    http.Client? httpClient,
    String? baseUrl,
  })  : _client = httpClient ?? http.Client(),
        _baseUrl = _trimTrailingSlash(baseUrl ?? ApiConstants.baseUrl);

  final http.Client _client;
  final String _baseUrl;

  static String _trimTrailingSlash(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1);
    }
    return url;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static const _headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  /// POST `/api/login`
  Future<AuthResponse> login(LoginInput input) async {
    final response = await _client.post(
      _uri('/api/login'),
      headers: _headers,
      body: jsonEncode(input.toJson()),
    );
    return AuthResponse.fromHttpResponse(response);
  }

  /// POST `/api/register`
  Future<AuthResponse> registro(RegistroInput input) async {
    final response = await _client.post(
      _uri('/api/register'),
      headers: _headers,
      body: jsonEncode(input.toJson()),
    );
    return AuthResponse.fromHttpResponse(response);
  }

  void close() {
    _client.close();
  }
}
