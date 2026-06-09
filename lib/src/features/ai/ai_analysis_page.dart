import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/ai/ai_repository.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/ai/models/gym_analysis_result.dart';
import 'package:intl/intl.dart';

class AiAnalysisPage extends ConsumerStatefulWidget {
  const AiAnalysisPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends ConsumerState<AiAnalysisPage> {
  bool _loading = true;
  GymAnalysisResult? _result;
  int _months = 12;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(aiRepositoryProvider).getGymAnalysis(
            widget.gymId,
            months: _months,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Analysis failed', error: e);
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
        title: const Text('AI Analysis'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _months,
            onSelected: (v) {
              setState(() => _months = v);
              _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 6, child: Text('Last 6 months')),
              PopupMenuItem(value: 12, child: Text('Last 12 months')),
              PopupMenuItem(value: 24, child: Text('Last 24 months')),
            ],
            icon: const Icon(Icons.date_range_outlined),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : result == null
              ? const Center(child: Text('No analysis available.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _SummaryCard(summary: result.summary, months: result.periodMonths),
                      const SizedBox(height: 16),
                      Text(
                        'Membership',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Joined',
                              value: '${result.membership.joinedInPeriod}',
                              icon: Icons.person_add_alt_1_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricTile(
                              label: 'Left',
                              value: '${result.membership.leftInPeriod}',
                              icon: Icons.person_remove_alt_1_rounded,
                              color: semantics.accentCoral,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricTile(
                              label: 'Active',
                              value: '${result.membership.activeNow}',
                              icon: Icons.people_alt_rounded,
                              color: semantics.accentLime,
                              valueColor: semantics.onAccentLime,
                            ),
                          ),
                        ],
                      ),
                      if (result.membership.peakJoinMonth?.monthLabel != null) ...[
                        const SizedBox(height: 8),
                        _InfoChip(
                          icon: Icons.trending_up_rounded,
                          text:
                              'Peak join month: ${result.membership.peakJoinMonth!.monthLabel} (${result.membership.peakJoinMonth!.joinedCount} joins)',
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Store & sales',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Revenue',
                              value: _money(result.sales.totalRevenue),
                              icon: Icons.payments_outlined,
                              color: theme.colorScheme.primary,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricTile(
                              label: 'Orders',
                              value: '${result.sales.totalOrders}',
                              icon: Icons.receipt_long_outlined,
                              color: theme.colorScheme.secondary,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      if (result.sales.peakSalesMonth?.monthLabel != null) ...[
                        const SizedBox(height: 8),
                        _InfoChip(
                          icon: Icons.calendar_month_outlined,
                          text:
                              'Highest sales month: ${result.sales.peakSalesMonth!.monthLabel} (${_money(result.sales.peakSalesMonth!.salesTotal)})',
                        ),
                      ],
                      if (result.sales.topProducts.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...result.sales.topProducts.map(
                          (p) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('${p.qtySold} sold'),
                              trailing: Text(
                                _money(p.revenue),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Attendance methods',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (result.attendance.preferredMethod != null)
                        _InfoChip(
                          icon: Icons.how_to_reg_rounded,
                          text:
                              'Most used: ${result.attendance.preferredMethod!.label} (${result.attendance.preferredMethod!.percent.toStringAsFixed(0)}%)',
                        ),
                      const SizedBox(height: 8),
                      ...result.attendance.methods.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(m.label)),
                                  Text('${m.count} · ${m.percent.toStringAsFixed(0)}%'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: (m.percent / 100).clamp(0.0, 1.0),
                                borderRadius: BorderRadius.circular(4),
                                minHeight: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (result.attendance.peakMonth?.monthLabel != null) ...[
                        const SizedBox(height: 4),
                        _InfoChip(
                          icon: Icons.directions_run_rounded,
                          text:
                              'Busiest attendance month: ${result.attendance.peakMonth!.monthLabel} (${result.attendance.peakMonth!.checkIns} check-ins)',
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'Member highlights',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      if (result.members.oldestMember != null)
                        _InfoChip(
                          icon: Icons.emoji_events_outlined,
                          text:
                              'Longest-standing: ${result.members.oldestMember!.fullName} (${result.members.oldestMember!.daysAsMember} days)',
                        ),
                      if (result.members.mostConsistent.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...result.members.mostConsistent.map(
                          (m) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(
                                m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : '?',
                              ),
                            ),
                            title: Text(m.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(m.note ?? '${m.checkInCount} visits'),
                            trailing: const Icon(Icons.verified_outlined, size: 18),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'AI insights',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.months});

  final String summary;
  final int months;

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
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Gym intelligence · $months mo',
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
