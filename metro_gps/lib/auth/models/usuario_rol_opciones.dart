/// Valores de `rol` permitidos por `CHECK (rol IN (...))` en tabla `usuario`.
///
/// Nota: en el esquema aparece `coductor` (sin la **n** de *conductor*). La app
/// envía ese literal para no violar la restricción. Si corriges la BD a
/// `conductor`, cambia [coductor] y el CHECK en SQL.
abstract final class UsuarioRolBd {
  static const String coductor = 'coductor';
  static const String receptor = 'receptor';
  static const String admin = 'admin';

  static const List<String> todos = [coductor, receptor, admin];

  static String etiqueta(String valorBd) {
    switch (valorBd) {
      case coductor:
        return 'Conductor';
      case receptor:
        return 'Receptor';
      case admin:
        return 'Administrador';
      default:
        return valorBd;
    }
  }
}
