/// Rol para elegir la ruta WebSocket de telemetría (misma sesión JWT).
enum TelemetriaWsRol {
  admin,
  conductor,
  receptor,
}

abstract final class TelemetriaWsPaths {
  static String pathFor(TelemetriaWsRol rol) {
    switch (rol) {
      case TelemetriaWsRol.admin:
        return '/api/app/panel-admin/viaje/tareas-viaje-telemetria';
      case TelemetriaWsRol.conductor:
        return '/api/app/conductor/viaje/tareas-viaje-telemetria';
      case TelemetriaWsRol.receptor:
        return '/api/app/medico/viaje/tareas-viaje-telemetria';
    }
  }

  static String historialRest(TelemetriaWsRol rol) {
    switch (rol) {
      case TelemetriaWsRol.admin:
        return '/api/app/panel-admin/viaje/telemetria';
      case TelemetriaWsRol.conductor:
        return '/api/app/panel-admin/viaje/telemetria';
      case TelemetriaWsRol.receptor:
        return '/api/app/medico/viaje/telemetria';
    }
  }
}
