import 'dart:async';

import 'package:flutter/material.dart';

import '../ble/esp32_bluetooth_service.dart';
import '../ble/esp32_telemetria_packet.dart';
import '../models/telemetria.dart';
import '../models/viaje.dart';
import '../telemetria_local_store.dart';

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

  late List<TelemetriaRegistro> _registros;
  StreamSubscription<Esp32TelemetriaPacket>? _packetSub;
  bool _autoGuardar = true;
  bool _conectando = false;

  @override
  void initState() {
    super.initState();
    _registros = _store.listar(widget.viaje.idViaje);
    _bt.addListener(_onBtChanged);
    _packetSub = _bt.packets.listen(_onPacket);
  }

  @override
  void dispose() {
    _packetSub?.cancel();
    _bt.removeListener(_onBtChanged);
    super.dispose();
  }

  void _onBtChanged() {
    if (mounted) setState(() {});
  }

  void _onPacket(Esp32TelemetriaPacket packet) {
    if (!_autoGuardar) {
      if (mounted) setState(() {});
      return;
    }
    _store.agregar(
      idViaje: widget.viaje.idViaje,
      input: packet.toTelemetriaInput(),
    );
    _refrescar();
  }

  void _refrescar() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aún no hay lectura del ESP32')),
      );
      return;
    }
    _store.agregar(
      idViaje: widget.viaje.idViaje,
      input: p.toTelemetriaInput(),
    );
    _refrescar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lectura guardada en la tabla')),
    );
  }

  Future<void> _mostrarTelemetriaBluetooth() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Telemetría por Bluetooth',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Dispositivo: ${Esp32BluetoothService.deviceName}',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _buildEsp32Card(compact: false),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _mostrarFormularioManual();
              },
              child: const Text('Entrada manual (sin ESP32)'),
            ),
          ],
        ),
      ),
    );
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
              TextField(
                controller: tempCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Temperatura interna (°C)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: latCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Latitud',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lonCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Longitud',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Fuerza G impacto',
                  border: OutlineInputBorder(),
                ),
              ),
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
      tempCtrl.dispose();
      latCtrl.dispose();
      lonCtrl.dispose();
      gCtrl.dispose();
      alertaCtrl.dispose();
      return;
    }

    double? parse(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

    final temp = parse(tempCtrl.text);
    final lat = parse(latCtrl.text);
    final lon = parse(lonCtrl.text);
    final g = parse(gCtrl.text);
    final alerta = alertaCtrl.text.trim();

    tempCtrl.dispose();
    latCtrl.dispose();
    lonCtrl.dispose();
    gCtrl.dispose();
    alertaCtrl.dispose();

    if (temp == null || lat == null || lon == null || g == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Revisa que todos los valores numéricos sean válidos'),
        ),
      );
      return;
    }

    _store.agregar(
      idViaje: widget.viaje.idViaje,
      input: TelemetriaInput(
        temperaturaInterna: temp,
        latitud: lat,
        longitud: lon,
        fuerzaG: g,
        alertaGenerada: alerta.isEmpty ? null : alerta,
      ),
    );

    _refrescar();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro manual guardado (solo en la app)'),
      ),
    );
  }

  Widget _buildEsp32Card({required bool compact}) {
    final p = _bt.lastPacket;
    final connected = _bt.isConnected;
    final status = _bt.statusMessage ?? 'Sin conectar';

    return Card(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  connected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: connected ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    connected ? 'ESP32 conectado' : 'ESP32 desconectado',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (p != null && connected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'En vivo',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(status, style: Theme.of(context).textTheme.bodySmall),
            if (_bt.lastError != null) ...[
              const SizedBox(height: 4),
              Text(
                _bt.lastError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            if (!_bt.isSupported) ...[
              const SizedBox(height: 8),
              const Text(
                'Prueba en un teléfono Android: empareja "ESP32_Telemetria_Bryan" '
                'en Ajustes → Bluetooth antes de conectar.',
                style: TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed:
                      _conectando || !_bt.isSupported ? null : _toggleBluetooth,
                  icon: _conectando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(connected ? Icons.link_off : Icons.link),
                  label: Text(connected ? 'Desconectar' : 'Conectar ESP32'),
                ),
                if (connected)
                  OutlinedButton.icon(
                    onPressed: p == null ? null : _guardarLecturaActual,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Guardar lectura'),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Agregar cada lectura a la tabla'),
              subtitle: const Text('El ESP32 envía datos cada ~3 s'),
              value: _autoGuardar,
              onChanged: (v) => setState(() => _autoGuardar = v),
            ),
            if (p != null) ...[
              const Divider(),
              Text(
                'Última lectura (${_formatoHora(p.recibidoEn)})',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              _datoEnVivo('Temp. interna (t_int)', '${p.tInt.toStringAsFixed(1)} °C'),
              _datoEnVivo('Temp. ambiente', '${p.tAmb.toStringAsFixed(1)} °C'),
              _datoEnVivo('Humedad', '${p.hum.toStringAsFixed(0)} %'),
              _datoEnVivo('Luz (lux)', p.lux.toStringAsFixed(0)),
              _datoEnVivo('Aceleración (acc)', p.acc.toStringAsFixed(2)),
              _datoEnVivo(
                'GPS',
                '${p.lat.toStringAsFixed(5)}, ${p.lng.toStringAsFixed(5)}',
              ),
              _datoEnVivo('Altitud', '${p.alt.toStringAsFixed(1)} m'),
            ] else if (connected) ...[
              const SizedBox(height: 8),
              const Text('Esperando primera línea JSON del ESP32…'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _datoEnVivo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.viaje;

    return Scaffold(
      appBar: AppBar(
        title: Text('Viaje ${v.idCorto}'),
        actions: [
          IconButton(
            tooltip: 'Entrada manual',
            onPressed: _mostrarFormularioManual,
            icon: const Icon(Icons.edit_note),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarTelemetriaBluetooth,
        icon: const Icon(Icons.bluetooth),
        label: const Text('Subir telemetría'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado: ${v.estadoViaje ?? '—'}'),
                  const SizedBox(height: 4),
                  Text('Inicio: ${v.fechaInicio}'),
                  if (v.fechaLlegada != null)
                    Text('Llegada: ${v.fechaLlegada}'),
                  const SizedBox(height: 8),
                  Text(
                    'Origen sede: ${_idCorto(v.idSedeOrigen)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Destino sede: ${_idCorto(v.idSedeDestino)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          _buildEsp32Card(compact: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Telemetría (${_registros.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: _registros.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Sin registros. Conecta el ESP32 por Bluetooth o usa entrada manual.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Hora')),
                          DataColumn(label: Text('Origen')),
                          DataColumn(label: Text('Temp °C')),
                          DataColumn(label: Text('Lat')),
                          DataColumn(label: Text('Lon')),
                          DataColumn(label: Text('G')),
                          DataColumn(label: Text('Alerta')),
                          DataColumn(label: Text('Servidor')),
                        ],
                        rows: _registros.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Text(_formatoHora(r.registradoEn))),
                              DataCell(
                                Icon(
                                  r.desdeBluetooth
                                      ? Icons.bluetooth
                                      : Icons.keyboard,
                                  size: 20,
                                  color: r.desdeBluetooth
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                              ),
                              DataCell(
                                Text(r.temperaturaInterna.toStringAsFixed(1)),
                              ),
                              DataCell(Text(r.latitud.toStringAsFixed(5))),
                              DataCell(Text(r.longitud.toStringAsFixed(5))),
                              DataCell(Text(r.fuerzaG.toStringAsFixed(2))),
                              DataCell(Text(r.alertaGenerada ?? '—')),
                              DataCell(
                                Icon(
                                  r.enviadoAlServidor
                                      ? Icons.cloud_done
                                      : Icons.cloud_off,
                                  size: 20,
                                  color: r.enviadoAlServidor
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  static String _idCorto(String id) =>
      id.length > 8 ? '${id.substring(0, 8)}…' : id;

  static String _formatoHora(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$d/$m ${dt.year} $h:$min:$s';
  }
}
