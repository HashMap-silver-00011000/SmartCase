import 'dart:convert';

import '../admin/clinica_api.dart';
import '../conductor/models/viaje.dart';
import '../core/api_client.dart';

class ReceptorViajeApiResult<T> {
  const ReceptorViajeApiResult({
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  final int statusCode;
  final T? data;
  final String? errorMessage;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ReceptorViajeApi {
  ReceptorViajeApi({ApiClient? client})
      : _client = client ?? ClinicaApi.sharedClient;

  final ApiClient _client;

  static const _tareasViaje = '/api/app/medico/viaje/tareas-viaje';

  Future<ReceptorViajeApiResult<List<Viaje>>> listarMisViajes() async {
    try {
      final response = await _client.get(_tareasViaje);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.trim();
        if (body.isEmpty || body == 'null') {
          return ReceptorViajeApiResult(
            statusCode: response.statusCode,
            data: const [],
          );
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
          return ReceptorViajeApiResult(
            statusCode: response.statusCode,
            data: lista,
          );
        }
      }
      return ReceptorViajeApiResult(
        statusCode: response.statusCode,
        errorMessage: 'No se pudieron cargar viajes (${response.statusCode})',
      );
    } catch (e) {
      return ReceptorViajeApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }
}
