import 'package:floodalert/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../../models/street_model.dart';
import '../../../widgets/advisory_section.dart';
import '../../../widgets/info_tile.dart';
import '../../../widgets/risk_badge.dart';

class StreetSheet extends StatelessWidget {
  final Street street;
  final Map<int, Street> byId;

  final double riskThreshold;

  final String Function(double) riskLabel;
  final String Function(double) riskPercent;
  final Color Function(double) riskBadgeColor;

  final List<AdvisoryItem> Function(double r, Street st) municipalityAdvisories;

  final void Function(Street st) onZoomToStreet;
  final void Function(Street st) onZoomToAlt;

  List<AdvisoryItem> _municipalityAdvisories(double r, Street st) {
    if (r >= 0.75) {
      return const [
        AdvisoryItem(
          title: "إجراء فوري (Critical)",
          lines: [
            "إغلاق المقاطع الحرجة فوراً إذا بدأ تجمع المياه.",
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
            "مراقبة المناطق المنخفضة.",
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

  const StreetSheet({
    super.key,
    required this.street,
    required this.byId,
    required this.riskThreshold,
    required this.riskLabel,
    required this.riskPercent,
    required this.riskBadgeColor,
    required this.municipalityAdvisories,
    required this.onZoomToStreet,
    required this.onZoomToAlt,
  });

  @override
  Widget build(BuildContext context) {
    final showAlt = street.risk >= riskThreshold && street.alt != null;
    final altId = street.alt?.osmId;
    final altStreet = (altId == null) ? null : byId[altId];

    final badgeColor = riskBadgeColor(street.risk);
    final items = municipalityAdvisories(street.risk, street);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
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
                      street.nameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  RiskBadge(label: riskLabel(street.risk), color: badgeColor),
                ],
              ),
              const SizedBox(height: 10),

              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: street.risk.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.black.withOpacity(0.08),
                  color: badgeColor,
                ),
              ),
              const SizedBox(height: 8),
              Text("Risk: ${riskPercent(street.risk)}%"),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InfoTile(
                      title: "Slope",
                      value: street.slopePercent == null
                          ? "N/A"
                          : "${street.slopePercent!.toStringAsFixed(2)}%",
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InfoTile(
                      title: "Elevation",
                      value: street.elevationM == null
                          ? "N/A"
                          : "${street.elevationM!.toStringAsFixed(1)} m",
                      icon: Icons.terrain,
                    ),
                  ),
                ],
              ),

              if (showAlt) ...[
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Text(
                  "Alternative route",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withOpacity(0.80),
                  ),
                ),
                const SizedBox(height: 6),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alt_route, color: Colors.blue),
                  title: Text(street.alt!.nameAr),
                  subtitle: const Text("Tap to zoom to the dashed blue route"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context);
                    if (altStreet != null) {
                      onZoomToAlt(altStreet);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Alternative geometry not found."),
                        ),
                      );
                    }
                  },
                ),
              ],

              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),

              Text(
                "Municipality advisories",
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
                        onZoomToStreet(street);
                      },
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text("Zoom to street"),
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
