  import '../../conductor/models/viaje.dart' as conductor;
  


class Viaje {

conductor.Viaje toConductorViaje() {
  return conductor.Viaje(
    idViaje: idViaje,
    idCaja: idCaja,
    idUsuarioConductor: idUsuarioConductor,
    idUsuarioReceptor: idUsuarioReceptor,
    idSedeOrigen: idSedeOrigen,
    idSedeDestino: idSedeDestino,
    idAmbulancia: idAmbulancia,
    fechaInicio: fechaInicio,
    fechaLlegada: fechaLlegada,
    estadoViaje: estadoViaje,
  );
}
  const Viaje({
    required this.idViaje,
    required this.idCaja,
    required this.idUsuarioConductor,
    this.idUsuarioReceptor,
    required this.idSedeOrigen,
    required this.idSedeDestino,
    required this.idAmbulancia,
    required this.fechaInicio,
    this.fechaLlegada,
    this.estadoViaje,
    required this.pinEntrega,
  });

  final String idViaje;
  final String idCaja;
  final String idUsuarioConductor;
  final String? idUsuarioReceptor;
  final String idSedeOrigen;
  final String idSedeDestino;
  final String idAmbulancia;
  final String fechaInicio;
  final String? fechaLlegada;
  final String? estadoViaje;
  final String pinEntrega;

  factory Viaje.fromJson(Map<String, dynamic> json) {
    return Viaje(
      idViaje: _read(json, const ['id_viaje']),
      idCaja: _read(json, const ['id_caja']),
      idUsuarioConductor: _read(json, const ['id_usuario_conductor']),
      idUsuarioReceptor: _optional(json, const ['id_usuario_receptor']),
      idSedeOrigen: _read(json, const ['id_sede_origen']),
      idSedeDestino: _read(json, const ['id_sede_destino']),
      idAmbulancia: _read(json, const ['id_ambulancia']),
      fechaInicio: _read(json, const ['fecha_inicio']),
      fechaLlegada: _optional(json, const ['fecha_llegada']),
      estadoViaje: _optional(json, const ['estado_viaje']),
      pinEntrega: _read(json, const ['pin_entrega']),
    );
  }

  static String _read(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final v = json[key];
      if (v != null) {
        final s = v.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return '';
  }

  static String? _optional(Map<String, dynamic> json, List<String> keys) {
    final s = _read(json, keys);
    return s.isEmpty ? null : s;
  }

  String get idCorto =>
      idViaje.length > 8 ? idViaje.substring(0, 8) : idViaje;
}

