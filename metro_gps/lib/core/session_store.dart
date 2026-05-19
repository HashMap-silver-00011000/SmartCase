import '../auth/models/usuario_rol_opciones.dart';

/// Estado de sesión en memoria tras un login exitoso.
class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  String? rol;
  String? idUsuario;

  bool get isAdmin => rol == UsuarioRolBd.admin;

  bool get isConductor =>
      rol != null && rol!.trim().toLowerCase() == UsuarioRolBd.coductor;

  void setRol(String? value) => rol = value;

  void setIdUsuario(String? value) => idUsuario = value;

  void clear() {
    rol = null;
    idUsuario = null;
  }
}
