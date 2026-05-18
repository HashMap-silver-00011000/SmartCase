import 'dart:convert';

import '../core/api_client.dart';
import 'models/clinica.dart';

class ClinicaApiResult<T> {
  const ClinicaApiResult({
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  final int statusCode;
  final T? data;
  final String? errorMessage;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ClinicaApi {
  ClinicaApi({ApiClient? client}) : _client = client ?? _sharedClient;

  static final ApiClient _sharedClient = ApiClient();

  final ApiClient _client;

  static ApiClient get sharedClient => _sharedClient;

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

  Future<ClinicaApiResult<List<Clinica>>> listar() async {
    final response = await _client.get('/api/app/panel-admin/clinica/lista');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        final lista = decoded
            .whereType<Map<String, dynamic>>()
            .map(Clinica.fromJson)
            .toList();
        return ClinicaApiResult(
          statusCode: response.statusCode,
          data: lista,
        );
      }
    }
    return ClinicaApiResult(
      statusCode: response.statusCode,
      errorMessage: _errorFromBody(response.body) ?? 'No se pudo cargar la lista',
    );
  }

  Future<ClinicaApiResult<void>> crear(ClinicaInput input) async {
    final response = await _client.post(
      '/api/app/panel-admin/clinica/crear',
      body: jsonEncode(input.toJson()),
    );
    return ClinicaApiResult(
      statusCode: response.statusCode,
      errorMessage: response.statusCode >= 200 && response.statusCode < 300
          ? null
          : _errorFromBody(response.body) ?? 'No se pudo crear la clínica',
    );
  }

  Future<ClinicaApiResult<Clinica>> obtener(String idClinica) async {
    final response = await _client.sendJson(
      'GET',
      '/api/app/panel-admin/clinica/obtener',
      body: jsonEncode({'id_clinica': idClinica}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return ClinicaApiResult(
          statusCode: response.statusCode,
          data: Clinica.fromJson(decoded),
        );
      }
    }
    return ClinicaApiResult(
      statusCode: response.statusCode,
      errorMessage: _errorFromBody(response.body) ?? 'Clínica no encontrada',
    );
  }

  Future<ClinicaApiResult<void>> actualizar(Clinica clinica) async {
    final response = await _client.put(
      '/api/app/panel-admin/clinica/actualizar',
      body: jsonEncode(clinica.toJson()),
    );
    return ClinicaApiResult(
      statusCode: response.statusCode,
      errorMessage: response.statusCode >= 200 && response.statusCode < 300
          ? null
          : _errorFromBody(response.body) ?? 'No se pudo actualizar',
    );
  }

  Future<ClinicaApiResult<void>> eliminar(String idClinica) async {
    final response = await _client.sendJson(
      'DELETE',
      '/api/app/panel-admin/clinica/borrar',
      body: jsonEncode({'id_clinica': idClinica}),
    );
    return ClinicaApiResult(
      statusCode: response.statusCode,
      errorMessage: response.statusCode >= 200 && response.statusCode < 300
          ? null
          : _errorFromBody(response.body) ?? 'No se pudo eliminar',
    );
  }
}
