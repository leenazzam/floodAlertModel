import 'package:latlong2/latlong.dart';

class Street {
  final int osmId;
  final String nameAr;
  final String? nameEn;
  final String? highway;
  final bool oneway;
  final List<LatLng> path;

  final double? slopePercent;
  final double? elevationM;

  double risk;

  final AltStreet? alt;

  Street({
    required this.osmId,
    required this.nameAr,
    required this.path,
    required this.oneway,
    required this.risk,
    this.nameEn,
    this.highway,
    this.slopePercent,
    this.elevationM,
    this.alt,
  });

  factory Street.fromJson(Map<String, dynamic> j) {
    final pathList = (j['path'] as List<dynamic>)
        .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();

    return Street(
      osmId: (j['osm_id'] as num).toInt(),
      path: pathList,
      nameAr: (j['name_ar'] ?? '') as String,
      nameEn: j['name_en'] as String?,
      highway: j['highway'] as String?,
      oneway: (j['oneway'] ?? false) as bool,
      risk: ((j['risk'] ?? 0.0) as num).toDouble(),
      slopePercent: (j['slope_percent'] == null)
          ? null
          : ((j['slope_percent'] as num).toDouble()),
      elevationM: (j['elevation_m'] == null)
          ? null
          : ((j['elevation_m'] as num).toDouble()),
      alt: (j['alt'] == null) ? null : AltStreet.fromJson(j['alt']),
    );
  }
}

class AltStreet {
  final int? osmId;
  final String nameAr;

  AltStreet({required this.nameAr, this.osmId});

  factory AltStreet.fromJson(Map<String, dynamic> j) {
    return AltStreet(
      osmId: j['osm_id'] == null ? null : (j['osm_id'] as num).toInt(),
      nameAr: (j['name_ar'] ?? '') as String,
    );
  }
}
