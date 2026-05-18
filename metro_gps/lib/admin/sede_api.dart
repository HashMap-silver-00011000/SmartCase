import 'dart:convert';

import '../core/api_client.dart';
import 'clinica_api.dart';
import 'models/sede.dart';

class SedeApiResult<T> {
  const SedeApiResult({
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  final int statusCode;
  final T? data;
  final String? errorMessage;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class SedeApi {
  SedeApi({ApiClient? client}) : _client = client ?? ClinicaApi.sharedClient;

  final ApiClient _client;

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

  Future<SedeApiResult<List<Sede>>> listarPorClinica(String idClinica) async {
    try {
      final response = await _client.get(
        '/api/app/panel-admin/clinica/sede/lista?id_clinica=$idClinica',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.trim();
        if (body.isEmpty || body == 'null') {
          return SedeApiResult(
            statusCode: response.statusCode,
            data: const [],
          );
        }
        final decoded = jsonDecode(body);
        if (decoded == null) {
          return SedeApiResult(
            statusCode: response.statusCode,
            data: const [],
          );
        }
        if (decoded is List) {
          final lista = <Sede>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              lista.add(Sede.fromJson(item));
            } else if (item is Map) {
              lista.add(Sede.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          return SedeApiResult(
            statusCode: response.statusCode,
            data: lista,
          );
        }
      }
      return SedeApiResult(
        statusCode: response.statusCode,
        errorMessage:
            _errorFromBody(response.body) ?? 'No se pudo cargar las sedes',
      );
    } catch (e) {
      return SedeApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión al listar sedes: $e',
      );
    }
  }

  Future<SedeApiResult<void>> crear(SedeInput input) async {
    try {
      final response = await _client.post(
        '/api/app/panel-admin/clinica/sede/crear',
        body: jsonEncode(input.toJson()),
      );
      return SedeApiResult(
        statusCode: response.statusCode,
        errorMessage: response.statusCode >= 200 && response.statusCode < 300
            ? null
            : _errorFromBody(response.body) ?? 'No se pudo crear la sede',
      );
    } catch (e) {
      return SedeApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión al crear la sede: $e',
      );
    }
  }

  Future<SedeApiResult<Sede>> obtener(String idSede) async {
    final response = await _client.sendJson(
      'GET',
      '/api/app/panel-admin/clinica/sede/obtener',
      body: jsonEncode({
        'id_sede': idSede,
        'IDSede': idSede,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return SedeApiResult(
          statusCode: response.statusCode,
          data: Sede.fromJson(decoded),
        );
      }
    }
    return SedeApiResult(
      statusCode: response.statusCode,
      errorMessage: _errorFromBody(response.body) ?? 'Sede no encontrada',
    );
  }

  Future<SedeApiResult<void>> actualizar(Sede sede) async {
    final response = await _client.put(
      '/api/app/panel-admin/clinica/sede/actualizar',
      body: jsonEncode(sede.toBackendJson()),
    );
    return SedeApiResult(
      statusCode: response.statusCode,
      errorMessage: response.statusCode >= 200 && response.statusCode < 300
          ? null
          : _errorFromBody(response.body) ?? 'No se pudo actualizar',
    );
  }

  Future<SedeApiResult<void>> eliminar(Sede sede) async {
    final response = await _client.sendJson(
      'DELETE',
      '/api/app/panel-admin/clinica/sede/borrar',
      body: jsonEncode(sede.toBackendJson()),
    );
    return SedeApiResult(
      statusCode: response.statusCode,
      errorMessage: response.statusCode >= 200 && response.statusCode < 300
          ? null
          : _errorFromBody(response.body) ?? 'No se pudo eliminar',
    );
  }
}
