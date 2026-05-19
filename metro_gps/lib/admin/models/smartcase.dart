class SmartCase {
  const SmartCase({
    required this.idCaja,
    required this.estadoSolenoide,
    required this.organo,
  });

  final String idCaja;
  final String estadoSolenoide;
  final String organo;

  static const estadosSolenoide = ['bloqueado', 'desbloqueado'];

  factory SmartCase.fromJson(Map<String, dynamic> json) {
    return SmartCase(
      idCaja: _read(json, const ['id_caja', 'IDCaja']),
      estadoSolenoide:
          _read(json, const ['estado_solenoide', 'EstadoSolenoide']),
      organo: _read(json, const ['organo', 'Organo']),
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

  Map<String, dynamic> toJson() => {
        'id_caja': idCaja,
        'estado_solenoide': estadoSolenoide,
        'organo': organo,
      };
}

class SmartCaseInput {
  const SmartCaseInput({
    required this.estadoSolenoide,
    required this.organo,
  });

  final String estadoSolenoide;
  final String organo;

  Map<String, dynamic> toJson() => {
        'estado_solenoide': estadoSolenoide,
        'organo': organo,
      };
}
