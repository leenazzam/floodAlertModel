import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/street_model.dart';
import '../../theme/app_colors.dart';

LatLngBounds boundsOf(List<LatLng> pts) {
  var minLat = pts.first.latitude;
  var maxLat = pts.first.latitude;
  var minLng = pts.first.longitude;
  var maxLng = pts.first.longitude;

  for (final p in pts) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
}

void focusStreet(MapController c, Street st, {double maxZoom = 17}) {
  if (st.path.length < 2) return;
  final b = boundsOf(st.path);
  c.fitCamera(
    CameraFit.bounds(
      bounds: b,
      padding: const EdgeInsets.all(60),
      maxZoom: maxZoom,
    ),
  );
}

void focusPoint(MapController c, LatLng p, {double zoom = 17}) {
  c.move(p, zoom);
}

String riskLabel(double r) {
  if (r >= 0.75) return "Critical";
  if (r >= 0.60) return "High";
  if (r >= 0.30) return "Medium";
  return "Low";
}

String riskPercent(double r) => ((r * 100).clamp(0, 100)).toStringAsFixed(0);

Color riskBadgeColor(double r) {
  if (r >= 0.75) return AppColors.danger;
  if (r >= 0.60) return const Color(0xFFFF8A00);
  if (r >= 0.30) return AppColors.accent;
  return Colors.green;
}

Color streetColor(double r) {
  if (r >= 0.70) return AppColors.danger;
  if (r >= 0.40) return AppColors.accent;
  return Colors.green;
}
