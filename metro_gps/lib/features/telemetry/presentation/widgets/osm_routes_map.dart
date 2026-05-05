import 'package:metro_gps/features/telemetry/domain/models/telemetry_point.dart';
import 'package:metro_gps/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OSMRoutesMap extends StatelessWidget {
  const OSMRoutesMap({
    super.key,
    required this.points,
  });

  final List<TelemetryPoint> points;

  @override
  Widget build(BuildContext context) {
    final center = points.isEmpty ? const LatLng(7.1254, -73.1198) : points.last.latLng;
    final polylinePoints = points.map((e) => e.latLng).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.metro_gps.app',
        ),
        if (polylinePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                strokeWidth: 4,
                color: AppColors.primary,
              ),
            ],
          ),
        if (polylinePoints.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: polylinePoints.last,
                width: 42,
                height: 42,
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.driver,
                  size: 34,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
