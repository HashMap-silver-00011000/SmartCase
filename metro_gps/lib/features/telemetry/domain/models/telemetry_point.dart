import 'package:latlong2/latlong.dart';

class TelemetryPoint {
  const TelemetryPoint({
    required this.idTelemetria,
    required this.idBus,
    required this.lat,
    required this.long,
    required this.fecha,
    this.idRuta,
  });

  final String idTelemetria;
  final String idBus;
  final double lat;
  final double long;
  final DateTime fecha;
  final String? idRuta;

  LatLng get latLng => LatLng(lat, long);

  factory TelemetryPoint.fromJson(Map<String, dynamic> json) {
    return TelemetryPoint(
      idTelemetria: json['telemetria']?.toString() ?? json['id_telemetria']?.toString() ?? '',
      idBus: json['id_bus']?.toString() ?? '',
      lat: _toDouble(json['lat']),
      long: _toDouble(json['long']),
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? '') ?? DateTime.now(),
      idRuta: json['id_ruta']?.toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }
}
