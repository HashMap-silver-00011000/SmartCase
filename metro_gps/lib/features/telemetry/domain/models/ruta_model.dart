class RutaModel {
  const RutaModel({
    required this.idRuta,
    required this.codigo,
    required this.nombre,
    required this.activa,
  });

  final String idRuta;
  final String codigo;
  final String nombre;
  final bool activa;

  factory RutaModel.fromJson(Map<String, dynamic> json) {
    return RutaModel(
      idRuta: json['id_ruta']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      activa: json['activa'] == true,
    );
  }
}
