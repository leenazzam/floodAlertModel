import 'package:flutter/material.dart';

class AdvisoryItem {
  final String title;
  final List<String> lines;
  final IconData icon;
  final bool emphasis;

  const AdvisoryItem({
    required this.title,
    required this.lines,
    required this.icon,
    this.emphasis = false,
  });
}

class AdvisorySection extends StatelessWidget {
  final List<AdvisoryItem> items;
  final Color accent;

  const AdvisorySection({super.key, required this.items, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((it) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: it.emphasis
                ? accent.withOpacity(0.10)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: it.emphasis
                  ? accent.withOpacity(0.35)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                it.icon,
                color: it.emphasis ? accent : Colors.black.withOpacity(0.75),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: it.emphasis
                            ? accent
                            : Colors.black.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...it.lines.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: accent.withOpacity(0.85),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
