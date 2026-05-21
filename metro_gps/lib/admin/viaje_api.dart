import 'dart:convert';

import '../conductor/models/viaje.dart';
import '../core/api_client.dart';
import 'clinica_api.dart';
import 'models/viaje.dart' show ViajeInput;

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

  Future<ViajeApiResult<List<Viaje>>> listarPorEstado(String estado) async {
    try {
      final response = await _client.get(
        '/api/app/panel-admin/viaje/viajes-estado?estado=$estado',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.trim();
        if (body.isEmpty || body == 'null') {
          return ViajeApiResult(statusCode: response.statusCode, data: const []);
        }
        final decoded = jsonDecode(body);
        if (decoded is List) {
          final lista = <Viaje>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              lista.add(Viaje.fromJson(item));
            } else if (item is Map) {
              lista.add(Viaje.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          return ViajeApiResult(statusCode: response.statusCode, data: lista);
        }
      }
      return ViajeApiResult(
        statusCode: response.statusCode,
        errorMessage: _errorFromBody(response.body) ?? 'No se pudieron cargar viajes',
      );
    } catch (e) {
      return ViajeApiResult(statusCode: 0, errorMessage: 'Error de conexión: $e');
    }
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
