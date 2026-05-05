import 'package:metro_gps/app/providers.dart';
import 'package:metro_gps/core/widgets/empty_state_card.dart';
import 'package:metro_gps/features/auth/domain/models/user_model.dart';
import 'package:metro_gps/features/auth/presentation/widgets/role_badge.dart';
import 'package:metro_gps/features/telemetry/domain/models/ruta_model.dart';
import 'package:metro_gps/features/telemetry/domain/models/telemetry_point.dart';
import 'package:metro_gps/features/telemetry/presentation/widgets/osm_routes_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoutesMapScreen extends ConsumerStatefulWidget {
  const RoutesMapScreen({super.key, required this.user});

  final UserModel user;

  @override
  ConsumerState<RoutesMapScreen> createState() => _RoutesMapScreenState();
}

class _RoutesMapScreenState extends ConsumerState<RoutesMapScreen> {
  List<RutaModel> _rutas = <RutaModel>[];
  List<TelemetryPoint> _points = <TelemetryPoint>[];
  String? _selectedRuta;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(telemetryApiServiceProvider);
      final rutas = await api.getRutas();
      final points = await api.getTelemetria(idRuta: _selectedRuta);
      setState(() {
        _rutas = rutas;
        _points = points;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await HapticFeedback.selectionClick();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mapa de rutas - ${widget.user.nombre}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: RoleBadge(role: widget.user.rol)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedRuta,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por ruta',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todas las rutas'),
                          ),
                          ..._rutas.map(
                            (ruta) => DropdownMenuItem(
                              value: ruta.idRuta,
                              child: Text('${ruta.codigo} - ${ruta.nombre}'),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedRuta = value);
                          _refresh();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Refrescar',
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Builder(
                    builder: (_) {
                      if (_loading) {
                        return const Center(
                          key: ValueKey('loading-map'),
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (_error != null) {
                        return EmptyStateCard(
                          key: const ValueKey('error-map'),
                          title: 'Error al cargar telemetria',
                          subtitle: _error!,
                          icon: Icons.wifi_off_rounded,
                        );
                      }
                      if (_points.isEmpty) {
                        return const EmptyStateCard(
                          key: ValueKey('empty-map'),
                          title: 'Ruta sin datos',
                          subtitle: 'No hay puntos de telemetria para esta ruta.',
                          icon: Icons.route_rounded,
                        );
                      }
                      return OSMRoutesMap(
                        key: const ValueKey('data-map'),
                        points: _points,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
