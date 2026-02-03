import 'package:flutter/material.dart';

import '../../../models/street_model.dart';
import '../map_risk.dart';
import '../map_helpers.dart';

class RiskSlidersSheet extends StatefulWidget {
  final List<Street> streets;
  final int? selectedStreetId;

  final Map<int, WeatherInputs> weatherByStreet;

  final ValueChanged<int?> onStreetChanged;

  final void Function(int streetId, WeatherInputs w) onWeatherChanged;

  final void Function(int streetId, WeatherInputs w) onLiveUpdate;

  final void Function(int streetId, WeatherInputs w) onApplyForStreet;

  const RiskSlidersSheet({
    super.key,
    required this.streets,
    required this.selectedStreetId,
    required this.weatherByStreet,
    required this.onStreetChanged,
    required this.onWeatherChanged,
    required this.onLiveUpdate,
    required this.onApplyForStreet,
  });

  @override
  State<RiskSlidersSheet> createState() => _RiskSlidersSheetState();
}

class _RiskSlidersSheetState extends State<RiskSlidersSheet> {
  int? _sid;
  late WeatherInputs _w;

  List<Street> get _baseStreets {
    final altIds = widget.streets
        .map((s) => s.alt?.osmId)
        .whereType<int>()
        .toSet();

    return widget.streets.where((s) => !altIds.contains(s.osmId)).toList();
  }

  @override
  void initState() {
    super.initState();

    final base = _baseStreets;
    _sid = widget.selectedStreetId ?? (base.isEmpty ? null : base.first.osmId);

    _w = (_sid == null)
        ? const WeatherInputs(
            rainIntensity: 5.0,
            rainAcc6h: 10.0,
            humidity: 60.0,
            pressure: 1010.0,
            temperature: 18.0,
            windSpeed: 4.0,
          )
        : (widget.weatherByStreet[_sid!] ??
              const WeatherInputs(
                rainIntensity: 5.0,
                rainAcc6h: 10.0,
                humidity: 60.0,
                pressure: 1010.0,
                temperature: 18.0,
                windSpeed: 4.0,
              ));

    if (_sid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onWeatherChanged(_sid!, _w);
        widget.onLiveUpdate(_sid!, _w);
      });
    }
  }

  Street? get _selectedStreet {
    final list = _baseStreets;
    if (_sid == null || list.isEmpty) return null;
    try {
      return list.firstWhere((s) => s.osmId == _sid);
    } catch (_) {
      return list.first;
    }
  }

  void _setStreetId(int? id) {
    if (id == null) return;

    final nextWeather = widget.weatherByStreet[id] ?? _w;

    setState(() {
      _sid = id;
      _w = nextWeather;
    });

    widget.onStreetChanged(id);

    widget.onWeatherChanged(id, nextWeather);
    widget.onLiveUpdate(id, nextWeather);
  }

  void _setWeather(WeatherInputs next) {
    if (_sid == null) return;

    setState(() => _w = next);

    widget.onWeatherChanged(_sid!, next);
    widget.onLiveUpdate(_sid!, next);
  }

  @override
  Widget build(BuildContext context) {
    final st = _selectedStreet;

    final slope = st?.slopePercent ?? 0.0;
    final elev = st?.elevationM ?? 600.0;

    final preview = (st == null)
        ? null
        : computeStreetRisk(w: _w, slopePercent: slope, elevationM: elev);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.40,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Weather inputs (Demo)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                "Adjust sliders then apply to compute street risk.",
                style: TextStyle(color: Colors.black.withOpacity(0.65)),
              ),
              const SizedBox(height: 12),

              _streetDropdown(),

              const SizedBox(height: 10),
              if (preview != null && st != null) _previewRiskCard(st, preview),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              _sliderTile(
                title: "Rain intensity (mm/h)",
                valueText: _w.rainIntensity.toStringAsFixed(1),
                min: 0,
                max: 50,
                value: _w.rainIntensity,
                onChanged: (v) => _setWeather(
                  WeatherInputs(
                    rainIntensity: v,
                    rainAcc6h: _w.rainAcc6h,
                    humidity: _w.humidity,
                    pressure: _w.pressure,
                    temperature: _w.temperature,
                    windSpeed: _w.windSpeed,
                  ),
                ),
              ),
              _sliderTile(
                title: "Rain accumulation 6h (mm/6h)",
                valueText: _w.rainAcc6h.toStringAsFixed(1),
                min: 0,
                max: 200,
                value: _w.rainAcc6h,
                onChanged: (v) => _setWeather(
                  WeatherInputs(
                    rainIntensity: _w.rainIntensity,
                    rainAcc6h: v,
                    humidity: _w.humidity,
                    pressure: _w.pressure,
                    temperature: _w.temperature,
                    windSpeed: _w.windSpeed,
                  ),
                ),
              ),
              _sliderTile(
                title: "Relative humidity (%)",
                valueText: _w.humidity.toStringAsFixed(0),
                min: 0,
                max: 100,
                value: _w.humidity,
                onChanged: (v) => _setWeather(
                  WeatherInputs(
                    rainIntensity: _w.rainIntensity,
                    rainAcc6h: _w.rainAcc6h,
                    humidity: v,
                    pressure: _w.pressure,
                    temperature: _w.temperature,
                    windSpeed: _w.windSpeed,
                  ),
                ),
              ),
              _sliderTile(
                title: "Pressure (hPa)",
                valueText: _w.pressure.toStringAsFixed(0),
                min: 950,
                max: 1050,
                value: _w.pressure,
                onChanged: (v) => _setWeather(
                  WeatherInputs(
                    rainIntensity: _w.rainIntensity,
                    rainAcc6h: _w.rainAcc6h,
                    humidity: _w.humidity,
                    pressure: v,
                    temperature: _w.temperature,
                    windSpeed: _w.windSpeed,
                  ),
                ),
              ),
              _sliderTile(
                title: "Temperature (°C)",
                valueText: _w.temperature.toStringAsFixed(0),
                min: -5,
                max: 45,
                value: _w.temperature,
                onChanged: (v) => _setWeather(
                  WeatherInputs(
                    rainIntensity: _w.rainIntensity,
                    rainAcc6h: _w.rainAcc6h,
                    humidity: _w.humidity,
                    pressure: _w.pressure,
                    temperature: v,
                    windSpeed: _w.windSpeed,
                  ),
                ),
              ),
              _sliderTile(
                title: "Wind speed (m/s)",
                valueText: _w.windSpeed.toStringAsFixed(1),
                min: 0,
                max: 25,
                value: _w.windSpeed,
                onChanged: (v) => _setWeather(
                  WeatherInputs(
                    rainIntensity: _w.rainIntensity,
                    rainAcc6h: _w.rainAcc6h,
                    humidity: _w.humidity,
                    pressure: _w.pressure,
                    temperature: _w.temperature,
                    windSpeed: v,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Apply risk to selected street"),
                      onPressed: () {
                        if (_sid == null) return;
                        widget.onApplyForStreet(_sid!, _w);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _streetDropdown() {
    final list = _baseStreets;

    if (list.isEmpty) {
      return Text(
        "No streets loaded yet.",
        style: TextStyle(color: Colors.black.withOpacity(0.6)),
      );
    }

    final currentId = _sid ?? list.first.osmId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<int>(
              isExpanded: true,
              underline: const SizedBox(),
              value: currentId,
              items: list.map((s) {
                return DropdownMenuItem<int>(
                  value: s.osmId,
                  child: Text(
                    s.nameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _setStreetId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderTile({
    required String title,
    required String valueText,
    required double min,
    required double max,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    valueText,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            Slider(
              min: min,
              max: max,
              value: value.clamp(min, max),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewRiskCard(Street st, double r) {
    final badgeColor = riskBadgeColor(r);
    final slope = st.slopePercent ?? 0.0;
    final elev = st.elevationM ?? 600.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: badgeColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, color: badgeColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Preview — ${st.nameAr}",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  "Slope: ${slope.toStringAsFixed(2)}% | Elev: ${elev.toStringAsFixed(1)} m",
                ),
                const SizedBox(height: 6),
                Text(
                  "Computed risk: ${(r * 100).toStringAsFixed(0)}% (${riskLabel(r)})",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
