import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// dashMeters = طول الشرطة
/// gapMeters  = طول الفراغ
List<Polyline> dashedPolylinesContinuous(
  List<LatLng> pts, {
  required double dashMeters,
  required double gapMeters,
  required double strokeWidth,
  required Color color,
  StrokeCap cap = StrokeCap.round,
}) {
  if (pts.length < 2) return [];
  if (dashMeters <= 0) return [];

  const dist = Distance();
  final pattern = dashMeters + gapMeters;

  final out = <Polyline>[];

  double phase = 0.0;
  LatLng? dashStart;

  for (int i = 0; i < pts.length - 1; i++) {
    final a = pts[i];
    final b = pts[i + 1];
    final segLen = dist(a, b);
    if (segLen <= 0) continue;

    final bearing = dist.bearing(a, b);

    double walkedOnSeg = 0.0;

    while (walkedOnSeg < segLen) {
      final remainingSeg = segLen - walkedOnSeg;
      final remainingPattern = pattern - phase;
      final step = remainingSeg < remainingPattern
          ? remainingSeg
          : remainingPattern;

      final inDash = phase < dashMeters;

      final p1 = dist.offset(a, walkedOnSeg, bearing);
      final p2 = dist.offset(a, walkedOnSeg + step, bearing);

      if (inDash) {
        dashStart ??= p1;

        final dashRemaining = dashMeters - phase;
        if (step >= dashRemaining) {
          final dashEnd = dist.offset(a, walkedOnSeg + dashRemaining, bearing);
          out.add(
            Polyline(
              points: [dashStart, dashEnd],
              strokeWidth: strokeWidth,
              color: color,
              strokeCap: cap,
            ),
          );
          dashStart = null;
        }
      } else {
        dashStart = null;
      }

      walkedOnSeg += step;
      phase += step;

      if (phase >= pattern) {
        phase = 0.0;
      }
    }
  }

  return out;
}
