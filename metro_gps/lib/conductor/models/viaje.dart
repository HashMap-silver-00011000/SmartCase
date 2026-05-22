class Viaje {
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

  factory Viaje.fromJson(Map<String, dynamic> json) {
    return Viaje(
      idViaje: _read(json, const ['id_viaje', 'IDViaje']),
      idCaja: _read(json, const ['id_caja', 'IDCaja']),
      idUsuarioConductor:
          _read(json, const ['id_usuario_conductor', 'IDUsuarioConductor']),
      idUsuarioReceptor: _optional(
        json,
        const ['id_usuario_receptor', 'IDUsuarioReceptor'],
      ),
      idSedeOrigen: _read(json, const ['id_sede_origen', 'IDSedeOrigen']),
      idSedeDestino: _read(json, const ['id_sede_destino', 'IDSedeDestino']),
      idAmbulancia: _read(json, const ['id_ambulancia', 'IDAmbulancia']),
      fechaInicio: _read(json, const ['fecha_inicio', 'FechaInicio']),
      fechaLlegada: _optional(json, const ['fecha_llegada', 'FechaLlegada']),
      estadoViaje: _optional(json, const ['estado_viaje', 'EstadoViaje']),
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
