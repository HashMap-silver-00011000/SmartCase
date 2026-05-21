import 'package:uuid/uuid.dart';

import 'models/telemetria.dart';

/// Almacén en memoria hasta que exista API REST de telemetría en el backend.
class TelemetriaLocalStore {
  TelemetriaLocalStore._();

  static final TelemetriaLocalStore instance = TelemetriaLocalStore._();

  final _porViaje = <String, List<TelemetriaRegistro>>{};
  final _uuid = const Uuid();

  List<TelemetriaRegistro> listar(String idViaje) {
    return List.unmodifiable(_porViaje[idViaje] ?? const []);
  }

  List<TelemetriaRegistro> listarPendientes(String idViaje) {
    return listar(idViaje).where((r) => !r.enviadoAlServidor).toList();
  }

  void marcarEnviado(String idViaje, String idTelemetria) {
    final lista = _porViaje[idViaje];
    if (lista == null) return;
    for (var i = 0; i < lista.length; i++) {
      if (lista[i].idTelemetria == idTelemetria) {
        lista[i] = lista[i].copyWith(enviadoAlServidor: true);
        return;
      }
    }
  }

  void fusionarHistorial(String idViaje, List<TelemetriaRegistro> remotos) {
    if (remotos.isEmpty) return;
    final local = _porViaje.putIfAbsent(idViaje, () => []);
    final ids = local.map((e) => e.idTelemetria).toSet();
    for (final r in remotos) {
      if (!ids.contains(r.idTelemetria)) {
        local.add(r);
        ids.add(r.idTelemetria);
      }
    }
    local.sort((a, b) => a.registradoEn.compareTo(b.registradoEn));
  }

  TelemetriaRegistro agregar({
    required String idViaje,
    required TelemetriaInput input,
  }) {
    final registro = TelemetriaRegistro(
      idTelemetria: input.idTelemetria ?? _uuid.v4(),
      idViaje: idViaje,
      temperaturaInterna: input.temperaturaInterna,
      latitud: input.latitud,
      longitud: input.longitud,
      fuerzaG: input.fuerzaG,
      registradoEn: DateTime.now(),
      alertaGenerada: input.alertaGenerada,
      enviadoAlServidor: false,
      desdeBluetooth: input.desdeBluetooth,
      tempAmbiente: input.tempAmbiente,
      humedad: input.humedad,
      lux: input.lux,
      altitud: input.altitud,
    );
    _porViaje.putIfAbsent(idViaje, () => []).add(registro);
    return registro;
  }

  /// Devuelve el registro más reciente NO enviado aún, o null si no hay.
  /// El sync service lo usa para enviar la lectura "en vivo" al WebSocket.
  TelemetriaRegistro? lecturaVivo(String idViaje) {
    final lista = _porViaje[idViaje];
    if (lista == null || lista.isEmpty) return null;
    // Busca desde el final (más reciente) el primer pendiente
    for (var i = lista.length - 1; i >= 0; i--) {
      if (!lista[i].enviadoAlServidor) return lista[i];
    }
    return null;
  }
}