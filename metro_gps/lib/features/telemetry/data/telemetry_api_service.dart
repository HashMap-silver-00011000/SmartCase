import 'package:metro_gps/core/network/api_client.dart';
import 'package:metro_gps/features/telemetry/domain/models/ruta_model.dart';
import 'package:metro_gps/features/telemetry/domain/models/telemetry_point.dart';

class TelemetryApiService {
  TelemetryApiService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<RutaModel>> getRutas() async {
    final list = await _apiClient.getList('/rutas');
    return list
        .map((e) => RutaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TelemetryPoint>> getTelemetria({String? idRuta}) async {
    final path = idRuta == null || idRuta.isEmpty
        ? '/telemetria'
        : '/telemetria?ruta=$idRuta';
    final list = await _apiClient.getList(path);
    return list
        .map((e) => TelemetryPoint.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
