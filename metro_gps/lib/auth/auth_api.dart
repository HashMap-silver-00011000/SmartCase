import 'dart:convert';

import 'package:http/http.dart' as http;

import '../admin/clinica_api.dart';
import '../core/api_client.dart';
import '../core/api_constants.dart';
import '../core/jwt_session.dart';
import '../core/session_store.dart';
import 'auth_response.dart';
import 'models/auth_models.dart';

/// Cliente de las rutas públicas de autenticación del backend.
class AuthApi {
  AuthApi({
    http.Client? httpClient,
    String? baseUrl,
    ApiClient? apiClient,
  }) : _client = apiClient ?? ClinicaApi.sharedClient;

  final ApiClient _client;

  static const _headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  /// POST `/api/login`
  Future<AuthResponse> login(LoginInput input) async {
    final response = await _client.post(
      '/api/login',
      body: jsonEncode(input.toJson()),
    );
    final auth = AuthResponse.fromHttpResponse(response);
    if (auth.isSuccess) {
      _client.absorbSessionFromResponse(
        response,
        tokenFromBody: auth.token,
      );
      final rol = auth.rol ?? JwtSession.rolFromSessionCookie(_client.sessionCookie);
      if (rol != null && rol.isNotEmpty) {
        SessionStore.instance.setRol(rol.trim());
      }
    } else {
      await _client.clearSession();
    }
    return auth;
  }

  /// POST `/api/register`
  Future<AuthResponse> registro(RegistroInput input) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/register'),
      headers: _headers,
      body: jsonEncode(input.toJson()),
    );
    return AuthResponse.fromHttpResponse(response);
  }

  void close() {
    // El cliente compartido lo cierra la app al salir si hace falta.
  }
}
