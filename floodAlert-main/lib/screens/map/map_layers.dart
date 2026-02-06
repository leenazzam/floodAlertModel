import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/school_model.dart';
import '../../models/street_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/dash_polyline.dart';

LatLng midPoint(List<LatLng> pts) => pts[pts.length ~/ 2];

List<Polyline> buildPolylines({
  required List<Street> streets,
  required double riskThreshold,
  required Color Function(double) streetColorFn,
}) {
  final out = <Polyline>[];

  final byId = {for (final s in streets) s.osmId: s};
  final altStreetIds = streets
      .map((s) => s.alt?.osmId)
      .whereType<int>()
      .toSet();

  // 1) الشوارع الأساسية
  for (final st in streets) {
    if (altStreetIds.contains(st.osmId)) continue;
    if (st.path.length < 2) continue;

    out.add(
      Polyline(points: st.path, strokeWidth: 6, color: streetColorFn(st.risk)),
    );
  }

  // 2) البدائل
  for (final st in streets) {
    if (st.risk < riskThreshold) continue;
    final altId = st.alt?.osmId;
    if (altId == null) continue;

    final altStreet = byId[altId];
    if (altStreet == null || altStreet.path.length < 2) continue;

    out.addAll(
      dashedPolylinesContinuous(
        altStreet.path,
        dashMeters: 10,
        gapMeters: 30,
        strokeWidth: 6,
        color: AppColors.blue,
      ),
    );
  }

  return out;
}

List<Marker> buildMarkers({
  required List<Street> streets,
  required List<SchoolPoint> schools,
  required LatLng center,
  required double riskThreshold,
  required Color Function(double) streetColorFn,
  required void Function(SchoolPoint) onSchoolTap,
  required void Function(Street) onStreetTap,
}) {
  final schoolMarkers = schools.map((s) {
    return Marker(
      point: s.point,
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => onSchoolTap(s),
        child: const Icon(Icons.school, size: 34, color: Colors.black),
      ),
    );
  }).toList();

  final allAltIds = streets.map((s) => s.alt?.osmId).whereType<int>().toSet();

  final riskyAltIds = <int>{};
  for (final st in streets) {
    if (st.risk >= riskThreshold) {
      final altId = st.alt?.osmId;
      if (altId != null) riskyAltIds.add(altId);
    }
  }

  final streetTapMarkers = streets
      .map((st) {
        final isAltStreet = allAltIds.contains(st.osmId);
        final shouldShowAltNow = riskyAltIds.contains(st.osmId);
        if (isAltStreet && !shouldShowAltNow) return null;

        final p = st.path.isNotEmpty ? midPoint(st.path) : center;

        return Marker(
          point: p,
          width: 30,
          height: 30,
          child: GestureDetector(
            onTap: () => onStreetTap(st),
            child: Icon(Icons.circle, size: 16, color: streetColorFn(st.risk)),
          ),
        );
      })
      .whereType<Marker>()
      .toList();

  return [...schoolMarkers, ...streetTapMarkers];
}
