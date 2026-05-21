import 'dart:async';

import 'package:flutter/material.dart';

import '../../conductor/models/telemetria.dart';
import '../../conductor/telemetria_local_store.dart';
import '../../core/telemetria_api.dart';
import '../../core/telemetria_ws_client.dart';
import '../../core/telemetria_ws_paths.dart';
import '../../conductor/models/viaje.dart';

/// Vista de telemetría en vivo (WebSocket) + historial para admin y receptor.
class ViajeTelemetriaScreen extends StatefulWidget {
  const ViajeTelemetriaScreen({
    super.key,
    required this.viaje,
    required this.rolWs,
    this.titulo,
  });

  final Viaje viaje;
  final TelemetriaWsRol rolWs;
  final String? titulo;

  @override
  State<ViajeTelemetriaScreen> createState() => _ViajeTelemetriaScreenState();
}

class _ViajeTelemetriaScreenState extends State<ViajeTelemetriaScreen> {
  final _store = TelemetriaLocalStore.instance;
  final _api = TelemetriaApi();
  late TelemetriaWsClient _ws;
  StreamSubscription<TelemetriaRegistro>? _sub;

  List<TelemetriaRegistro> _registros = [];
  String _estadoWs = 'Conectando…';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _ws = TelemetriaWsClient(
      idViaje: widget.viaje.idViaje,
      rol: widget.rolWs,
    );
    _iniciar();
  }

  Future<void> _iniciar() async {
    _registros = _store.listar(widget.viaje.idViaje);
    final historial = await _api.listarPorViaje(
      idViaje: widget.viaje.idViaje,
      rol: widget.rolWs,
    );
    _store.fusionarHistorial(widget.viaje.idViaje, historial);
    if (!mounted) return;
    setState(() {
      _registros = _store.listar(widget.viaje.idViaje);
      _cargando = false;
    });

    try {
      await _ws.connect();
      if (!mounted) return;
      setState(() => _estadoWs = 'En vivo');
      _sub = _ws.stream.listen(_onNuevaLectura);
    } catch (e) {
      if (!mounted) return;
      setState(() => _estadoWs = 'Error WS: $e');
    }
  }

  void _onNuevaLectura(TelemetriaRegistro r) {
    if (r.idViaje != widget.viaje.idViaje) return;
    final lista = List<TelemetriaRegistro>.from(_registros);
    if (!lista.any((x) => x.idTelemetria == r.idTelemetria)) {
      lista.add(r);
      lista.sort((a, b) => a.registradoEn.compareTo(b.registradoEn));
      _store.fusionarHistorial(widget.viaje.idViaje, [r]);
      setState(() => _registros = lista);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ws.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.viaje;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo ?? 'Telemetría ${v.idCorto}'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              leading: Icon(
                _estadoWs == 'En vivo' ? Icons.sensors : Icons.cloud_off,
                color: _estadoWs == 'En vivo' ? Colors.green : Colors.orange,
              ),
              title: Text(_estadoWs),
              subtitle: Text('${_registros.length} lecturas'),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _registros.isEmpty
                    ? const Center(
                        child: Text(
                          'Esperando telemetría del conductor…',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _tabla(),
          ),
        ],
      ),
    );
  }

  Widget _tabla() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Hora')),
            DataColumn(label: Text('Temp °C')),
            DataColumn(label: Text('Lat')),
            DataColumn(label: Text('Lon')),
            DataColumn(label: Text('G')),
            DataColumn(label: Text('Hum')),
            DataColumn(label: Text('Alerta')),
          ],
          rows: _registros.map((r) {
            return DataRow(
              cells: [
                DataCell(Text(_fmt(r.registradoEn))),
                DataCell(Text(r.temperaturaInterna.toStringAsFixed(1))),
                DataCell(Text(r.latitud.toStringAsFixed(5))),
                DataCell(Text(r.longitud.toStringAsFixed(5))),
                DataCell(Text(r.fuerzaG.toStringAsFixed(2))),
                DataCell(Text(r.humedad?.toStringAsFixed(0) ?? '—')),
                DataCell(Text(r.alertaGenerada ?? '—')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
