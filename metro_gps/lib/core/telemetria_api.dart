import 'dart:convert';

import '../admin/clinica_api.dart';
import '../conductor/models/telemetria.dart';
import 'api_client.dart';
import 'telemetria_ws_paths.dart';

class TelemetriaApi {
  TelemetriaApi({ApiClient? client}) : _client = client ?? ClinicaApi.sharedClient;

  final ApiClient _client;

  Future<List<TelemetriaRegistro>> listarPorViaje({
    required String idViaje,
    required TelemetriaWsRol rol,
  }) async {
    final path =
        '${TelemetriaWsPaths.historialRest(rol)}?id_viaje=$idViaje';
    final response = await _client.get(path);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return [];
    }
    final body = response.body.trim();
    if (body.isEmpty || body == 'null') return [];
    final decoded = jsonDecode(body);
    if (decoded is! List) return [];

    final lista = <TelemetriaRegistro>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        lista.add(TelemetriaRegistro.fromJson(item));
      } else if (item is Map) {
        lista.add(TelemetriaRegistro.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return lista;
  }
}
