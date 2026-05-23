import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.pinEntrega, // ← solo receptor lo pasa
  });

  final Viaje viaje;
  final TelemetriaWsRol rolWs;
  final String? titulo;
  final String? pinEntrega;

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
    final tienePin = widget.pinEntrega != null &&
        widget.pinEntrega!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(v),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Franja de estado WS ───────────────────────────────────────
          _WsStatusBanner(
            estado: _estadoWs,
            totalRegistros: _registros.length,
          ),

          // ── PIN de entrega (solo receptor) ────────────────────────────
          if (tienePin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: _PinEntregaWidget(pin: widget.pinEntrega!),
            ),

          const SizedBox(height: 8),

          // ── Tabla de telemetría ───────────────────────────────────────
          Expanded(
            child: _cargando
                ? _buildLoading()
                : _registros.isEmpty
                    ? _buildEmpty()
                    : _buildTabla(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Viaje v) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: Color(0xFF1A1F36)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _estadoWs == 'En vivo'
                  ? const Color(0xFFE6F4EA)
                  : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              _estadoWs == 'En vivo'
                  ? Icons.sensors_rounded
                  : Icons.sensors_off_rounded,
              size: 18,
              color: _estadoWs == 'En vivo'
                  ? const Color(0xFF1B873F)
                  : const Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.titulo ?? 'Telemetría ${v.idCorto}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                widget.rolWs.name[0].toUpperCase() +
                    widget.rolWs.name.substring(1),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8A94A6),
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFE8ECF2)),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF1A73E8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Cargando telemetría…',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.sensors_rounded,
                size: 40,
                color: Color(0xFF1A73E8),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Sin datos aún',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Esperando telemetría del conductor…',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF8A94A6),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabla() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECF2)),
          ),
          clipBehavior: Clip.hardEdge,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8F9FC)),
            headingTextStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A94A6),
              letterSpacing: 0.5,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1A1F36),
              fontWeight: FontWeight.w500,
            ),
            dividerThickness: 1,
            columnSpacing: 20,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text('HORA')),
              DataColumn(label: Text('TEMP °C')),
              DataColumn(label: Text('LAT')),
              DataColumn(label: Text('LON')),
              DataColumn(label: Text('G')),
              DataColumn(label: Text('HUM')),
              DataColumn(label: Text('ALERTA')),
            ],
            rows: _registros.map((r) {
              final tieneAlerta =
                  r.alertaGenerada != null && r.alertaGenerada!.isNotEmpty;
              return DataRow(
                cells: [
                  DataCell(Text(_fmt(r.registradoEn))),
                  DataCell(Text(r.temperaturaInterna.toStringAsFixed(1))),
                  DataCell(Text(r.latitud.toStringAsFixed(5))),
                  DataCell(Text(r.longitud.toStringAsFixed(5))),
                  DataCell(Text(r.fuerzaG.toStringAsFixed(2))),
                  DataCell(
                      Text(r.humedad?.toStringAsFixed(0) ?? '—')),
                  DataCell(
                    tieneAlerta
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              r.alertaGenerada!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB71C1C),
                              ),
                            ),
                          )
                        : const Text('—'),
                  ),
                ],
              );
            }).toList(),
          ),
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

// ─── Banner de estado WebSocket ───────────────────────────────────────────────

class _WsStatusBanner extends StatelessWidget {
  const _WsStatusBanner({
    required this.estado,
    required this.totalRegistros,
  });

  final String estado;
  final int totalRegistros;

  @override
  Widget build(BuildContext context) {
    final enVivo = estado == 'En vivo';
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enVivo
                  ? const Color(0xFFE6F4EA)
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              enVivo ? Icons.sensors_rounded : Icons.cloud_off_rounded,
              size: 18,
              color: enVivo
                  ? const Color(0xFF1B873F)
                  : const Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estado,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: enVivo
                        ? const Color(0xFF1B873F)
                        : const Color(0xFFB45309),
                  ),
                ),
                Text(
                  '$totalRegistros lecturas recibidas',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A94A6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (enVivo)
            _PulseDot(),
        ],
      ),
    );
  }
}

// ─── Punto pulsante "en vivo" ─────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFF1B873F),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─── PIN de entrega ───────────────────────────────────────────────────────────

class _PinEntregaWidget extends StatefulWidget {
  const _PinEntregaWidget({required this.pin});
  final String pin;

  @override
  State<_PinEntregaWidget> createState() => _PinEntregaWidgetState();
}

class _PinEntregaWidgetState extends State<_PinEntregaWidget> {
  bool _visible = false;

  void _copiarPin() {
    Clipboard.setData(ClipboardData(text: widget.pin));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'PIN copiado al portapapeles',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color(0xFF1B873F),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          const Icon(Icons.key_rounded, size: 17, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          const Text(
            'PIN de entrega',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _visible ? widget.pin : '••••••',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _visible
                    ? const Color(0xFF1A1F36)
                    : const Color(0xFFB45309),
                letterSpacing: _visible ? 3 : 5,
                fontFamily: 'monospace',
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _visible = !_visible),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 19,
                color: const Color(0xFFB45309),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _copiarPin,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.copy_rounded,
                size: 17,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}