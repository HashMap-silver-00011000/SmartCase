import 'dart:convert';

import '../core/api_client.dart';
import 'clinica_api.dart';
import 'models/smartcase.dart';

class SmartCaseApiResult<T> {
  const SmartCaseApiResult({
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  final int statusCode;
  final T? data;
  final String? errorMessage;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class SmartCaseApi {
  SmartCaseApi({ApiClient? client}) : _client = client ?? ClinicaApi.sharedClient;

  final ApiClient _client;

  static const _base = '/api/app/panel-admin/smartcase';

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

  Future<SmartCaseApiResult<List<SmartCase>>> listar() async {
    try {
      final response = await _client.get('$_base/lista');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final lista = <SmartCase>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              lista.add(SmartCase.fromJson(item));
            } else if (item is Map) {
              lista.add(SmartCase.fromJson(Map<String, dynamic>.from(item)));
            }
          }
          return SmartCaseApiResult(
            statusCode: response.statusCode,
            data: lista,
          );
        }
      }
      return SmartCaseApiResult(
        statusCode: response.statusCode,
        errorMessage:
            _errorFromBody(response.body) ?? 'No se pudo cargar las cajas',
      );
    } catch (e) {
      return SmartCaseApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }

  Future<SmartCaseApiResult<void>> crear(SmartCaseInput input) async {
    try {
      final response = await _client.post(
        '$_base/crear',
        body: jsonEncode(input.toJson()),
      );
      return SmartCaseApiResult(
        statusCode: response.statusCode,
        errorMessage: response.statusCode >= 200 && response.statusCode < 300
            ? null
            : _errorFromBody(response.body) ?? 'No se pudo crear',
      );
    } catch (e) {
      return SmartCaseApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }

  Future<SmartCaseApiResult<void>> actualizar(SmartCase caja) async {
    try {
      final response = await _client.put(
        '$_base/actualizar/${caja.idCaja}',
        body: jsonEncode(SmartCaseInput(
          estadoSolenoide: caja.estadoSolenoide,
          organo: caja.organo,
        ).toJson()),
      );
      return SmartCaseApiResult(
        statusCode: response.statusCode,
        errorMessage: response.statusCode >= 200 && response.statusCode < 300
            ? null
            : _errorFromBody(response.body) ?? 'No se pudo actualizar',
      );
    } catch (e) {
      return SmartCaseApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }

  Future<SmartCaseApiResult<void>> eliminar(String idCaja) async {
    try {
      final response = await _client.sendJson(
        'DELETE',
        '$_base/borrar/$idCaja',
      );
      return SmartCaseApiResult(
        statusCode: response.statusCode,
        errorMessage: response.statusCode >= 200 && response.statusCode < 300
            ? null
            : _errorFromBody(response.body) ?? 'No se pudo eliminar',
      );
    } catch (e) {
      return SmartCaseApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }
}
