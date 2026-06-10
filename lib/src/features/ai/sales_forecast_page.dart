import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/ai/ai_repository.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/ai/models/sales_forecast_result.dart';
import 'package:intl/intl.dart';

class SalesForecastPage extends ConsumerStatefulWidget {
  const SalesForecastPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<SalesForecastPage> createState() => _SalesForecastPageState();
}

class _SalesForecastPageState extends ConsumerState<SalesForecastPage> {
  bool _loading = true;
  SalesForecastResult? _result;
  int _months = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(aiRepositoryProvider).getSalesForecast(
            widget.gymId,
            forecastMonths: _months,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Forecast failed', error: e);
    }
  }

  String _money(double value) => '₹${NumberFormat('#,##0').format(value.round())}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership Sales Forecast'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _months,
            onSelected: (v) {
              setState(() => _months = v);
              _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('1-month forecast')),
              PopupMenuItem(value: 3, child: Text('3-month forecast')),
              PopupMenuItem(value: 6, child: Text('6-month forecast')),
            ],
            icon: const Icon(Icons.date_range_outlined),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : result == null
              ? const Center(child: Text('No forecast available.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _SummaryCard(
                        summary: result.summary,
                        months: result.forecastMonths,
                        focus: result.staffingHints.marketingFocusLabel,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Overview',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Est. MRR',
                              value: _money(result.overview.estimatedMrr),
                              icon: Icons.payments_outlined,
                              color: theme.colorScheme.primary,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricTile(
                              label: 'Renewal rate',
                              value:
                                  '${result.overview.historicalRenewalRatePercent.toStringAsFixed(0)}%',
                              icon: Icons.autorenew_rounded,
                              color: semantics.accentLime,
                              valueColor: semantics.onAccentLime,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Projected churn',
                              value:
                                  '${result.overview.projectedChurnRatePercent.toStringAsFixed(1)}%',
                              icon: Icons.trending_down_rounded,
                              color: semantics.accentCoral,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricTile(
                              label: 'At-risk',
                              value: '${result.overview.atRiskMembers}',
                              icon: Icons.warning_amber_rounded,
                              color: Colors.orange.shade700,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Revenue forecast',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (result.monthlyForecast.isEmpty)
                        _EmptyNote(text: 'Add subscription history to generate forecasts.')
                      else
                        ...result.monthlyForecast.map(
                          (f) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                Icons.calendar_month_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              title: Text(
                                f.monthLabel,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'Renewals: ${_money(f.predictedRenewalRevenue)} · ${f.confidence} confidence',
                              ),
                              trailing: Text(
                                _money(f.predictedMembershipRevenue),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Renewals pipeline',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Due in 30 days',
                              value: '${result.renewals.next30Days.count}',
                              icon: Icons.event_available_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricTile(
                              label: 'Expected ₹',
                              value: _money(result.renewals.next30Days.expectedRevenue),
                              icon: Icons.savings_outlined,
                              color: theme.colorScheme.secondary,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoChip(
                        icon: Icons.info_outline_rounded,
                        text:
                            '60-day window: ${result.renewals.next60Days.count} renewals · expected ${_money(result.renewals.next60Days.expectedRevenue)} of ${_money(result.renewals.next60Days.fullPotentialRevenue)} potential',
                      ),
                      if (result.renewals.upcoming.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...result.renewals.upcoming.map(
                          (r) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(
                                r.fullName.isNotEmpty ? r.fullName[0].toUpperCase() : '?',
                              ),
                            ),
                            title: Text(r.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${r.planName} · ends ${r.endDate ?? '—'}'),
                            trailing: _LikelihoodBadge(level: r.renewalLikelihood),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Churn analysis',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Recent churn',
                              value:
                                  '${result.churn.recentChurnRatePercent.toStringAsFixed(1)}%',
                              icon: Icons.person_remove_alt_1_rounded,
                              color: semantics.accentCoral,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricTile(
                              label: 'Next month',
                              value:
                                  '${result.churn.projectedNextMonthPercent.toStringAsFixed(1)}%',
                              icon: Icons.insights_rounded,
                              color: theme.colorScheme.secondary,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _InfoChip(
                        icon: Icons.groups_rounded,
                        text:
                            '${result.churn.membersChurnedLast30Days} churned last 30 days · ${result.churn.expiredNotRenewed90d} expired without renewal (90d)',
                      ),
                      if (result.monthlyHistory.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Recent revenue history',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        ...result.monthlyHistory.reversed.take(6).map(
                          (m) => _BarRow(
                            label: m.monthLabel,
                            value: _money(m.membershipRevenue),
                            progress: _historyProgress(m.membershipRevenue, result.monthlyHistory),
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Planning insights',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      _InfoChip(
                        icon: Icons.campaign_outlined,
                        text:
                            'Marketing focus: ${result.staffingHints.marketingFocusLabel} · Priority: ${result.staffingHints.priority}',
                      ),
                      const SizedBox(height: 8),
                      ...result.insights.map(
                        (insight) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(insight, style: theme.textTheme.bodyMedium)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  double _historyProgress(double value, List<MonthlyRevenueStat> history) {
    final peak = history.map((h) => h.membershipRevenue).fold<double>(0, (a, b) => a > b ? a : b);
    if (peak <= 0) return 0;
    return (value / peak).clamp(0.0, 1.0);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.months,
    required this.focus,
  });

  final String summary;
  final int months;
  final String focus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.query_stats_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sales forecast · $months mo · $focus',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.valueColor,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color? valueColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: valueColor ?? color,
              fontSize: compact ? 15 : null,
            ),
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              Text(value, style: theme.textTheme.labelSmall),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _LikelihoodBadge extends StatelessWidget {
  const _LikelihoodBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'high' => Colors.green.shade700,
      'low' => context.appColors.accentCoral,
      _ => Colors.orange.shade700,
    };
    return Text(
      level.toUpperCase(),
      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: color),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.mutedText,
            ),
      ),
    );
  }
}
