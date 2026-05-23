import 'dart:convert';

import '../admin/clinica_api.dart';
import '../core/api_client.dart';

class ConductorPinApiResult {
  const ConductorPinApiResult({
    required this.statusCode,
    this.valido,
    this.errorMessage,
  });

  final int statusCode;
  final bool? valido;
  final String? errorMessage;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ConductorPinApi {
  ConductorPinApi({ApiClient? client})
      : _client = client ?? ClinicaApi.sharedClient;

  final ApiClient _client;

  static const _comprobarPin = '/api/app/conductor/viaje/pin-desbloqueo';

  Future<ConductorPinApiResult> comprobarPin({
    required String idViaje,
    required String pinEntrega,
  }) async {
    try {
      final response = await _client.post(
        _comprobarPin,
        body: jsonEncode({
          'id_viaje': idViaje,
          'pin_entrega': pinEntrega,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final valor = decoded['Valor'];
        return ConductorPinApiResult(
          statusCode: response.statusCode,
          valido: valor is bool ? valor : false,
        );
      }

      String? mensaje;
      try {
        final decoded = jsonDecode(response.body);
        mensaje = decoded['error'] as String?;
      } catch (_) {}

      return ConductorPinApiResult(
        statusCode: response.statusCode,
        errorMessage: mensaje ?? 'Error al comprobar el PIN (${response.statusCode})',
      );
    } catch (e) {
      return ConductorPinApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }
}