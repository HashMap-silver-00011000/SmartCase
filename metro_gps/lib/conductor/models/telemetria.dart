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

  // Actualizado para enviar los nuevos sensores hacia tu backend en Go
  Map<String, dynamic> toBackendJson() => {
        'id_viaje': idViaje,
        'temperatura_interna': temperaturaInterna,
        'latitud_actual': latitud,
        'longitud_actual': longitud,
        'fuerza_g_impacto': fuerzaG,
        'temperatura_ambiente': tempAmbiente,
        'humedad': humedad,
        'lux': lux,
        'altitud': altitud,
        'desde_bluetooth': desdeBluetooth,
        if (alertaGenerada != null && alertaGenerada!.isNotEmpty)
          'alerta_generada': alertaGenerada,
      };
}

class TelemetriaInput {
  const TelemetriaInput({
    required this.temperaturaInterna,
    required this.latitud,
    required this.longitud,
    required this.fuerzaG,
    this.alertaGenerada,
    this.desdeBluetooth = false,
    this.tempAmbiente,
    this.humedad,
    this.lux,
    this.altitud,
  });

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

  // --- FACTORY AÑADIDO PARA PARSEAR EL JSON DEL ESP32 ---
  factory TelemetriaInput.fromJson(Map<String, dynamic> json) {
    // Usamos (json['clave'] as num?)?.toDouble() para garantizar que si el ESP32 
    // envía un entero (ej. 0 en vez de 0.0), Dart no lance una excepción de casteo.
    return TelemetriaInput(
      temperaturaInterna: (json['temperatura_interna'] as num?)?.toDouble() ?? 0.0,
      latitud: (json['latitud_actual'] as num?)?.toDouble() ?? 0.0,
      longitud: (json['longitud_actual'] as num?)?.toDouble() ?? 0.0,
      fuerzaG: (json['fuerza_g_impacto'] as num?)?.toDouble() ?? 0.0,
      tempAmbiente: (json['temperatura_ambiente'] as num?)?.toDouble() ?? 0.0,
      humedad: (json['humedad'] as num?)?.toDouble() ?? 0.0,
      lux: (json['lux'] as num?)?.toDouble() ?? 0.0,
      altitud: (json['altitud'] as num?)?.toDouble() ?? 0.0,
      desdeBluetooth: true, 
    );
  }
}