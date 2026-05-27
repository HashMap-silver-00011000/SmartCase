import 'package:flutter/material.dart';
import 'shared/ui/osm_map_widget.dart';


class MapTestScreen extends StatelessWidget {
  const MapTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OSM Test'),
      ),
      body: const OsmMapWidget(
        latitude: 48.8584,
        longitude: 2.2945,
      ),
    );
  }
}