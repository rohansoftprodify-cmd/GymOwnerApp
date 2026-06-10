import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/ai/models/attendance_analytics_result.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/section_header.dart';

class AttendanceAnalyticsSection extends StatelessWidget {
  const AttendanceAnalyticsSection({
    super.key,
    required this.gymId,
    required this.result,
  });

  final String gymId;
  final AttendanceAnalyticsResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final peak = result.peakHours.isNotEmpty ? result.peakHours.first : null;
    final quiet = result.quietHours.isNotEmpty ? result.quietHours.first : null;
    final floorPeak = result.equipmentPressure.peakOccupancyHour;

    return Column(
      children: [
        const SizedBox(height: 4),
        SectionHeader(
          title: 'AI Attendance',
          actionLabel: 'Full report',
          onAction: () => context.push('/attendance-analytics?gymId=$gymId'),
        ),
        const SizedBox(height: 4),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/attendance-analytics?gymId=$gymId'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.insights_rounded, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Last ${result.periodDays} days',
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    result.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (peak != null)
                        _MiniStat(
                          label: 'Peak hour',
                          value: peak.hourLabel,
                          color: theme.colorScheme.primary,
                        ),
                      if (quiet != null)
                        _MiniStat(
                          label: 'Quiet hour',
                          value: quiet.hourLabel,
                          color: semantics.accentLime,
                          textColor: semantics.onAccentLime,
                        ),
                      if (floorPeak != null && floorPeak.avgOnFloor > 0)
                        _MiniStat(
                          label: 'Floor load',
                          value: floorPeak.hourLabel,
                          color: theme.colorScheme.secondary,
                          wide: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    this.textColor,
    this.wide = false,
  });

  final String label;
  final String value;
  final Color color;
  final Color? textColor;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: textColor ?? color,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
