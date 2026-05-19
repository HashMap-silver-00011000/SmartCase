import 'dart:convert';

import '../core/api_client.dart';
import 'clinica_api.dart';
import 'models/ambulancia.dart';

class AmbulanciaApiResult<T> {
  const AmbulanciaApiResult({
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  final int statusCode;
  final T? data;
  final String? errorMessage;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class AmbulanciaApi {
  AmbulanciaApi({ApiClient? client}) : _client = client ?? ClinicaApi.sharedClient;

  final ApiClient _client;

  static const _base = '/api/app/panel-admin/ambulancia';

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

  Future<AmbulanciaApiResult<List<Ambulancia>>> listar() async {
    try {
      final response = await _client.get('$_base/lista');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.trim();
        if (body.isEmpty || body == 'null') {
          return AmbulanciaApiResult(
            statusCode: response.statusCode,
            data: const [],
          );
        }
        final decoded = jsonDecode(body);
        if (decoded == null) {
          return AmbulanciaApiResult(
            statusCode: response.statusCode,
            data: const [],
          );
        }
        if (decoded is List) {
          final lista = <Ambulancia>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              lista.add(Ambulancia.fromJson(item));
            } else if (item is Map) {
              lista.add(Ambulancia.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          return AmbulanciaApiResult(
            statusCode: response.statusCode,
            data: lista,
          );
        }
      }
      return AmbulanciaApiResult(
        statusCode: response.statusCode,
        errorMessage: _errorFromBody(response.body) ??
            'No se pudo cargar ambulancias (${response.statusCode})',
      );
    } catch (e) {
      return AmbulanciaApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión al listar ambulancias: $e',
      );
    }
  }

  Future<AmbulanciaApiResult<void>> crear(AmbulanciaInput input) async {
    try {
      final response = await _client.post(
        '$_base/crear',
        body: jsonEncode(input.toJson()),
      );
      return AmbulanciaApiResult(
        statusCode: response.statusCode,
        errorMessage: response.statusCode >= 200 && response.statusCode < 300
            ? null
            : _errorFromBody(response.body) ?? 'No se pudo crear',
      );
    } catch (e) {
      return AmbulanciaApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }

  Future<AmbulanciaApiResult<void>> actualizar(Ambulancia ambulancia) async {
    try {
      final response = await _client.put(
        '$_base/actualizar/${ambulancia.idAmbulancia}',
        body: jsonEncode(AmbulanciaInput(
          placa: ambulancia.placa,
          tipo: ambulancia.tipo,
        ).toJson()),
      );
      return AmbulanciaApiResult(
        statusCode: response.statusCode,
        errorMessage: response.statusCode >= 200 && response.statusCode < 300
            ? null
            : _errorFromBody(response.body) ?? 'No se pudo actualizar',
      );
    } catch (e) {
      return AmbulanciaApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }

  Future<AmbulanciaApiResult<void>> eliminar(String idAmbulancia) async {
    try {
      final response = await _client.sendJson(
        'DELETE',
        '$_base/borrar/$idAmbulancia',
      );
      return AmbulanciaApiResult(
        statusCode: response.statusCode,
        errorMessage: response.statusCode >= 200 && response.statusCode < 300
            ? null
            : _errorFromBody(response.body) ?? 'No se pudo eliminar',
      );
    } catch (e) {
      return AmbulanciaApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }
}
