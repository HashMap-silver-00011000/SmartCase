import '../auth/models/usuario_rol_opciones.dart';

/// Estado de sesión en memoria tras un login exitoso.
class SessionStore {
  SessionStore._();

  static final SessionStore instance = SessionStore._();

  String? rol;

  bool get isAdmin => rol == UsuarioRolBd.admin;

  void setRol(String? value) => rol = value;

  void clear() => rol = null;
}
