class UsuarioConductor {
  const UsuarioConductor({
    required this.idUsuario,
    required this.nombreCompleto,
    required this.email,
    required this.rol,
  });

  final String idUsuario;
  final String nombreCompleto;
  final String email;
  final String rol;

  factory UsuarioConductor.fromJson(Map<String, dynamic> json) {
    return UsuarioConductor(
      idUsuario: _read(json, const ['id_usuario', 'IDUsuario']),
      nombreCompleto:
          _read(json, const ['nombre_completo', 'Nombre', 'nombre']),
      email: _read(json, const ['email', 'Correo', 'correo']),
      rol: _read(json, const ['rol', 'Rol']),
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
}
