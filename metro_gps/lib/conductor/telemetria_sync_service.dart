import 'dart:async';

import '../core/telemetria_ws_client.dart';
import '../core/telemetria_ws_paths.dart';
import 'models/telemetria.dart';
import 'telemetria_local_store.dart';

/// Envía telemetría al backend por WebSocket.
///
/// Flujo:
/// 1. La vista llama [enviarRegistro] cada vez que el ESP32 entrega un paquete
///    nuevo → envío inmediato.
/// 2. Un timer de respaldo cada 5 s reenvía cualquier registro que haya
///    quedado pendiente por fallo de conexión.
class TelemetriaSyncService {
  TelemetriaSyncService({
    required this.idViaje,
    TelemetriaLocalStore? store,
    TelemetriaWsClient? wsClient,
  })  : _store = store ?? TelemetriaLocalStore.instance,
        _ws = wsClient ??
            TelemetriaWsClient(
              idViaje: idViaje,
              rol: TelemetriaWsRol.conductor,
            );

  final String idViaje;
  final TelemetriaLocalStore _store;
  final TelemetriaWsClient _ws;

  Timer? _timer;
  bool _enviando = false;
  bool _activo = false;

  String? lastError;
  DateTime? lastEnvio;

  TelemetriaWsClient get wsClient => _ws;

  Future<void> start() async {
    _activo = true;
    await _asegurarConexion();
    _timer?.cancel();
    // Timer de respaldo: reenvía pendientes que hayan fallado antes
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _enviarPendientes(),
    );
  }

  Future<void> stop() async {
    _activo = false;
    _timer?.cancel();
    _timer = null;
    await _ws.dispose();
  }

  /// Llama esto desde la vista cada vez que llega un paquete nuevo del ESP32.
  /// Guarda en el store y envía de inmediato al WebSocket.
  Future<bool> enviarRegistro(TelemetriaRegistro registro) async {
    if (!_activo) return false;
    return _enviar(registro);
  }

  // ── privados ────────────────────────────────────────────────────────────────

  Future<void> _asegurarConexion() async {
    if (_ws.isConnected) return;
    try {
      await _ws.connect();
      lastError = _ws.lastError;
    } catch (e) {
      lastError = e.toString();
    }
  }

  /// Timer de respaldo: envía todos los registros pendientes del viaje.
  Future<void> _enviarPendientes() async {
    if (!_activo || _enviando) return;
    final pendientes = _store.listarPendientes(idViaje);
    if (pendientes.isEmpty) return;

    if (!_ws.isConnected) await _asegurarConexion();
    if (!_ws.isConnected) {
      lastError = _ws.lastError ?? 'Sin conexión WebSocket';
      return;
    }

    for (final r in pendientes) {
      if (!_activo) break;
      await _enviar(r);
    }
  }

  Future<bool> _enviar(TelemetriaRegistro registro) async {
    if (_enviando) return false;
    _enviando = true;
    try {
      if (!_ws.isConnected) await _asegurarConexion();
      if (!_ws.isConnected) {
        lastError = _ws.lastError ?? 'Sin conexión WebSocket';
        return false;
      }

      final ok = _ws.send(registro);
      if (ok) {
        _store.marcarEnviado(idViaje, registro.idTelemetria);
        lastEnvio = DateTime.now();
        lastError = null;
      } else {
        lastError = _ws.lastError;
        // Intenta reconectar para el siguiente ciclo
        await _asegurarConexion();
      }
      return ok;
    } catch (e) {
      lastError = e.toString();
      return false;
    } finally {
      _enviando = false;
    }
  }
}