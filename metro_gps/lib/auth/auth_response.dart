import 'dart:convert';

import 'package:http/http.dart' as http;

/// Respuesta normalizada de `/api/login` o `/api/register`.
class AuthResponse {
  const AuthResponse({
    required this.statusCode,
    required this.rawBody,
    this.jsonBody,
  });

  final int statusCode;
  final String rawBody;
  final Map<String, dynamic>? jsonBody;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  factory AuthResponse.fromHttpResponse(http.Response response) {
    Map<String, dynamic>? jsonBody;
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          jsonBody = decoded;
        }
      } on FormatException {
        // Cuerpo no JSON; se deja jsonBody en null.
      }
    }
    return AuthResponse(
      statusCode: response.statusCode,
      rawBody: response.body,
      jsonBody: jsonBody,
    );
  }

  /// Mensaje legible para errores típicos (`error`, `message`, etc.).
  String? get errorMessage {
    final data = jsonBody;
    if (data == null) return rawBody.isEmpty ? null : rawBody;
    for (final key in ['error', 'message', 'msg', 'detail']) {
      final v = data[key];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }
}
