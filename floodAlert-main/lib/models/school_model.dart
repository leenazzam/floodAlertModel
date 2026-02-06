import 'package:latlong2/latlong.dart';

class SchoolPoint {
  final String id;
  final String name;
  final LatLng point;
  final double risk;

  final int? nearestStreetOsmId;
  final String? nearestStreetNameAr;

  const SchoolPoint({
    required this.id,
    required this.name,
    required this.point,
    required this.risk,
    this.nearestStreetOsmId,
    this.nearestStreetNameAr,
  });

  factory SchoolPoint.fromJson(Map<String, dynamic> j) {
    return SchoolPoint(
      id: j["id"].toString(),
      name: j["name"] ?? "",
      point: LatLng((j["lat"] as num).toDouble(), (j["lng"] as num).toDouble()),
      risk: ((j["risk"] ?? 0.0) as num).toDouble(),
      nearestStreetOsmId: (j["nearest_street_osm_id"] as num?)?.toInt(),
      nearestStreetNameAr: j["nearest_street_name_ar"] as String?,
    );
  }
}
