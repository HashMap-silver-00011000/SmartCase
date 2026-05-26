// lib/debug/ui/debug_telemetria_screen.dart
//
// Pantalla de PRUEBA que muestra el mapa + tabla de telemetría
// con datos ficticios. No se conecta al backend ni al ESP32.
//
// Cómo acceder: desde el AdminPanelScreen hay un tile "Debug Telemetría"
// que abre esta pantalla. Solo es visible en DEBUG builds.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../conductor/models/telemetria.dart';
import '../../shared/ui/viaje_mapa_widget.dart';

// ─── Datos de prueba ──────────────────────────────────────────────────────────

/// Genera una ruta ficticia alrededor de Bucaramanga (Colombia).
/// Cada llamada agrega un punto nuevo a la trayectoria, simulando movimiento.
List<TelemetriaRegistro> _generarDummyRegistros({int cantidad = 12}) {
  final rng = Random(42); // semilla fija → mismo recorrido siempre
  final registros = <TelemetriaRegistro>[];

  // Punto de partida: centro de Bucaramanga
  double lat = 7.1193;
  double lng = -73.1227;

  final ahora = DateTime.now();

  for (var i = 0; i < cantidad; i++) {
    // Avanzar un poco en dirección noreste, con pequeña variación aleatoria
    lat += 0.0008 + rng.nextDouble() * 0.0004;
    lng += 0.0006 + rng.nextDouble() * 0.0004;

    final tempInterna = 2.0 + rng.nextDouble() * 5.0; // 2–7 °C (órgano)
    final fuerzaG = rng.nextDouble() * 3.0; // 0–3 G
    final humedad = 55.0 + rng.nextDouble() * 30.0; // 55–85 %

    String? alerta;
    if (tempInterna >= 6.5) alerta = 'Temperatura alta';
    if (fuerzaG >= 2.5) alerta = 'Impacto elevado';

    registros.add(
      TelemetriaRegistro(
        idTelemetria: 'dummy-$i',
        idViaje: 'viaje-debug',
        temperaturaInterna: double.parse(tempInterna.toStringAsFixed(1)),
        latitud: double.parse(lat.toStringAsFixed(6)),
        longitud: double.parse(lng.toStringAsFixed(6)),
        fuerzaG: double.parse(fuerzaG.toStringAsFixed(2)),
        registradoEn: ahora.subtract(Duration(seconds: (cantidad - i) * 15)),
        alertaGenerada: alerta,
        desdeBluetooth: i % 3 != 0,
        enviadoAlServidor: i < cantidad - 2,
        humedad: double.parse(humedad.toStringAsFixed(0)),
        tempAmbiente: 22.0 + rng.nextDouble() * 4,
        lux: rng.nextDouble() * 50, // caja cerrada → poca luz
        altitud: 900 + rng.nextDouble() * 200,
      ),
    );
  }

  return registros;
}

// ─── Pantalla principal ───────────────────────────────────────────────────────

class DebugTelemetriaScreen extends StatefulWidget {
  const DebugTelemetriaScreen({super.key});

  @override
  State<DebugTelemetriaScreen> createState() => _DebugTelemetriaScreenState();
}

class _DebugTelemetriaScreenState extends State<DebugTelemetriaScreen> {
  List<TelemetriaRegistro> _registros = [];
  Timer? _timer;
  bool _simulando = false;
  int _siguiente = 0; // índice del próximo registro "en vivo" a añadir
  late final List<TelemetriaRegistro> _pool; // todos los datos pre-generados

  @override
  void initState() {
    super.initState();
    _pool = _generarDummyRegistros(cantidad: 20);
    // Carga inicial: muestra los primeros 6 registros
    _registros = _pool.take(6).toList();
    _siguiente = _registros.length;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Arranca/para la simulación de llegada de datos en vivo cada 3 s.
  void _toggleSimulacion() {
    if (_simulando) {
      _timer?.cancel();
      setState(() => _simulando = false);
    } else {
      setState(() => _simulando = true);
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (_siguiente >= _pool.length) {
          _timer?.cancel();
          setState(() => _simulando = false);
          return;
        }
        setState(() {
          _registros = List.from(_registros)..add(_pool[_siguiente]);
          _siguiente++;
        });
      });
    }
  }

  void _resetear() {
    _timer?.cancel();
    setState(() {
      _simulando = false;
      _registros = _pool.take(6).toList();
      _siguiente = _registros.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          // ── Banner "modo debug" ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _DebugBanner(
                simulando: _simulando,
                totalRegistros: _registros.length,
                totalPool: _pool.length,
                onToggle: _toggleSimulacion,
                onReset: _resetear,
              ),
            ),
          ),

          // ── Mapa OSM ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    icon: Icons.map_outlined,
                    label: 'Recorrido GPS',
                    badge:
                        _registros
                            .where((r) => r.latitud != 0 || r.longitud != 0)
                            .length
                            .toString() +
                        ' puntos',
                  ),
                  const SizedBox(height: 8),
                  ViajeMapa(registros: _registros),
                ],
              ),
            ),
          ),

          // ── Tabla de sensores ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SectionHeader(
                icon: Icons.table_chart_outlined,
                label: 'Lecturas de sensores',
                badge: '${_registros.length}',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: _registros.isEmpty
                  ? const _EmptyState()
                  : _TablaRegistros(registros: _registros),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
              color: _simulando
                  ? const Color(0xFFE6F4EA)
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              _simulando ? Icons.sensors_rounded : Icons.bug_report_outlined,
              size: 18,
              color: _simulando
                  ? const Color(0xFF1B873F)
                  : const Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Debug · Telemetría',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Datos ficticios — sin backend',
                style: TextStyle(
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
}

// ─── Banner de modo debug ─────────────────────────────────────────────────────

class _DebugBanner extends StatelessWidget {
  const _DebugBanner({
    required this.simulando,
    required this.totalRegistros,
    required this.totalPool,
    required this.onToggle,
    required this.onReset,
  });

  final bool simulando;
  final int totalRegistros;
  final int totalPool;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: simulando ? const Color(0xFF81C784) : const Color(0xFFFFE082),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: simulando
                      ? const Color(0xFFE6F4EA)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  simulando ? Icons.sensors_rounded : Icons.bug_report_outlined,
                  size: 18,
                  color: simulando
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
                      simulando
                          ? 'Simulando llegada de datos…'
                          : 'Modo debug — datos ficticios',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: simulando
                            ? const Color(0xFF1B873F)
                            : const Color(0xFFB45309),
                      ),
                    ),
                    Text(
                      '$totalRegistros / $totalPool registros cargados',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A94A6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (simulando) _PulseDot(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onToggle,
                  style: FilledButton.styleFrom(
                    backgroundColor: simulando
                        ? const Color(0xFFE53935)
                        : const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(
                    simulando ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(
                    simulando ? 'Detener simulación' : 'Simular datos en vivo',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: Color(0xFFE8ECF2)),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: Color(0xFF1A1F36),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '💡 Los datos simulan un recorrido real en Bucaramanga.\n'
              'El botón ▶ agrega un nuevo punto GPS cada 3 segundos,\n'
              'igual que lo haría el ESP32 en producción.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF5B6273),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Punto pulsante ───────────────────────────────────────────────────────────

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
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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

// ─── Encabezado de sección ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label, this.badge});

  final IconData icon;
  final String label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8A94A6)),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A73E8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
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
              'Sin datos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tabla de registros ───────────────────────────────────────────────────────

class _TablaRegistros extends StatelessWidget {
  const _TablaRegistros({required this.registros});

  final List<TelemetriaRegistro> registros;

  @override
  Widget build(BuildContext context) {
    // Muestra más reciente primero
    final items = registros.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
          rows: items.map((r) {
            final tieneAlerta =
                r.alertaGenerada != null && r.alertaGenerada!.isNotEmpty;
            return DataRow(
              cells: [
                DataCell(Text(_fmt(r.registradoEn))),
                DataCell(Text(r.temperaturaInterna.toStringAsFixed(1))),
                DataCell(Text(r.latitud.toStringAsFixed(5))),
                DataCell(Text(r.longitud.toStringAsFixed(5))),
                DataCell(Text(r.fuerzaG.toStringAsFixed(2))),
                DataCell(Text(r.humedad?.toStringAsFixed(0) ?? '—')),
                DataCell(
                  tieneAlerta
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
    );
  }

  static String _fmt(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
