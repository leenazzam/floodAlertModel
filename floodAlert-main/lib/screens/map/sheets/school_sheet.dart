import 'package:flutter/material.dart';

import '../../../models/school_model.dart';
import '../../../models/street_model.dart';
import '../../../widgets/advisory_section.dart';
import '../../../widgets/risk_badge.dart';

class SchoolSheet extends StatelessWidget {
  final SchoolPoint school;
  final Map<int, Street> byId;

  final int forecastHorizonHours;

  final String Function(double) riskLabel;
  final String Function(double) riskPercent;
  final Color Function(double) riskBadgeColor;

  final List<AdvisoryItem> Function(double r) schoolAdvisories;

  final VoidCallback onZoomToSchool;
  final void Function(Street st) onZoomToStreet;

  const SchoolSheet({
    super.key,
    required this.school,
    required this.byId,
    required this.forecastHorizonHours,
    required this.riskLabel,
    required this.riskPercent,
    required this.riskBadgeColor,
    required this.schoolAdvisories,
    required this.onZoomToSchool,
    required this.onZoomToStreet,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = riskBadgeColor(school.risk);

    final nearestStreet = (school.nearestStreetOsmId != null)
        ? byId[school.nearestStreetOsmId!]
        : null;

    final items = schoolAdvisories(school.risk);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.58,
      minChildSize: 0.35,
      maxChildSize: 0.92,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      school.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RiskBadge(label: riskLabel(school.risk), color: badgeColor),
                ],
              ),
              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: school.risk.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.black.withOpacity(0.08),
                  color: badgeColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Risk: ${riskPercent(school.risk)}% (Forecast: $forecastHorizonHours hours)",
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              if (school.nearestStreetNameAr != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.route),
                  title: Text("Nearest street: ${school.nearestStreetNameAr}"),
                  subtitle: const Text("Tap to zoom to the street"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: nearestStreet == null
                      ? null
                      : () {
                          Navigator.pop(context);
                          onZoomToStreet(nearestStreet);
                        },
                ),
                const Divider(height: 1),
                const SizedBox(height: 10),
              ],

              Text(
                "School advisories",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withOpacity(0.80),
                ),
              ),
              const SizedBox(height: 8),
              AdvisorySection(items: items, accent: badgeColor),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onZoomToSchool();
                      },
                      icon: const Icon(Icons.my_location),
                      label: const Text("Zoom to school"),
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
}
