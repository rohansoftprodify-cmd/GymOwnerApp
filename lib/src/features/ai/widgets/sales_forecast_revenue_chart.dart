import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/ai/models/sales_forecast_result.dart';
import 'package:intl/intl.dart';

class SalesForecastRevenueChart extends StatelessWidget {
  const SalesForecastRevenueChart({
    super.key,
    required this.history,
    required this.forecast,
    this.height = 220,
    this.compact = false,
  });

  final List<MonthlyRevenueStat> history;
  final List<MonthlyForecastStat> forecast;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;
    final points = _buildPoints();

    if (points.isEmpty) {
      return Container(
        height: compact ? 100 : 160,
        alignment: Alignment.center,
        child: Text(
          'Not enough data for a chart yet.',
          style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
        ),
      );
    }

    final maxY = points.map((p) => p.value).fold<double>(0, (a, b) => a > b ? a : b);
    final chartMaxY = maxY <= 0 ? 1000.0 : maxY * 1.15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact) ...[
          Row(
            children: [
              _LegendDot(color: colorScheme.primary, label: 'Actual'),
              const SizedBox(width: 14),
              _LegendDot(
                color: colorScheme.secondary,
                label: 'Forecast',
                dashed: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              maxY: chartMaxY,
              minY: 0,
              gridData: FlGridData(
                show: !compact,
                drawVerticalLine: false,
                horizontalInterval: chartMaxY / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: !compact,
                    reservedSize: compact ? 0 : 44,
                    interval: chartMaxY / 4,
                    getTitlesWidget: (value, meta) {
                      if (value <= 0 || value > chartMaxY) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          _compactMoney(value),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: semantics.mutedText,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: compact ? 22 : 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          points[index].shortLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: compact ? 8 : 9,
                            fontWeight: points[index].isForecast
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: points[index].isForecast
                                ? colorScheme.secondary
                                : colorScheme.onSurface,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: !compact,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final point = points[group.x.toInt()];
                    return BarTooltipItem(
                      '${point.fullLabel}\n${_money(point.value)}',
                      TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: points[i].value,
                        width: compact ? 10 : 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                        color: points[i].isForecast
                            ? colorScheme.secondary.withValues(alpha: 0.75)
                            : colorScheme.primary,
                        backDrawRodData: points[i].isForecast
                            ? BackgroundBarChartRodData(
                                show: true,
                                toY: chartMaxY,
                                color: colorScheme.secondary.withValues(alpha: 0.06),
                              )
                            : BackgroundBarChartRodData(show: false),
                      ),
                    ],
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 350),
          ),
        ),
        if (!compact && points.any((p) => p.isForecast)) ...[
          const SizedBox(height: 8),
          Text(
            'Dashed-style bars show projected membership revenue.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: semantics.mutedText,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }

  static List<_ChartPoint> _buildPointsFrom(
    List<MonthlyRevenueStat> history,
    List<MonthlyForecastStat> forecast,
  ) {
    final sortedHistory = [...history]
      ..sort((a, b) => a.monthKey.compareTo(b.monthKey));
    final recentHistory = sortedHistory.length <= 6
        ? sortedHistory
        : sortedHistory.sublist(sortedHistory.length - 6);

    final points = <_ChartPoint>[
      for (final month in recentHistory)
        _ChartPoint(
          monthKey: month.monthKey,
          shortLabel: _shortMonthLabel(month.monthKey, month.monthLabel),
          fullLabel: month.monthLabel,
          value: month.membershipRevenue,
          isForecast: false,
        ),
    ];

    final sortedForecast = [...forecast]..sort((a, b) => a.monthKey.compareTo(b.monthKey));
    for (final month in sortedForecast) {
      points.add(
        _ChartPoint(
          monthKey: month.monthKey,
          shortLabel: _shortMonthLabel(month.monthKey, month.monthLabel),
          fullLabel: '${month.monthLabel} (forecast)',
          value: month.predictedMembershipRevenue,
          isForecast: true,
        ),
      );
    }

    return points;
  }

  List<_ChartPoint> _buildPoints() => _buildPointsFrom(history, forecast);

  static String _shortMonthLabel(String monthKey, String fallback) {
    final parsed = DateTime.tryParse('$monthKey-01');
    if (parsed != null) {
      return DateFormat('MMM').format(parsed);
    }
    if (fallback.length >= 3) return fallback.substring(0, 3);
    return fallback;
  }

  static String _money(double value) => '₹${NumberFormat('#,##0').format(value.round())}';

  static String _compactMoney(double value) {
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(0)}k';
    return '₹${value.round()}';
  }
}

class SalesForecastSparkline extends StatelessWidget {
  const SalesForecastSparkline({
    super.key,
    required this.history,
    required this.forecast,
  });

  final List<MonthlyRevenueStat> history;
  final List<MonthlyForecastStat> forecast;

  @override
  Widget build(BuildContext context) {
    return SalesForecastRevenueChart(
      history: history,
      forecast: forecast,
      height: 72,
      compact: true,
    );
  }
}

class _ChartPoint {
  const _ChartPoint({
    required this.monthKey,
    required this.shortLabel,
    required this.fullLabel,
    required this.value,
    required this.isForecast,
  });

  final String monthKey;
  final String shortLabel;
  final String fullLabel;
  final double value;
  final bool isForecast;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dashed ? color.withValues(alpha: 0.35) : color,
            borderRadius: BorderRadius.circular(3),
            border: dashed ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
