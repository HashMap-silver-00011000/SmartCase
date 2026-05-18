class Clinica {
  const Clinica({
    required this.idClinica,
    required this.nombre,
  });

  final String idClinica;
  final String nombre;

  factory Clinica.fromJson(Map<String, dynamic> json) {
    return Clinica(
      idClinica: json['id_clinica'] as String,
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_clinica': idClinica,
        'nombre': nombre,
      };
}

class ClinicaInput {
  const ClinicaInput({required this.nombre});

  final String nombre;

  Map<String, dynamic> toJson() => {'nombre': nombre};
}
