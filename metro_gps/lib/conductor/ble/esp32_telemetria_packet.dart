import 'dart:convert';

import '../models/telemetria.dart';

/// Lectura en vivo enviada por el ESP32 por Bluetooth clásico (SerialBT.println).
///
/// Soporta el JSON actual del firmware:
/// `temperatura_interna`, `temperatura_ambiente`, `humedad`, `lux`,
/// `fuerza_g_impacto`, `latitud_actual`, `longitud_actual`, `altitud`
///
/// y el formato anterior (`t_int`, `t_amb`, `acc`, `lat`, `long`, …).
class Esp32TelemetriaPacket {
  const Esp32TelemetriaPacket({
    this.idBus,
    required this.tInt,
    required this.tAmb,
    required this.hum,
    required this.lux,
    required this.acc,
    required this.lat,
    required this.lng,
    required this.alt,
    required this.recibidoEn,
  });

  final String? idBus;
  final double tInt;
  final double tAmb;
  final double hum;
  final double lux;
  final double acc;
  final double lat;
  final double lng;
  final double alt;
  final DateTime recibidoEn;

  static double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double _firstNum(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key)) return _num(json[key]);
    }
    return 0;
  }

  factory Esp32TelemetriaPacket.fromJson(Map<String, dynamic> json) {
    return Esp32TelemetriaPacket(
      idBus: json['id_bus']?.toString(),
      tInt: _firstNum(json, ['temperatura_interna', 't_int']),
      tAmb: _firstNum(json, ['temperatura_ambiente', 't_amb']),
      hum: _firstNum(json, ['humedad', 'hum']),
      lux: _num(json['lux']),
      acc: _firstNum(json, ['fuerza_g_impacto', 'acc']),
      lat: _firstNum(json, ['latitud_actual', 'lat']),
      lng: _firstNum(json, ['longitud_actual', 'long', 'lon', 'lng']),
      alt: _num(json['altitud'] ?? json['alt']),
      recibidoEn: DateTime.now(),
    );
  }

  factory Esp32TelemetriaPacket.fromJsonLine(String line) {
    final map = jsonDecode(line) as Map<String, dynamic>;
    return Esp32TelemetriaPacket.fromJson(map);
  }

  String? _alertaPorUmbrales() {
    if (tInt >= 8) return 'Temperatura interna alta';
    if (acc >= 15) return 'Impacto / vibración elevada';
    if (hum >= 85) return 'Humedad alta';
    return null;
  }

  TelemetriaInput toTelemetriaInput({String? idTelemetria}) => TelemetriaInput(
        idTelemetria: idTelemetria,
        temperaturaInterna: tInt,
        latitud: lat,
        longitud: lng,
        fuerzaG: acc,
        alertaGenerada: _alertaPorUmbrales(),
        tempAmbiente: tAmb,
        humedad: hum,
        lux: lux,
        altitud: alt,
        desdeBluetooth: true,
      );
}
