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

  Map<String, dynamic> toBackendJson() => {
        'id_viaje': idViaje,
        'temperatura_interna': temperaturaInterna,
        'latitud_actual': latitud,
        'longitud_actual': longitud,
        'fuerza_g_impacto': fuerzaG,
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
}
