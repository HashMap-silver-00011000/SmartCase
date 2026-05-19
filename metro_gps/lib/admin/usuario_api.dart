import 'dart:convert';

import '../core/api_client.dart';
import 'clinica_api.dart';
import 'models/usuario.dart';

class UsuarioApiResult<T> {
  const UsuarioApiResult({
    required this.statusCode,
    this.data,
    this.errorMessage,
  });

  final int statusCode;
  final T? data;
  final String? errorMessage;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class UsuarioApi {
  UsuarioApi({ApiClient? client}) : _client = client ?? ClinicaApi.sharedClient;

  final ApiClient _client;

  Future<UsuarioApiResult<List<UsuarioConductor>>> listarConductores() async {
    try {
      final response = await _client.get(
        '/api/app/panel-admin/usuario/conductores/lista',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final lista = <UsuarioConductor>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              lista.add(UsuarioConductor.fromJson(item));
            } else if (item is Map) {
              lista.add(
                UsuarioConductor.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
          return UsuarioApiResult(
            statusCode: response.statusCode,
            data: lista,
          );
        }
      }
      return UsuarioApiResult(
        statusCode: response.statusCode,
        errorMessage: 'No se pudo cargar la lista de conductores',
      );
    } catch (e) {
      return UsuarioApiResult(
        statusCode: 0,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }
}
