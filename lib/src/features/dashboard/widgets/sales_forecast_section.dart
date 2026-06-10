import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/ai/models/sales_forecast_result.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/section_header.dart';
import 'package:intl/intl.dart';

class SalesForecastSection extends StatelessWidget {
  const SalesForecastSection({
    super.key,
    required this.gymId,
    required this.result,
  });

  final String gymId;
  final SalesForecastResult result;

  String _money(double value) => '₹${NumberFormat('#,##0').format(value.round())}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final nextMonth = result.monthlyForecast.isNotEmpty ? result.monthlyForecast.first : null;

    return Column(
      children: [
        const SizedBox(height: 4),
        SectionHeader(
          title: 'Sales forecast',
          actionLabel: 'Full report',
          onAction: () => context.push('/sales-forecast?gymId=$gymId'),
        ),
        const SizedBox(height: 4),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/sales-forecast?gymId=$gymId'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.query_stats_rounded, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${result.forecastMonths}-month outlook',
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
                      if (nextMonth != null)
                        _MiniStat(
                          label: 'Next month',
                          value: _money(nextMonth.predictedMembershipRevenue),
                          color: theme.colorScheme.primary,
                        ),
                      _MiniStat(
                        label: 'Renewals (30d)',
                        value: '${result.renewals.next30Days.count}',
                        color: semantics.accentLime,
                        textColor: semantics.onAccentLime,
                      ),
                      _MiniStat(
                        label: 'Churn risk',
                        value: '${result.overview.projectedChurnRatePercent.toStringAsFixed(0)}%',
                        color: semantics.accentCoral,
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
  });

  final String label;
  final String value;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
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
