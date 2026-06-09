import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/ai/models/gym_analysis_result.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/section_header.dart';

class AiAnalysisSection extends StatelessWidget {
  const AiAnalysisSection({
    super.key,
    required this.gymId,
    required this.result,
  });

  final String gymId;
  final GymAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final topInsight = result.insights.isNotEmpty ? result.insights.first : result.summary;
    final preferred = result.attendance.preferredMethod?.label ?? '—';
    final topProduct = result.sales.topProducts.isNotEmpty
        ? result.sales.topProducts.first.name
        : 'No sales yet';

    return Column(
      children: [
        const SizedBox(height: 4),
        SectionHeader(
          title: 'AI Analysis',
          actionLabel: 'Full report',
          onAction: () => context.push('/ai-analysis?gymId=$gymId'),
        ),
        const SizedBox(height: 4),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/ai-analysis?gymId=$gymId'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Last ${result.periodMonths} months',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    topInsight,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniStat(
                        label: 'Joined',
                        value: '${result.membership.joinedInPeriod}',
                        color: theme.colorScheme.primary,
                      ),
                      _MiniStat(
                        label: 'Left',
                        value: '${result.membership.leftInPeriod}',
                        color: semantics.accentCoral,
                      ),
                      _MiniStat(
                        label: 'Top check-in',
                        value: preferred,
                        color: semantics.accentLime,
                        textColor: semantics.onAccentLime,
                        wide: true,
                      ),
                      _MiniStat(
                        label: 'Top product',
                        value: topProduct,
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
