import 'package:floodalert/repo/street_store.dart';
import 'package:floodalert/screens/alerts_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../repo/refidia_repository.dart';
import '../models/school_model.dart';
import '../models/street_model.dart';

import '../widgets/app_map.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/map_search_bar.dart';
import 'settings_page.dart';

import 'map/map_helpers.dart';
import 'map/map_layers.dart';
import 'map/map_risk.dart';
import 'map/map_advisories.dart';

import 'map/sheets/risk_sliders_sheet.dart';
import 'map/sheets/school_sheet.dart';
import 'map/sheets/street_sheet.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int _currentIndex = 0;

  static const double _homeZoom = 13.5;
  double _zoom = _homeZoom;

  static const double _riskThreshold = 0.60;
  static const int _forecastHorizonHours = 12;

  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

  final RefidiaRepository _refidiaRepo = RefidiaRepository.instance;

  final Map<int, WeatherInputs> _weatherByStreet = {};

  List<SchoolPoint> _schools = [];
  List<Street> _streets = [];

  // sliders state
  WeatherInputs _weather = const WeatherInputs(
    rainIntensity: 5.0,
    rainAcc6h: 10.0,
    humidity: 60.0,
    pressure: 1010.0,
    temperature: 18.0,
    windSpeed: 4.0,
  );

  WeatherInputs _weatherFor(int streetId) {
    return _weatherByStreet[streetId] ?? _weather;
  }

  void _setWeatherFor(int streetId, WeatherInputs w) {
    _weatherByStreet[streetId] = w;
    _weather = w;
  }

  int? _selectedStreetId;

  static const LatLng _refidiaCenter = LatLng(32.2241748, 35.2338782);
  LatLng get _center => _refidiaCenter;

  Map<int, Street> get _byId => {for (final s in _streets) s.osmId: s};

  @override
  void initState() {
    super.initState();
    _loadLayers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_center, _homeZoom);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onNavTap(int i) => setState(() => _currentIndex = i);

  Future<void> _loadLayers() async {
    try {
      final streets = await _refidiaRepo.fetchStreets();
      final schools = await _refidiaRepo.fetchSchools();
      StreetStore.instance.setStreets(streets);

      final riskByStreetId = {for (final st in streets) st.osmId: st.risk};

      final fixedSchools = schools.map((sch) {
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

      if (!mounted) return;
      setState(() {
        _streets = streets;
        _schools = fixedSchools;
        _selectedStreetId = streets.isNotEmpty ? streets.first.osmId : null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load layers: $e")));
    }
  }

  void _applyRiskNow() {
    final result = applyRiskToAllStreets(
      streets: _streets,
      schools: _schools,
      w: _weather,
    );

    setState(() {
      _streets = result.streets;
      _schools = result.schools;
    });

    StreetStore.instance.setUpdatedStreets(_streets);
  }

  void _openRiskSlidersSheet() {
    final baseId =
        _selectedStreetId ?? (_streets.isEmpty ? null : _streets.first.osmId);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => RiskSlidersSheet(
        streets: _streets,
        selectedStreetId: baseId,
        weatherByStreet: _weatherByStreet,

        onStreetChanged: (id) {
          if (id == null) return;
          setState(() {
            _selectedStreetId = id;
            _weather = _weatherFor(id);
          });
        },

        onWeatherChanged: (streetId, w) {
          setState(() => _setWeatherFor(streetId, w));
        },

        onLiveUpdate: (streetId, w) {
          setState(() => _setWeatherFor(streetId, w));

          final result = applyRiskToSingleStreet(
            streets: _streets,
            schools: _schools,
            streetId: streetId,
            w: w,
          );

          setState(() {
            _streets = result.streets;
            _schools = result.schools;
          });

          StreetStore.instance.setUpdatedStreets(_streets);
        },

        onApplyForStreet: (streetId, w) {
          setState(() => _setWeatherFor(streetId, w));

          final result = applyRiskToSingleStreet(
            streets: _streets,
            schools: _schools,
            streetId: streetId,
            w: w,
          );

          setState(() {
            _streets = result.streets;
            _schools = result.schools;
          });

          StreetStore.instance.setUpdatedStreets(_streets);

          Navigator.pop(context);
        },
      ),
    );
  }

  void _openSchoolSheet(SchoolPoint s) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SchoolSheet(
        school: s,
        byId: _byId,
        forecastHorizonHours: _forecastHorizonHours,
        riskLabel: riskLabel,
        riskPercent: riskPercent,
        riskBadgeColor: riskBadgeColor,
        schoolAdvisories: (r) =>
            schoolAdvisories(r, forecastHorizonHours: _forecastHorizonHours),
        onZoomToSchool: () {
          focusPoint(_mapController, s.point, zoom: 18);
          setState(() => _zoom = 18);
        },
        onZoomToStreet: (st) {
          focusStreet(_mapController, st, maxZoom: 17);
        },
      ),
    );
  }

  void _openStreetSheet(Street st) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => StreetSheet(
        street: st,
        byId: _byId,
        riskThreshold: _riskThreshold,
        riskLabel: riskLabel,
        riskPercent: riskPercent,
        riskBadgeColor: riskBadgeColor,
        municipalityAdvisories: municipalityAdvisories,
        onZoomToStreet: (s) => focusStreet(_mapController, s, maxZoom: 17),
        onZoomToAlt: (s) => focusStreet(_mapController, s, maxZoom: 17),
      ),
    );
  }

  void _zoomIn() {
    _zoom = (_zoom + 1).clamp(3.0, 19.0);
    _mapController.move(_mapController.camera.center, _zoom);
    setState(() {});
  }

  void _zoomOut() {
    _zoom = (_zoom - 1).clamp(3.0, 19.0);
    _mapController.move(_mapController.camera.center, _zoom);
    setState(() {});
  }

  void _goToCenter() {
    _zoom = _homeZoom;
    _mapController.move(_center, _homeZoom);
    setState(() {});
  }

  Widget _buildMapBody() {
    final polylines = buildPolylines(
      streets: _streets,
      riskThreshold: _riskThreshold,
      streetColorFn: streetColor,
    );

    final markers = buildMarkers(
      streets: _streets,
      schools: _schools,
      center: _center,
      riskThreshold: _riskThreshold,
      streetColorFn: streetColor,
      onSchoolTap: _openSchoolSheet,
      onStreetTap: _openStreetSheet,
    );

    return Stack(
      children: [
        Positioned(
          child: AppMap(
            controller: _mapController,
            center: _center,
            zoom: _zoom,
            polylines: polylines,
            extraMarkers: markers,
            onZoomChanged: (z) {
              if (z == _zoom) return;
              setState(() => _zoom = z);
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: MapSearchBar(
              controller: _searchController,
              onFilterTap: _openRiskSlidersSheet,
              onSubmitted: (value) {},
            ),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: "go_center",
            onPressed: _goToCenter,
            child: const Icon(Icons.my_location),
          ),
        ),
        Positioned(
          right: 12,
          bottom: 160,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: "zoom_in",
                mini: true,
                onPressed: _zoomIn,
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "zoom_out",
                mini: true,
                onPressed: _zoomOut,
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_currentIndex) {
      0 => _buildMapBody(),
      1 => const AlertsPage(),
      _ => const SettingsPage(),
    };
    return Scaffold(
      body: body,
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
