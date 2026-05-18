class Sede {
  const Sede({
    required this.idSede,
    required this.idClinica,
    required this.nombre,
  });

  final String idSede;
  final String idClinica;
  final String nombre;

  factory Sede.fromJson(Map<String, dynamic> json) {
    return Sede(
      idSede: _readString(json, const ['id_sede', 'IDSede', 'IdSede']),
      idClinica: _readString(json, const ['id_clinica', 'IDClinica', 'IdClinica']),
      nombre: _readString(json, const ['nombre', 'Nombre']),
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    final lower = <String, dynamic>{
      for (final entry in json.entries)
        entry.key.toLowerCase(): entry.value,
    };
    for (final key in keys) {
      final value = lower[key.toLowerCase()];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
        'id_sede': idSede,
        'id_clinica': idClinica,
        'nombre': nombre,
      };

  /// Body para operaciones que enlazan `models.Sede` en el backend.
  Map<String, dynamic> toBackendJson() => {
        'id_sede': idSede,
        'IDSede': idSede,
        'id_clinica': idClinica,
        'IDClinica': idClinica,
        'nombre': nombre,
        'Nombre': nombre,
      };
}

class SedeInput {
  const SedeInput({
    required this.idClinica,
    required this.nombre,
  });

  final String idClinica;
  final String nombre;

  Map<String, dynamic> toJson() => {
        'id_clinica': idClinica,
        'nombre': nombre,
      };
}
