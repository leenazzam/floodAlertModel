import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AppMap extends StatelessWidget {
  final MapController controller;
  final LatLng center;
  final double zoom;

  final List<Marker> markers;
  final List<Polyline> polylines;
  final List<Marker> extraMarkers;

  final ValueChanged<double>? onZoomChanged;

  const AppMap({
    super.key,
    required this.controller,
    required this.center,
    required this.zoom,
    this.markers = const [],
    this.polylines = const [],
    this.extraMarkers = const [],
    this.onZoomChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        onPositionChanged: (pos, _) {
          final z = pos.zoom;
          if (z != null) onZoomChanged?.call(z);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: "com.example.floodalert",
        ),

        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        if (extraMarkers.isNotEmpty) MarkerLayer(markers: extraMarkers),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }
}
