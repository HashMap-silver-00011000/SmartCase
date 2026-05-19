import 'dart:convert';

import '../core/api_client.dart';
import 'clinica_api.dart';
import 'models/viaje.dart';

class ViajeApiResult<T> {
  const ViajeApiResult({
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  final int statusCode;
  final T? data;
  final String? errorMessage;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ViajeApi {
  ViajeApi({ApiClient? client}) : _client = client ?? ClinicaApi.sharedClient;

  final ApiClient _client;

  static String? _errorFromBody(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['error', 'message', 'msg', 'mensaje', 'Mensaje']) {
          final v = decoded[key];
          if (v is String && v.isNotEmpty) return v;
        }
      }
    } on FormatException {
      return body;
    }
    return null;
  }

  Future<ViajeApiResult<void>> crear(ViajeInput input) async {
    try {
      final response = await _client.post(
        '/api/app/panel-admin/viaje/crear',
        body: jsonEncode(input.toJson()),
      );
      return ViajeApiResult(
        statusCode: response.statusCode,
        errorMessage: response.statusCode >= 200 && response.statusCode < 300
            ? null
            : _errorFromBody(response.body) ?? 'No se pudo crear el viaje',
      );
    } catch (e) {
      return ViajeApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }
}
