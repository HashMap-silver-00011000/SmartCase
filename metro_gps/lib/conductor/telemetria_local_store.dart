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

  TelemetriaRegistro agregar({
    required String idViaje,
    required TelemetriaInput input,
  }) {
    final registro = TelemetriaRegistro(
      idTelemetria: _uuid.v4(),
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
}
