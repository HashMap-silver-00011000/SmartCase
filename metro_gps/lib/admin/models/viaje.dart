class ViajeInput {
  const ViajeInput({
    required this.idCaja,
    required this.idUsuarioConductor,
    required this.idSedeOrigen,
    required this.idSedeDestino,
    required this.idAmbulancia,
    this.estadoViaje,
  });

  final String idCaja;
  final String idUsuarioConductor;
  final String idSedeOrigen;
  final String idSedeDestino;
  final String idAmbulancia;
  final String? estadoViaje;

  static const estadosPermitidos = [
    'transito',
    'entregado',
    'muestra comprometida',
  ];

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id_caja': idCaja,
      'id_usuario_conductor': idUsuarioConductor,
      'id_sede_origen': idSedeOrigen,
      'id_sede_destino': idSedeDestino,
      'id_ambulancia': idAmbulancia,
    };
    if (estadoViaje != null && estadoViaje!.isNotEmpty) {
      json['estado_viaje'] = estadoViaje;
    }
    return json;
  }
}
