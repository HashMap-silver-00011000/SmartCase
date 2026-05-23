// lib/conductor/ui/conductor_viaje_detalle_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';

import '../ble/esp32_bluetooth_service.dart';
import '../ble/esp32_telemetria_packet.dart';
import '../conductor_viaje_api.dart';
import '../conductor_pin_api.dart';
import '../models/telemetria.dart';
import '../models/viaje.dart';
import '../telemetria_local_store.dart';
import '../telemetria_sync_service.dart';

class ConductorViajeDetalleScreen extends StatefulWidget {
  const ConductorViajeDetalleScreen({super.key, required this.viaje});

  final Viaje viaje;

  @override
  State<ConductorViajeDetalleScreen> createState() =>
      _ConductorViajeDetalleScreenState();
}

class _ConductorViajeDetalleScreenState
    extends State<ConductorViajeDetalleScreen> {
  final _store = TelemetriaLocalStore.instance;
  final _bt = Esp32BluetoothService.instance;
  final _api = ConductorViajeApi();
  late final TelemetriaSyncService _sync;

  late List<TelemetriaRegistro> _registros;
  StreamSubscription<Esp32TelemetriaPacket>? _packetSub;
  bool _autoGuardar = true;
  bool _conectando = false;

  static const _tempMax = 40.0;
  static const _humedadMax = 100.0;
  static const _luxMax = 1200.0;
  static const _gMax = 12.0;
  static const _altMax = 3000.0;

  @override
  void initState() {
    super.initState();
    _sync = TelemetriaSyncService(idViaje: widget.viaje.idViaje);
    _registros = _store.listar(widget.viaje.idViaje);
    _bt.addListener(_onBtChanged);
    _packetSub = _bt.packets.listen(_onPacket);
    _iniciarSync();
  }

  Future<void> _iniciarSync() async {
    try {
      await _sync.start();
    } catch (_) {}
  }

  @override
  void dispose() {
    _packetSub?.cancel();
    _bt.removeListener(_onBtChanged);
    _sync.stop();
    super.dispose();
  }

  void _onBtChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onPacket(Esp32TelemetriaPacket packet) async {
    if (!mounted) return;
    if (!_autoGuardar) {
      setState(() {});
      return;
    }
    final registro = _store.agregar(
      idViaje: widget.viaje.idViaje,
      input: packet.toTelemetriaInput(),
    );
    _sync.enviarRegistro(registro);
    _refrescar();
  }

  void _refrescar() {
    if (!mounted) return;
    setState(() {
      _registros = _store.listar(widget.viaje.idViaje);
    });
  }

  Future<void> _toggleBluetooth() async {
    if (_bt.isConnected) {
      await _bt.disconnect();
      return;
    }
    setState(() => _conectando = true);
    try {
      await _bt.connect();
    } finally {
      if (mounted) setState(() => _conectando = false);
    }
  }

  void _guardarLecturaActual() {
    final p = _bt.lastPacket;
    if (p == null) {
      _snack('Aún no hay lectura del ESP32');
      return;
    }
    final registro = _store.agregar(
      idViaje: widget.viaje.idViaje,
      input: p.toTelemetriaInput(),
    );
    _sync.enviarRegistro(registro);
    _refrescar();
    _snack('Lectura guardada');
  }

  // ── NUEVO: se llama cuando el PIN es válido ────────────────────────────────
   Future<void> _marcarEntregado() async {
    // 1. Intentar enviar el comando al ESP32 si está conectado
    if (_bt.isConnected) {
      final enviado = await _bt.abrirCaja();
      if (!enviado && mounted) {
        _snack('Advertencia: no se pudo enviar la orden al ESP32');
      }
    }
 
    // 2. Actualizar el estado en el backend independientemente del BT
    final res = await _api.actualizarEstadoViaje(
      idViaje: widget.viaje.idViaje,
      estado: 'entregado',
    );
    if (!mounted) return;
    if (res.isSuccess) {
      _snack('Viaje marcado como entregado');
      Navigator.of(context).pop();
    } else {
      _snack(res.errorMessage ?? 'Error al actualizar estado');
    }
  }

  Future<void> _mostrarFormularioManual() async {
    final tempCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();
    final gCtrl = TextEditingController();
    final alertaCtrl = TextEditingController();

    final guardado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registro manual'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(tempCtrl, 'Temperatura interna (°C)'),
              const SizedBox(height: 12),
              _campo(latCtrl, 'Latitud'),
              const SizedBox(height: 12),
              _campo(lonCtrl, 'Longitud'),
              const SizedBox(height: 12),
              _campo(gCtrl, 'Fuerza G impacto'),
              const SizedBox(height: 12),
              TextField(
                controller: alertaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alerta (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (guardado != true || !mounted) {
      for (final c in [tempCtrl, latCtrl, lonCtrl, gCtrl, alertaCtrl]) {
        c.dispose();
      }
      return;
    }

    double? parse(String s) =>
        double.tryParse(s.trim().replaceAll(',', '.'));
    final temp = parse(tempCtrl.text);
    final lat = parse(latCtrl.text);
    final lon = parse(lonCtrl.text);
    final g = parse(gCtrl.text);
    final alerta = alertaCtrl.text.trim();

    for (final c in [tempCtrl, latCtrl, lonCtrl, gCtrl, alertaCtrl]) {
      c.dispose();
    }

    if (temp == null || lat == null || lon == null || g == null) {
      _snack('Revisa que los valores numéricos sean válidos');
      return;
    }

    final registro = _store.agregar(
      idViaje: widget.viaje.idViaje,
      input: TelemetriaInput(
        temperaturaInterna: temp,
        latitud: lat,
        longitud: lon,
        fuerzaG: g,
        alertaGenerada: alerta.isEmpty ? null : alerta,
      ),
    );
    _sync.enviarRegistro(registro);
    _refrescar();
    if (!mounted) return;
    _snack('Registro guardado y enviado');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  TextField _campo(TextEditingController ctrl, String label) => TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );

  Color _sensorColor(double value, double max,
      {double warnPct = 0.6, double dangerPct = 0.85}) {
    final pct = (value / max).clamp(0.0, 1.0);
    if (pct >= dangerPct) return const Color(0xFFE24B4A);
    if (pct >= warnPct) return const Color(0xFFEF9F27);
    return const Color(0xFF1D9E75);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.viaje;
    final p = _bt.lastPacket;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Viaje ${v.idCorto}'),
        // ── Botón de cambiar estado ELIMINADO ─────────────────────────────
        actions: [
          IconButton(
            tooltip: 'Entrada manual',
            onPressed: _mostrarFormularioManual,
            icon: const Icon(Icons.edit_note_outlined),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        onBluetooth: () => _mostrarPanelBluetooth(context),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _ViajeInfoCard(viaje: v),

          const _SectionLabel(label: 'Verificación de entrega'),
          // ── onPinValido conecta el PIN con actualizarEstadoViaje ──────────
          _PinVerificacionCard(
            idViaje: v.idViaje,
            onPinValido: _marcarEntregado,
          ),

          _SectionLabel(
            label: 'Sensores en vivo',
            trailing: p != null ? _LivePill() : null,
          ),
          if (p != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5,
                children: [
                  _SensorCard(
                    label: 'Temp. interna',
                    value: p.tInt.toStringAsFixed(1),
                    unit: '°C',
                    icon: Icons.thermostat_outlined,
                    fill: (p.tInt / _tempMax).clamp(0.0, 1.0),
                    color: _sensorColor(p.tInt, _tempMax),
                  ),
                  _SensorCard(
                    label: 'Temp. ambiente',
                    value: p.tAmb.toStringAsFixed(1),
                    unit: '°C',
                    icon: Icons.device_thermostat_outlined,
                    fill: (p.tAmb / _tempMax).clamp(0.0, 1.0),
                    color: _sensorColor(p.tAmb, _tempMax),
                  ),
                  _SensorCard(
                    label: 'Humedad',
                    value: p.hum.toStringAsFixed(0),
                    unit: '%',
                    icon: Icons.water_drop_outlined,
                    fill: (p.hum / _humedadMax).clamp(0.0, 1.0),
                    color: _sensorColor(p.hum, _humedadMax,
                        warnPct: 0.7, dangerPct: 0.9),
                  ),
                  _SensorCard(
                    label: 'Luz',
                    value: p.lux.toStringAsFixed(0),
                    unit: 'lux',
                    icon: Icons.light_mode_outlined,
                    fill: (p.lux / _luxMax).clamp(0.0, 1.0),
                    color: _sensorColor(p.lux, _luxMax,
                        warnPct: 0.7, dangerPct: 0.9),
                  ),
                  _SensorCard(
                    label: 'Impacto G',
                    value: p.acc.toStringAsFixed(2),
                    unit: 'G',
                    icon: Icons.vibration_outlined,
                    fill: (p.acc / _gMax).clamp(0.0, 1.0),
                    color: _sensorColor(p.acc, _gMax,
                        warnPct: 0.4, dangerPct: 0.7),
                  ),
                  _SensorCard(
                    label: 'Altitud',
                    value: p.alt.toStringAsFixed(0),
                    unit: 'm',
                    icon: Icons.landscape_outlined,
                    fill: (p.alt / _altMax).clamp(0.0, 1.0),
                    color: _sensorColor(p.alt, _altMax,
                        warnPct: 0.7, dangerPct: 0.9),
                  ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _bt.isConnected
                      ? 'Esperando primera lectura del ESP32…'
                      : 'Conecta el ESP32 para ver sensores en vivo',
                  style: textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          if (p != null) ...[
            const _SectionLabel(label: 'Posición GPS'),
            _GpsCard(packet: p),
          ],

          const _SectionLabel(label: 'Bluetooth · ESP32'),
          _BluetoothCard(
            bt: _bt,
            conectando: _conectando,
            autoGuardar: _autoGuardar,
            onToggle: _toggleBluetooth,
            onGuardar: _guardarLecturaActual,
            onAutoGuardar: (v) => setState(() => _autoGuardar = v),
          ),

          _SectionLabel(
              label: 'Telemetría registrada (${_registros.length})'),
          _TelemetriaTable(registros: _registros),
        ],
      ),
    );
  }

  Future<void> _mostrarPanelBluetooth(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Text(
              'Telemetría Bluetooth',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            Text(
              Esp32BluetoothService.deviceName,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _BluetoothCard(
              bt: _bt,
              conectando: _conectando,
              autoGuardar: _autoGuardar,
              onToggle: _toggleBluetooth,
              onGuardar: _guardarLecturaActual,
              onAutoGuardar: (v) => setState(() => _autoGuardar = v),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _mostrarFormularioManual();
              },
              icon: const Icon(Icons.edit_note_outlined, size: 18),
              label: const Text('Entrada manual (sin ESP32)'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PIN Verificación Card ──────────────────────────────────────────────────────

enum _PinEstado { inactivo, cargando, valido, invalido }

class _PinVerificacionCard extends StatefulWidget {
  const _PinVerificacionCard({
    required this.idViaje,
    required this.onPinValido, // ← NUEVO
  });

  final String idViaje;
  final VoidCallback onPinValido; // ← NUEVO

  @override
  State<_PinVerificacionCard> createState() => _PinVerificacionCardState();
}

class _PinVerificacionCardState extends State<_PinVerificacionCard> {
  final _pinCtrl = TextEditingController();
  final _pinApi = ConductorPinApi();
  _PinEstado _estado = _PinEstado.inactivo;
  String? _mensajeError;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _comprobar() async {
    final pin = _pinCtrl.text.trim();
    if (pin.isEmpty) return;

    setState(() {
      _estado = _PinEstado.cargando;
      _mensajeError = null;
    });

    final res = await _pinApi.comprobarPin(
      idViaje: widget.idViaje,
      pinEntrega: pin,
    );

    if (!mounted) return;

    if (res.isSuccess) {
      final esValido = res.valido == true;
      setState(() {
        _estado = esValido ? _PinEstado.valido : _PinEstado.invalido;
        _mensajeError = esValido ? null : 'PIN incorrecto. Intenta de nuevo.';
      });
      // ── CLAVE: dispara el cambio de estado en la BD ───────────────────────
      if (esValido) widget.onPinValido();
    } else {
      setState(() {
        _estado = _PinEstado.invalido;
        _mensajeError = res.errorMessage ?? 'Error al verificar el PIN.';
      });
    }
  }

  void _reiniciar() {
    setState(() {
      _estado = _PinEstado.inactivo;
      _mensajeError = null;
      _pinCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _headerBg,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_headerIcon, size: 18, color: _iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headerTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _iconColor,
                        ),
                      ),
                      Text(
                        _headerSubtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A94A6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_estado == _PinEstado.valido ||
                    _estado == _PinEstado.invalido)
                  GestureDetector(
                    onTap: _reiniciar,
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: Color(0xFF8A94A6),
                    ),
                  ),
              ],
            ),
          ),
          if (_estado == _PinEstado.valido)
            _buildResultado()
          else
            _buildFormulario(),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            enabled: _estado != _PinEstado.cargando,
            maxLength: 10,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: '••••••',
              hintStyle: TextStyle(
                letterSpacing: 4,
                color: Colors.grey.shade400,
              ),
              counterText: '',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: Color(0xFF8A94A6),
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8ECF2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8ECF2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1A73E8),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE53935)),
              ),
              errorText:
                  _estado == _PinEstado.invalido ? _mensajeError : null,
            ),
            onSubmitted: (_) => _comprobar(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: _estado == _PinEstado.cargando ? null : _comprobar,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                disabledBackgroundColor:
                    const Color(0xFF1A73E8).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _estado == _PinEstado.cargando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.verified_outlined, size: 18),
              label: Text(
                _estado == _PinEstado.cargando
                    ? 'Verificando…'
                    : 'Verificar PIN',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFE6F4EA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              size: 36,
              color: Color(0xFF1B873F),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Entrega verificada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B873F),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'El PIN ingresado es correcto.\nPuedes proceder con la entrega.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF8A94A6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color get _borderColor {
    switch (_estado) {
      case _PinEstado.valido:   return const Color(0xFF81C784);
      case _PinEstado.invalido: return const Color(0xFFEF9A9A);
      default:                  return const Color(0xFFE8ECF2);
    }
  }

  Color get _headerBg {
    switch (_estado) {
      case _PinEstado.valido:   return const Color(0xFFE6F4EA);
      case _PinEstado.invalido: return const Color(0xFFFFEBEE);
      default:                  return const Color(0xFFF8F9FC);
    }
  }

  Color get _iconBg {
    switch (_estado) {
      case _PinEstado.valido:   return const Color(0xFFC8E6C9);
      case _PinEstado.invalido: return const Color(0xFFFFCDD2);
      default:                  return const Color(0xFFE8F0FE);
    }
  }

  Color get _iconColor {
    switch (_estado) {
      case _PinEstado.valido:   return const Color(0xFF1B873F);
      case _PinEstado.invalido: return const Color(0xFFB71C1C);
      default:                  return const Color(0xFF1A73E8);
    }
  }

  IconData get _headerIcon {
    switch (_estado) {
      case _PinEstado.valido:   return Icons.verified_rounded;
      case _PinEstado.invalido: return Icons.lock_person_outlined;
      default:                  return Icons.pin_outlined;
    }
  }

  String get _headerTitle {
    switch (_estado) {
      case _PinEstado.valido:   return 'PIN verificado';
      case _PinEstado.invalido: return 'PIN incorrecto';
      default:                  return 'Ingresar PIN de entrega';
    }
  }

  String get _headerSubtitle {
    switch (_estado) {
      case _PinEstado.valido:   return 'El receptor confirmó la entrega';
      case _PinEstado.invalido: return 'El PIN no coincide con el registrado';
      default:                  return 'Solicita el PIN al receptor para confirmar';
    }
  }
}

// ── Widgets auxiliares (sin cambios) ──────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.trailing});
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3DE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: Color(0xFF1D9E75)),
          SizedBox(width: 4),
          Text(
            'En vivo',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3B6D11),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViajeInfoCard extends StatelessWidget {
  const _ViajeInfoCard({required this.viaje});
  final Viaje viaje;

  Color _estadoColor(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'transito':           return const Color(0xFF185FA5);
      case 'entregado':          return const Color(0xFF1D9E75);
      case 'muestra comprometida': return const Color(0xFFE24B4A);
      default:                   return const Color(0xFF888780);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = viaje;
    final estadoColor = _estadoColor(v.estadoViaje);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '# ${v.idViaje.length > 8 ? v.idViaje.substring(0, 8) : v.idViaje}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    v.estadoViaje ?? 'Sin estado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: estadoColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.trip_origin,
                    size: 14, color: Color(0xFF1D9E75)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    v.idSedeOrigen,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.arrow_forward,
                    size: 14, color: Color(0xFF888780)),
                const SizedBox(width: 6),
                const Icon(Icons.place_outlined,
                    size: 14, color: Color(0xFFE24B4A)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    v.idSedeDestino,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule_outlined,
                    size: 14, color: Color(0xFF888780)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Inicio: ${v.fechaInicio}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (v.fechaLlegada != null) ...[
                  const Icon(Icons.flag_outlined,
                      size: 14, color: Color(0xFF1D9E75)),
                  const SizedBox(width: 4),
                  Text(
                    'Llegada: ${v.fechaLlegada}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.fill,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF888780)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: const TextStyle(fontSize: 12, color: Color(0xFF888780)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 3,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsCard extends StatelessWidget {
  const _GpsCard({required this.packet});
  final Esp32TelemetriaPacket packet;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 0.5,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFE24B4A),
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _GpsDato(
                  label: 'Latitud',
                  value: packet.lat.toStringAsFixed(5)),
              _GpsDato(
                  label: 'Longitud',
                  value: packet.lng.toStringAsFixed(5)),
              _GpsDato(
                  label: 'Altitud',
                  value: '${packet.alt.toStringAsFixed(0)} m'),
            ],
          ),
        ],
      ),
    );
  }
}

class _GpsDato extends StatelessWidget {
  const _GpsDato({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF888780))),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _BluetoothCard extends StatelessWidget {
  const _BluetoothCard({
    required this.bt,
    required this.conectando,
    required this.autoGuardar,
    required this.onToggle,
    required this.onGuardar,
    required this.onAutoGuardar,
  });

  final Esp32BluetoothService bt;
  final bool conectando;
  final bool autoGuardar;
  final VoidCallback onToggle;
  final VoidCallback onGuardar;
  final ValueChanged<bool> onAutoGuardar;

  @override
  Widget build(BuildContext context) {
    final connected = bt.isConnected;
    final p = bt.lastPacket;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected
                        ? const Color(0xFF1D9E75)
                        : const Color(0xFF888780),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connected ? 'ESP32 conectado' : 'ESP32 desconectado',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        bt.statusMessage ?? 'Sin conectar',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF888780)),
                      ),
                    ],
                  ),
                ),
                if (connected && p != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3DE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'En vivo',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B6D11),
                      ),
                    ),
                  ),
              ],
            ),
            if (bt.lastError != null) ...[
              const SizedBox(height: 4),
              Text(
                bt.lastError!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (!bt.isSupported)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Empareja "ESP32_Telemetria_Bryan" en Ajustes → Bluetooth antes de conectar.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888780)),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed:
                      conectando || !bt.isSupported ? null : onToggle,
                  icon: conectando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          connected
                              ? Icons.bluetooth_disabled_outlined
                              : Icons.bluetooth_outlined,
                          size: 18,
                        ),
                  label: Text(connected ? 'Desconectar' : 'Conectar ESP32'),
                ),
                if (connected)
                  OutlinedButton.icon(
                    onPressed: p == null ? null : onGuardar,
                    icon: const Icon(Icons.save_alt_outlined, size: 18),
                    label: const Text('Guardar lectura'),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Agregar cada lectura a la tabla',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'El ESP32 envía datos cada ~3 s',
                style: TextStyle(fontSize: 12),
              ),
              value: autoGuardar,
              onChanged: onAutoGuardar,
            ),
          ],
        ),
      ),
    );
  }
}

class _TelemetriaTable extends StatelessWidget {
  const _TelemetriaTable({required this.registros});
  final List<TelemetriaRegistro> registros;

  @override
  Widget build(BuildContext context) {
    if (registros.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Sin registros. Conecta el ESP32 o usa entrada manual.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF888780)),
          ),
        ),
      );
    }

    final items = registros.reversed.take(50).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 38,
          dataRowMaxHeight: 44,
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('Hora', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('Orig.', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('Temp °C', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('G', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('Alerta', style: TextStyle(fontSize: 12))),
            DataColumn(label: Text('WS', style: TextStyle(fontSize: 12))),
          ],
          rows: items.map((r) {
            final gColor = r.fuerzaG >= 8
                ? const Color(0xFFE24B4A)
                : r.fuerzaG >= 4
                    ? const Color(0xFFEF9F27)
                    : null;

            return DataRow(cells: [
              DataCell(Text(_hora(r.registradoEn),
                  style: const TextStyle(fontSize: 12))),
              DataCell(Icon(
                r.desdeBluetooth
                    ? Icons.bluetooth
                    : Icons.keyboard_outlined,
                size: 16,
                color: r.desdeBluetooth
                    ? const Color(0xFF185FA5)
                    : const Color(0xFF888780),
              )),
              DataCell(Text(r.temperaturaInterna.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12))),
              DataCell(Text(
                r.fuerzaG.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      gColor != null ? FontWeight.w600 : FontWeight.normal,
                  color: gColor,
                ),
              )),
              DataCell(_AlertaChip(alerta: r.alertaGenerada)),
              DataCell(Icon(
                r.enviadoAlServidor
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                size: 16,
                color: r.enviadoAlServidor
                    ? const Color(0xFF1D9E75)
                    : const Color(0xFFEF9F27),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  static String _hora(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _AlertaChip extends StatelessWidget {
  const _AlertaChip({this.alerta});
  final String? alerta;

  @override
  Widget build(BuildContext context) {
    if (alerta == null || alerta!.isEmpty) {
      return const Text('—',
          style: TextStyle(fontSize: 12, color: Color(0xFF888780)));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFAEEDA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        alerta!.length > 10 ? '${alerta!.substring(0, 10)}…' : alerta!,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFF854F0B),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onBluetooth});
  final VoidCallback onBluetooth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBluetooth,
                icon: const Icon(Icons.bluetooth_outlined, size: 18),
                label: const Text('Telemetría BT'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}