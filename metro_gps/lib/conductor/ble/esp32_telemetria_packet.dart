import 'dart:convert';

import '../models/telemetria.dart';

/// Lectura en vivo enviada por el ESP32 por Bluetooth clásico (SerialBT.println).
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

  factory Esp32TelemetriaPacket.fromJson(Map<String, dynamic> json) {
    return Esp32TelemetriaPacket(
      idBus: json['id_bus']?.toString(),
      tInt: _num(json['t_int']),
      tAmb: _num(json['t_amb']),
      hum: _num(json['hum']),
      lux: _num(json['lux']),
      acc: _num(json['acc']),
      lat: _num(json['lat']),
      lng: _num(json['long'] ?? json['lon'] ?? json['lng']),
      alt: _num(json['alt']),
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

  TelemetriaInput toTelemetriaInput() => TelemetriaInput(
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
