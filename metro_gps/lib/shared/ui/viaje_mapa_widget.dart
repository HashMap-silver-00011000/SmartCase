// lib/shared/ui/viaje_mapa_widget.dart
//
// Mapa OSM reutilizable que muestra el recorrido GPS de un viaje.
// Usa flutter_map (ya en pubspec.yaml) + latlong2 (también ya incluido).
//
// Uso mínimo:
//   ViajeMapa(registros: _registros)

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../conductor/models/telemetria.dart';

class ViajeMapa extends StatefulWidget {
  const ViajeMapa({super.key, required this.registros, this.height = 280});

  /// Lista de registros de telemetría (puede estar vacía).
  final List<TelemetriaRegistro> registros;

  /// Alto del mapa en píxeles lógicos.
  final double height;

  @override
  State<ViajeMapa> createState() => _ViajeMapaState();
}

class _ViajeMapaState extends State<ViajeMapa> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  /// Filtra solo los registros que tienen coordenadas reales (no 0,0).
  List<TelemetriaRegistro> get _conGps =>
      widget.registros.where((r) => r.latitud != 0 || r.longitud != 0).toList();

  List<LatLng> get _puntos =>
      _conGps.map((r) => LatLng(r.latitud, r.longitud)).toList();

  /// Centro del mapa: último punto GPS conocido, o Bogotá como fallback.
  LatLng get _centro {
    if (_conGps.isEmpty) return const LatLng(4.711, -74.0721); // Bogotá
    final ultimo = _conGps.last;
    return LatLng(ultimo.latitud, ultimo.longitud);
  }

  /// Zoom inicial: más cercano si hay varios puntos, alejado si solo hay uno.
  double get _zoom => _conGps.length > 1 ? 14.0 : 13.0;

  void _centrarEnUltimo() {
    if (_conGps.isEmpty) return;
    _mapController.move(_centro, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    final puntos = _puntos;
    final sinDatos = puntos.isEmpty;

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // ── Mapa base ────────────────────────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _centro,
                initialZoom: _zoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // Capa de tiles OpenStreetMap (no requiere API key)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.metro_gps',
                  maxZoom: 19,
                ),

                // Línea de recorrido
                if (puntos.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: puntos,
                        strokeWidth: 3.5,
                        color: const Color(0xFF1A73E8),
                      ),
                    ],
                  ),

                // Marcadores: puntos intermedios (azul pequeño) + último (rojo)
                MarkerLayer(
                  markers: [
                    // Puntos de ruta anteriores
                    for (final p in puntos.take(
                      puntos.length > 1 ? puntos.length - 1 : 0,
                    ))
                      Marker(
                        point: p,
                        width: 10,
                        height: 10,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A73E8),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // Último punto conocido (posición actual)
                    if (puntos.isNotEmpty)
                      Marker(
                        point: puntos.last,
                        width: 36,
                        height: 36,
                        child: const _PosicionActualPin(),
                      ),
                  ],
                ),
              ],
            ),

            // ── Overlay: sin datos GPS ───────────────────────────────────
            if (sinDatos)
              Container(
                color: const Color(0xFFF4F6FA).withOpacity(0.85),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 36,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sin coordenadas GPS aún',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Botón "centrar" (esquina inferior derecha) ───────────────
            if (!sinDatos)
              Positioned(
                bottom: 12,
                right: 12,
                child: _MapButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Centrar en posición actual',
                  onTap: _centrarEnUltimo,
                ),
              ),

            // ── Atribución OSM (requerida por la licencia) ───────────────
            Positioned(
              bottom: 4,
              left: 8,
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pin animado para la posición actual ──────────────────────────────────────

class _PosicionActualPin extends StatelessWidget {
  const _PosicionActualPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo exterior
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        // Punto central
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Botón flotante sobre el mapa ─────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.onTap,
    this.tooltip = '',
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF1A73E8)),
        ),
      ),
    );
  }
}
