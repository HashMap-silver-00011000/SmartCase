class Ambulancia {
  const Ambulancia({
    required this.idAmbulancia,
    required this.placa,
    required this.tipo,
  });

  final String idAmbulancia;
  final String placa;
  final String tipo;

  static const tiposPermitidos = ['moto', 'ambulancia'];

  factory Ambulancia.fromJson(Map<String, dynamic> json) {
    return Ambulancia(
      idAmbulancia: _read(json, const ['id_ambulancia', 'IDAmbulancia']),
      placa: _read(json, const ['placa', 'Placa']),
      tipo: _read(json, const ['tipo', 'Tipo']),
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
        'id_ambulancia': idAmbulancia,
        'placa': placa,
        'tipo': tipo,
      };
}

class AmbulanciaInput {
  const AmbulanciaInput({
    required this.placa,
    required this.tipo,
  });

  final String placa;
  final String tipo;

  Map<String, dynamic> toJson() => {
        'placa': placa,
        'tipo': tipo,
      };
}
