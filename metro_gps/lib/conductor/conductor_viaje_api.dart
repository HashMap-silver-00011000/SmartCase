import 'dart:convert';

import '../admin/clinica_api.dart';
import '../core/api_client.dart';
import 'models/viaje.dart';

class ConductorViajeApiResult<T> {
  const ConductorViajeApiResult({
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  final int statusCode;
  final T? data;
  final String? errorMessage;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ConductorViajeApi {
  ConductorViajeApi({ApiClient? client})
      : _client = client ?? ClinicaApi.sharedClient;

  final ApiClient _client;

  // ── rutas ──────────────────────────────────────────────────────────────────
  static const _tareasViaje       = '/api/app/conductor/viaje/tareas-viaje';
  static const _actualizarEstado  = '/api/app/conductor/viaje/actualizar-estado-viaje';

  // ── helpers ────────────────────────────────────────────────────────────────
  static String? _errorFromBody(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in ['error', 'message', 'msg']) {
          final v = decoded[key];
          if (v is String && v.isNotEmpty) return v;
        }
      }
    } on FormatException {
      return body;
    }
    return null;
  }

  // ── métodos ────────────────────────────────────────────────────────────────

  /// GET: el backend usa el `sub` del JWT (cookie) como id del conductor.
  Future<ConductorViajeApiResult<List<Viaje>>> listarMisViajes() async {
    try {
      final response = await _client.get(_tareasViaje);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.trim();
        if (body.isEmpty || body == 'null') {
          return ConductorViajeApiResult(
            statusCode: response.statusCode,
            data: const [],
          );
        }
        final decoded = jsonDecode(body);
        if (decoded == null) {
          return ConductorViajeApiResult(
            statusCode: response.statusCode,
            data: const [],
          );
        }
        if (decoded is List) {
          final lista = <Viaje>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              lista.add(Viaje.fromJson(item));
            } else if (item is Map) {
              lista.add(Viaje.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          return ConductorViajeApiResult(
            statusCode: response.statusCode,
            data: lista,
          );
        }
      }

      return ConductorViajeApiResult(
        statusCode: response.statusCode,
        errorMessage: _errorFromBody(response.body) ??
            'No se pudieron cargar tus viajes (${response.statusCode})',
      );
    } catch (e) {
      return ConductorViajeApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }

  /// PUT: actualiza el estado del viaje ('transito', 'entregado', 'muestra comprometida').
  Future<ConductorViajeApiResult<void>> actualizarEstadoViaje({
    required String idViaje,
    required String estado,
  }) async {
    try {
      final response = await _client.put(
        _actualizarEstado,
        body: jsonEncode({
          'id_viaje': idViaje,
          'estado_viaje': estado,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ConductorViajeApiResult(statusCode: response.statusCode);
      }
      return ConductorViajeApiResult(
        statusCode: response.statusCode,
        errorMessage: _errorFromBody(response.body) ??
            'Error al actualizar estado (${response.statusCode})',
      );
    } catch (e) {
      return ConductorViajeApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }
}