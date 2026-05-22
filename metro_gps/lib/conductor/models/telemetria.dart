class TelemetriaRegistro {
  const TelemetriaRegistro({
    required this.idTelemetria,
    required this.idViaje,
    required this.temperaturaInterna,
    required this.latitud,
    required this.longitud,
    required this.fuerzaG,
    required this.registradoEn,
    this.alertaGenerada,
    this.enviadoAlServidor = false,
    this.desdeBluetooth = false,
    this.tempAmbiente,
    this.humedad,
    this.lux,
    this.altitud,
  });

  final String idTelemetria;
  final String idViaje;
  final double temperaturaInterna;
  final double latitud;
  final double longitud;
  final double fuerzaG;
  final DateTime registradoEn;
  final String? alertaGenerada;
  final bool enviadoAlServidor;
  final bool desdeBluetooth;
  final double? tempAmbiente;
  final double? humedad;
  final double? lux;
  final double? altitud;

  Map<String, dynamic> toBackendJson() => toWsJson();

  /// Payload JSON para WebSocket (modelo Go `Telemetria`).
  Map<String, dynamic> toWsJson() => {
        'id_telemetria': idTelemetria,
        'id_viaje': idViaje,
        'temperatura_interna': temperaturaInterna,
        'temperatura_ambiente': tempAmbiente ?? 0,
        'humedad': humedad ?? 0,
        'lux': lux ?? 0,
        'latitud_actual': latitud,
        'longitud_actual': longitud,
        'altitud': altitud ?? 0,
        'fuerza_g_impacto': fuerzaG,
        if (alertaGenerada != null && alertaGenerada!.isNotEmpty)
          'alerta_generada': alertaGenerada,
        'registrado_en': registradoEn.toUtc().toIso8601String(),
        'desde_bluetooth': desdeBluetooth,
      };

  factory TelemetriaRegistro.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return TelemetriaRegistro(
      idTelemetria: json['id_telemetria']?.toString() ?? '',
      idViaje: json['id_viaje']?.toString() ?? '',
      temperaturaInterna: toDouble(json['temperatura_interna']),
      latitud: toDouble(json['latitud_actual']),
      longitud: toDouble(json['longitud_actual']),
      fuerzaG: toDouble(json['fuerza_g_impacto']),
      registradoEn: parseDate(json['registrado_en']),
      alertaGenerada: json['alerta_generada']?.toString(),
      enviadoAlServidor: true,
      desdeBluetooth: json['desde_bluetooth'] == true,
      tempAmbiente: json['temperatura_ambiente'] != null
          ? toDouble(json['temperatura_ambiente'])
          : null,
      humedad:
          json['humedad'] != null ? toDouble(json['humedad']) : null,
      lux: json['lux'] != null ? toDouble(json['lux']) : null,
      altitud:
          json['altitud'] != null ? toDouble(json['altitud']) : null,
    );
  }

  TelemetriaRegistro copyWith({bool? enviadoAlServidor}) => TelemetriaRegistro(
        idTelemetria: idTelemetria,
        idViaje: idViaje,
        temperaturaInterna: temperaturaInterna,
        latitud: latitud,
        longitud: longitud,
        fuerzaG: fuerzaG,
        registradoEn: registradoEn,
        alertaGenerada: alertaGenerada,
        enviadoAlServidor: enviadoAlServidor ?? this.enviadoAlServidor,
        desdeBluetooth: desdeBluetooth,
        tempAmbiente: tempAmbiente,
        humedad: humedad,
        lux: lux,
        altitud: altitud,
      );
}

class TelemetriaInput {
  const TelemetriaInput({
    required this.temperaturaInterna,
    required this.latitud,
    required this.longitud,
    required this.fuerzaG,
    this.idTelemetria,
    this.alertaGenerada,
    this.desdeBluetooth = false,
    this.tempAmbiente,
    this.humedad,
    this.lux,
    this.altitud,
  });

  final String? idTelemetria;
  final double temperaturaInterna;
  final double latitud;
  final double longitud;
  final double fuerzaG;
  final String? alertaGenerada;
  final bool desdeBluetooth;
  final double? tempAmbiente;
  final double? humedad;
  final double? lux;
  final double? altitud;
}
