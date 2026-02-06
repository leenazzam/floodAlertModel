import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../repo/street_store.dart';
import '../models/street_model.dart';
import '../theme/app_colors.dart';
import '../widgets/advisory_section.dart';
import 'map/sheets/street_sheet.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  int? _selectedStreetId;

  // Risk helpers (same as map)
  static const double _riskThreshold = 0.60;

  String _riskLabel(double r) {
    if (r >= 0.75) return "Critical";
    if (r >= 0.60) return "High";
    if (r >= 0.30) return "Medium";
    return "Low";
  }

  String _riskPercent(double r) =>
      ((r * 100).clamp(0.0, 100.0)).toStringAsFixed(0);

  Color _riskBadgeColor(double r) {
    if (r >= 0.75) return AppColors.danger;
    if (r >= 0.60) return const Color(0xFFFF8A00);
    if (r >= 0.30) return AppColors.accent;
    return Colors.green;
  }

  List<AdvisoryItem> _municipalityAdvisories(double r, Street st) {
    if (r >= 0.75) {
      return const [
        AdvisoryItem(
          title: "إجراء فوري (Critical)",
          lines: [
            "إغلاق المقاطع الحرجة فوراً عند بدء تجمع المياه.",
            "تنبيه السكان القريبين.",
            "تفعيل طوارئ البلدية/الدفاع المدني.",
          ],
          icon: Icons.warning_amber_rounded,
          emphasis: true,
        ),
      ];
    }
    if (r >= 0.60) {
      return const [
        AdvisoryItem(
          title: "استعداد عالي (High)",
          lines: [
            "تجهيز تحويلات سير وإغلاق جزئي عند الحاجة.",
            "زيادة المراقبة في المناطق المنخفضة.",
          ],
          icon: Icons.report,
          emphasis: true,
        ),
      ];
    }
    if (r >= 0.30) {
      return const [
        AdvisoryItem(
          title: "مراقبة (Medium)",
          lines: ["تنظيف المصارف القريبة.", "متابعة الحالة كل فترة."],
          icon: Icons.visibility,
        ),
      ];
    }
    return const [
      AdvisoryItem(
        title: "طبيعي (Low)",
        lines: ["متابعة دورية فقط."],
        icon: Icons.check_circle,
      ),
    ];
  }

  // City dashboard (city-wide)
  double _cityRiskFromBase(List<Street> streetsBase) {
    if (streetsBase.isEmpty) return 0.0;
    final maxRisk = streetsBase.map((s) => s.risk).reduce(max);
    return maxRisk.clamp(0.0, 1.0);
  }

  List<double> _cityRain12hSeries(double cityRisk) {
    final base = 6 + (cityRisk * 40);
    return List.generate(12, (i) {
      final peakAt = 2;
      final dist = (i - peakAt).abs();
      final shape = exp(-dist / 2.0).toDouble();
      final noise = ((sin(i * 1.3) + 1) * 0.8).toDouble();
      final v = (base * shape + noise).toDouble();
      return v.clamp(0.0, 100.0).toDouble();
    });
  }

  double _cityFloodProb12h(double cityRisk) =>
      (cityRisk * 100).clamp(0.0, 100.0).toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,

      body: ValueListenableBuilder<List<Street>>(
        valueListenable: StreetStore.instance.streetsAll,
        builder: (context, streetsAll, _) {
          if (streetsAll.isEmpty) {
            return const Center(child: Text("No streets loaded yet"));
          }

          final altIds = streetsAll
              .map((s) => s.alt?.osmId)
              .whereType<int>()
              .toSet();
          final streetsBase =
              streetsAll.where((s) => !altIds.contains(s.osmId)).toList()
                ..sort((a, b) => b.risk.compareTo(a.risk));

          final cityRisk = _cityRiskFromBase(streetsBase);

          final selectedNow = () {
            final id = _selectedStreetId;
            if (id == null) return streetsBase.first;
            return streetsAll.firstWhere(
              (s) => s.osmId == id,
              orElse: () => streetsBase.first,
            );
          }();

          final byId = {for (final s in streetsAll) s.osmId: s};

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ProbDonutCard(
                title: "City flood probability within 12 hours",
                value: _cityFloodProb12h(cityRisk),
              ),
              const SizedBox(height: 16),
              _RainChartCard(
                title: "City rainfall intensity forecast (mm/h) • Next 12h",
                series: _cityRain12hSeries(cityRisk),
              ),
              const SizedBox(height: 14),

              Text(
                "Streets alerts",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(0.80),
                ),
              ),
              const SizedBox(height: 10),

              ...streetsBase.map((st) {
                final isSelected = st.osmId == selectedNow.osmId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AlertTile(
                    name: st.nameAr.isNotEmpty ? st.nameAr : "Unnamed street",
                    risk: st.risk,
                    selected: isSelected,
                    onTap: () {
                      setState(() => _selectedStreetId = st.osmId);

                      showModalBottomSheet(
                        context: context,
                        showDragHandle: true,
                        isScrollControlled: true,
                        builder: (_) => StreetSheet(
                          street: byId[st.osmId] ?? st,
                          byId: byId,
                          riskThreshold: _riskThreshold,
                          riskLabel: _riskLabel,
                          riskPercent: _riskPercent,
                          riskBadgeColor: _riskBadgeColor,
                          municipalityAdvisories: _municipalityAdvisories,
                          onZoomToStreet: (_) {},
                          onZoomToAlt: (_) {},
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

// Cards
class _DashboardCard extends StatelessWidget {
  final Widget child;
  const _DashboardCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RainChartCard extends StatelessWidget {
  final String title;
  final List<double> series;
  const _RainChartCard({required this.title, required this.series});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (int i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i]),
    ];

    final peakI = series.indexOf(series.reduce(max)).toDouble();

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 11,
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 25,
                  verticalInterval: 2,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                    dashArray: [6, 6],
                  ),
                  getDrawingVerticalLine: (v) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [6, 6],
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 25,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (v, _) => Text(
                        "${v.toInt()}h",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: peakI,
                      color: Colors.redAccent.withOpacity(0.85),
                      strokeWidth: 2,
                      label: VerticalLineLabel(
                        show: true,
                        alignment: Alignment.topLeft,
                        labelResolver: (_) => "Peak",
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.blue,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.withOpacity(0.30),
                          Colors.blue.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String t;
  const _CardTitle(this.t);

  @override
  Widget build(BuildContext context) {
    return Text(
      t,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontWeight: FontWeight.w900,
        fontSize: 14,
      ),
    );
  }
}

class _ProbDonutCard extends StatelessWidget {
  final String title;
  final double value;
  const _ProbDonutCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final double v = value.clamp(0.0, 100.0).toDouble();
    final isHigh = v >= 70;
    final main = isHigh ? AppColors.danger : AppColors.accent;
    final sub = isHigh ? "Very High" : "Moderate";

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(title),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 0,
                    centerSpaceRadius: 52,
                    sections: [
                      PieChartSectionData(
                        value: v,
                        color: main,
                        radius: 16,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 100 - v,
                        color: Colors.grey.shade200,
                        radius: 16,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${v.toStringAsFixed(0)}%",
                      style: TextStyle(
                        color: main,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      sub,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//AlertTile
class _AlertTile extends StatelessWidget {
  final String name;
  final double risk;
  final bool selected;
  final VoidCallback onTap;

  const _AlertTile({
    required this.name,
    required this.risk,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (risk * 100).toStringAsFixed(0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.notifications_active, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Risk: $pct%",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
