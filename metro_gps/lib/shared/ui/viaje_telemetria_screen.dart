// lib/shared/ui/viaje_telemetria_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../conductor/models/telemetria.dart';
import '../../conductor/telemetria_local_store.dart';
import '../../core/telemetria_api.dart';
import '../../core/telemetria_ws_client.dart';
import '../../core/telemetria_ws_paths.dart';
import '../../conductor/models/viaje.dart';
import 'viaje_mapa_widget.dart';

class ViajeTelemetriaScreen extends StatefulWidget {
  const ViajeTelemetriaScreen({
    super.key,
    required this.viaje,
    required this.rolWs,
    this.titulo,
    this.pinEntrega,
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

  TelemetriaRegistro? get _ultimo =>
      _registros.isEmpty ? null : _registros.last;

  @override
  void initState() {
    super.initState();
    _ws = TelemetriaWsClient(idViaje: widget.viaje.idViaje, rol: widget.rolWs);
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

  void _abrirHistorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistorialSheet(registros: _registros),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.viaje;
    final tienePin = widget.pinEntrega != null && widget.pinEntrega!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(v),
      body: _cargando
          ? _buildLoading()
          : CustomScrollView(
              slivers: [
                // ── Banner WebSocket ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _WsStatusBanner(
                      estado: _estadoWs,
                      totalRegistros: _registros.length,
                      ultimaLectura: _ultimo?.registradoEn,
                    ),
                  ),
                ),

                // ── PIN de entrega (solo receptor) ───────────────────────
                if (tienePin)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _PinEntregaWidget(pin: widget.pinEntrega!),
                    ),
                  ),

                // ── Tarjetas de temperatura ──────────────────────────────
                if (_ultimo != null) ...[
                  _buildSectionLabel(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    icon: Icons.thermostat_outlined,
                    label: 'Temperatura',
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SensorCard(
                              icon: Icons.thermostat_rounded,
                              iconColor: const Color(0xFF1A73E8),
                              iconBg: const Color(0xFFF0F4FF),
                              label: 'Interna',
                              value: _ultimo!.temperaturaInterna
                                  .toStringAsFixed(1),
                              unit: '°C',
                              sub: 'Caja de transporte',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SensorCard(
                              icon: Icons.device_thermostat_rounded,
                              iconColor: const Color(0xFFB45309),
                              iconBg: const Color(0xFFFFF8E1),
                              label: 'Ambiente',
                              value: _ultimo!.tempAmbiente
                                      ?.toStringAsFixed(1) ??
                                  '—',
                              unit: _ultimo!.tempAmbiente != null ? '°C' : '',
                              sub: 'Exterior',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Tarjetas de condiciones ────────────────────────────
                  _buildSectionLabel(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    icon: Icons.science_outlined,
                    label: 'Condiciones',
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
                        children: [
                          _SensorCard(
                            icon: Icons.water_drop_outlined,
                            iconColor: const Color(0xFF0891B2),
                            iconBg: const Color(0xFFE0F7FA),
                            label: 'Humedad',
                            value: _ultimo!.humedad?.toStringAsFixed(1) ?? '—',
                            unit: _ultimo!.humedad != null ? '%' : '',
                            sub: 'Relativa',
                          ),
                          _SensorCard(
                            icon: Icons.light_mode_outlined,
                            iconColor: const Color(0xFFD97706),
                            iconBg: const Color(0xFFFEF9C3),
                            label: 'Luminosidad',
                            value: _ultimo!.lux?.toStringAsFixed(0) ?? '—',
                            unit: _ultimo!.lux != null ? 'lux' : '',
                            sub: 'Ambiental',
                          ),
                          _SensorCard(
                            icon: Icons.landscape_outlined,
                            iconColor: const Color(0xFF059669),
                            iconBg: const Color(0xFFECFDF5),
                            label: 'Altitud',
                            value:
                                _ultimo!.altitud?.toStringAsFixed(0) ?? '—',
                            unit: _ultimo!.altitud != null ? 'm' : '',
                            sub: 'Sobre el nivel del mar',
                          ),
                          _SensorCard(
                            icon: Icons.vibration_rounded,
                            iconColor: const Color(0xFF7C3AED),
                            iconBg: const Color(0xFFF5F3FF),
                            label: 'Impacto G',
                            value: _ultimo!.fuerzaG.toStringAsFixed(2),
                            unit: 'G',
                            sub: 'Fuerza registrada',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Mapa GPS ───────────────────────────────────────────
                  _buildSectionLabel(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    icon: Icons.map_outlined,
                    label: 'Recorrido GPS',
                    badge: _registros
                            .where((r) => r.latitud != 0 || r.longitud != 0)
                            .length
                            .toString() +
                        ' puntos',
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ViajeMapa(registros: _registros, height: 420),
                    ),
                  ),

                  // ── Alerta ─────────────────────────────────────────────
                  if (_ultimo!.alertaGenerada != null &&
                      _ultimo!.alertaGenerada!.isNotEmpty) ...[
                    _buildSectionLabel(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      icon: Icons.warning_amber_rounded,
                      label: 'Alerta activa',
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _AlertaCard(
                            alerta: _ultimo!.alertaGenerada!),
                      ),
                    ),
                  ],
                ],

                // ── Sin datos aún ──────────────────────────────────────
                if (_ultimo == null)
                  SliverToBoxAdapter(child: _buildEmpty()),

                // ── Botón historial ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: _HistorialButton(
                      total: _registros.length,
                      onTap: _registros.isEmpty ? null : _abrirHistorial,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  SliverToBoxAdapter _buildSectionLabel({
    required EdgeInsets padding,
    required IconData icon,
    required String label,
    String? badge,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF8A94A6)),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A94A6),
                letterSpacing: 0.7,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A73E8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Viaje v) {
    final enVivo = _estadoWs == 'En vivo';
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Color(0xFF1A1F36),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: enVivo
                  ? const Color(0xFFE6F4EA)
                  : const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              enVivo ? Icons.sensors_rounded : Icons.sensors_off_rounded,
              size: 18,
              color: enVivo
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
        padding: const EdgeInsets.symmetric(vertical: 48),
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

  static String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// ─── Tarjeta de sensor individual ────────────────────────────────────────────

class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.unit,
    required this.sub,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String unit;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A94A6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36),
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8A94A6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8A94A6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tarjeta de alerta ────────────────────────────────────────────────────────

class _AlertaCard extends StatelessWidget {
  const _AlertaCard({required this.alerta});
  final String alerta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB71C1C),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alerta,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB71C1C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botón "Ver historial" ────────────────────────────────────────────────────

class _HistorialButton extends StatelessWidget {
  const _HistorialButton({required this.total, this.onTap});
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECF2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ver historial de lecturas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Todos los registros del viaje',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A94A6),
                      ),
                    ),
                  ],
                ),
              ),
              if (total > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A73E8),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF8A94A6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Sheet de historial ────────────────────────────────────────────────

class _HistorialSheet extends StatelessWidget {
  const _HistorialSheet({required this.registros});
  final List<TelemetriaRegistro> registros;

  @override
  Widget build(BuildContext context) {
    final invertidos = registros.reversed.toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF4F6FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle + cabecera
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE8ECF2)),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8ECF2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: Color(0xFF1A73E8),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Historial de lecturas',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1F36),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${registros.length} registros',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A73E8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de registros
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: invertidos.length,
                itemBuilder: (_, i) =>
                    _HistorialItem(registro: invertidos[i], index: i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Item del historial ───────────────────────────────────────────────────────

class _HistorialItem extends StatelessWidget {
  const _HistorialItem({required this.registro, required this.index});
  final TelemetriaRegistro registro;
  final int index;

  @override
  Widget build(BuildContext context) {
    final r = registro;
    final tieneAlerta =
        r.alertaGenerada != null && r.alertaGenerada!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tieneAlerta
              ? const Color(0xFFFFCDD2)
              : const Color(0xFFE8ECF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hora + alerta badge
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 13,
                color: Color(0xFF8A94A6),
              ),
              const SizedBox(width: 5),
              Text(
                _fmt(r.registradoEn),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              if (tieneAlerta)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    r.alertaGenerada!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Valores en grid compacto
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _MiniVal(
                  label: 'T. interna',
                  value: '${r.temperaturaInterna.toStringAsFixed(1)} °C'),
              if (r.tempAmbiente != null)
                _MiniVal(
                    label: 'T. amb.',
                    value: '${r.tempAmbiente!.toStringAsFixed(1)} °C'),
              if (r.humedad != null)
                _MiniVal(
                    label: 'Humedad',
                    value: '${r.humedad!.toStringAsFixed(0)} %'),
              if (r.lux != null)
                _MiniVal(
                    label: 'Lux', value: '${r.lux!.toStringAsFixed(0)}'),
              if (r.altitud != null)
                _MiniVal(
                    label: 'Altitud',
                    value: '${r.altitud!.toStringAsFixed(0)} m'),
              _MiniVal(
                  label: 'G', value: r.fuerzaG.toStringAsFixed(2)),
              if (r.latitud != 0 || r.longitud != 0)
                _MiniVal(
                    label: 'GPS',
                    value:
                        '${r.latitud.toStringAsFixed(4)}, ${r.longitud.toStringAsFixed(4)}'),
            ],
          ),
        ],
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

class _MiniVal extends StatelessWidget {
  const _MiniVal({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF8A94A6)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1F36),
          ),
        ),
      ],
    );
  }
}

// ─── Banner de estado WebSocket ───────────────────────────────────────────────

class _WsStatusBanner extends StatelessWidget {
  const _WsStatusBanner({
    required this.estado,
    required this.totalRegistros,
    this.ultimaLectura,
  });

  final String estado;
  final int totalRegistros;
  final DateTime? ultimaLectura;

  @override
  Widget build(BuildContext context) {
    final enVivo = estado == 'En vivo';
    return Container(
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
          if (ultimaLectura != null)
            Text(
              _fmtHora(ultimaLectura!),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF8A94A6),
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
          if (enVivo) ...[
            const SizedBox(width: 10),
            _PulseDot(),
          ],
        ],
      ),
    );
  }

  static String _fmtHora(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

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
            Text('PIN copiado al portapapeles',
                style: TextStyle(fontSize: 13)),
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