import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class OsmMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;

  const OsmMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(latitude, longitude),
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.metro_gps',
        ),

        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(latitude, longitude),
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_pin,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }
}