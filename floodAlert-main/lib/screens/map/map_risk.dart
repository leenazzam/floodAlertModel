import '../../models/school_model.dart';
import '../../models/street_model.dart';

class WeatherInputs {
  final double rainIntensity; // mm/h
  final double rainAcc6h; // mm/6h
  final double humidity; // %
  final double pressure; // hPa
  final double temperature; // C
  final double windSpeed; // m/s

  const WeatherInputs({
    required this.rainIntensity,
    required this.rainAcc6h,
    required this.humidity,
    required this.pressure,
    required this.temperature,
    required this.windSpeed,
  });

  Map<String, dynamic> toJson() => {
    "rain_intensity": rainIntensity,
    "rain_acc_6h": rainAcc6h,
    "humidity": humidity,
    "pressure": pressure,
    "temperature": temperature,
    "wind_speed": windSpeed,
  };
}

double _clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

double _norm(double v, double min, double max) {
  if (max <= min) return 0;
  return _clamp01((v - min) / (max - min));
}

/// Demo heuristic
double computeStreetRisk({
  required WeatherInputs w,
  required double slopePercent, // %
  required double elevationM, // m
}) {
  final nI = _norm(w.rainIntensity, 0, 50);
  final nA = _norm(w.rainAcc6h, 0, 200);
  final nH = _norm(w.humidity, 20, 100);
  final nP = _norm(1025 - w.pressure, 0, 50);
  final nT = _norm(w.temperature, 0, 35);
  final nW = _norm(w.windSpeed, 0, 25);

  final nS = _norm(slopePercent, 0, 20);
  final nE = 1.0 - _norm(elevationM, 450, 800);

  final rainScore = 0.55 * nI + 0.45 * nA;
  final meteoScore = 0.30 * nH + 0.35 * nP + 0.15 * nW + 0.20 * nT;
  final terrainScore = 0.65 * nS + 0.35 * nE;

  final raw = 0.55 * rainScore + 0.25 * meteoScore + 0.20 * terrainScore;
  return _clamp01(raw * 1.10);
}

({List<Street> streets, List<SchoolPoint> schools}) applyRiskToSingleStreet({
  required List<Street> streets,
  required List<SchoolPoint> schools,
  required int streetId,
  required WeatherInputs w,
}) {
  final updatedStreets = streets.map((st) {
    if (st.osmId != streetId) return st;

    final r = computeStreetRisk(
      w: w,
      slopePercent: st.slopePercent ?? 0.0,
      elevationM: st.elevationM ?? 600.0,
    );
    st.risk = r;
    return st;
  }).toList();

  final riskByStreetId = {for (final st in updatedStreets) st.osmId: st.risk};

  final updatedSchools = schools.map((sch) {
    if (sch.nearestStreetOsmId != streetId) return sch;

    final r = riskByStreetId[streetId] ?? sch.risk;
    return SchoolPoint(
      id: sch.id,
      name: sch.name,
      point: sch.point,
      risk: r,
      nearestStreetOsmId: sch.nearestStreetOsmId,
      nearestStreetNameAr: sch.nearestStreetNameAr,
    );
  }).toList();

  return (streets: updatedStreets, schools: updatedSchools);
}

({List<Street> streets, List<SchoolPoint> schools}) applyRiskToAllStreets({
  required List<Street> streets,
  required List<SchoolPoint> schools,
  required WeatherInputs w,
}) {
  final updatedStreets = streets.map((st) {
    final r = computeStreetRisk(
      w: w,
      slopePercent: st.slopePercent ?? 0.0,
      elevationM: st.elevationM ?? 600.0,
    );
    st.risk = r;
    return st;
  }).toList();

  final riskByStreetId = {for (final st in updatedStreets) st.osmId: st.risk};

  final updatedSchools = schools.map((sch) {
    final sid = sch.nearestStreetOsmId;
    final r = (sid != null) ? (riskByStreetId[sid] ?? sch.risk) : sch.risk;
    return SchoolPoint(
      id: sch.id,
      name: sch.name,
      point: sch.point,
      risk: r,
      nearestStreetOsmId: sch.nearestStreetOsmId,
      nearestStreetNameAr: sch.nearestStreetNameAr,
    );
  }).toList();

  return (streets: updatedStreets, schools: updatedSchools);
}
