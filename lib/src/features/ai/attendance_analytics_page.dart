import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/ai/ai_repository.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/ai/models/attendance_analytics_result.dart';

class AttendanceAnalyticsPage extends ConsumerStatefulWidget {
  const AttendanceAnalyticsPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<AttendanceAnalyticsPage> createState() => _AttendanceAnalyticsPageState();
}

class _AttendanceAnalyticsPageState extends ConsumerState<AttendanceAnalyticsPage> {
  bool _loading = true;
  AttendanceAnalyticsResult? _result;
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(aiRepositoryProvider).getAttendanceAnalytics(
            widget.gymId,
            days: _days,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Analytics failed', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Attendance Analytics'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _days,
            onSelected: (v) {
              setState(() => _days = v);
              _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('Last 7 days')),
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
              PopupMenuItem(value: 60, child: Text('Last 60 days')),
              PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
            icon: const Icon(Icons.date_range_outlined),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : result == null
              ? const Center(child: Text('No analytics available.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _SummaryCard(
                        summary: result.summary,
                        days: result.periodDays,
                        timezone: result.timezone,
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
                              label: 'Check-ins',
                              value: '${result.overview.totalCheckIns}',
                              icon: Icons.login_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricTile(
                              label: 'Members',
                              value: '${result.overview.uniqueMembers}',
                              icon: Icons.people_alt_rounded,
                              color: semantics.accentLime,
                              valueColor: semantics.onAccentLime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Avg session',
                              value: '${result.overview.avgSessionMinutes} min',
                              icon: Icons.timer_outlined,
                              color: theme.colorScheme.secondary,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricTile(
                              label: 'Check-out rate',
                              value: '${result.overview.checkoutRatePercent.toStringAsFixed(0)}%',
                              icon: Icons.logout_rounded,
                              color: theme.colorScheme.primary,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle(title: 'Peak hours', icon: Icons.trending_up_rounded),
                      const SizedBox(height: 8),
                      if (result.peakHours.isEmpty)
                        _EmptyNote(text: 'Not enough check-ins to detect peak hours yet.')
                      else
                        ...result.peakHours.map(
                          (h) => _BarRow(
                            label: h.hourLabel,
                            value: '${h.checkIns} check-ins',
                            progress: h.percentOfPeak / 100,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      const SizedBox(height: 16),
                      _SectionTitle(title: 'Quiet hours', icon: Icons.nightlight_round),
                      const SizedBox(height: 8),
                      if (result.quietHours.isEmpty)
                        _EmptyNote(text: 'No quiet-hour pattern yet.')
                      else
                        ...result.quietHours.map(
                          (h) => _BarRow(
                            label: h.hourLabel,
                            value: '${h.checkIns} check-ins',
                            progress: h.percentOfPeak / 100,
                            color: semantics.accentLime,
                          ),
                        ),
                      const SizedBox(height: 16),
                      _SectionTitle(
                        title: 'Equipment pressure',
                        icon: Icons.fitness_center_rounded,
                        subtitle: result.equipmentPressure.note,
                      ),
                      const SizedBox(height: 8),
                      if (result.equipmentPressure.peakOccupancyHour != null &&
                          result.equipmentPressure.peakOccupancyHour!.avgOnFloor > 0)
                        _InfoChip(
                          icon: Icons.groups_rounded,
                          text:
                              'Busiest floor load: ${result.equipmentPressure.peakOccupancyHour!.hourLabel} '
                              '(~${result.equipmentPressure.peakOccupancyHour!.avgOnFloor.toStringAsFixed(1)} members on floor)',
                        ),
                      const SizedBox(height: 8),
                      if (result.equipmentPressure.byHour.isEmpty)
                        _EmptyNote(text: 'Need more session overlap data for floor-load estimates.')
                      else
                        ...result.equipmentPressure.byHour.map(
                          (h) => _BarRow(
                            label: h.hourLabel,
                            value: '~${h.avgOnFloor.toStringAsFixed(1)} on floor',
                            progress: h.pressurePercent / 100,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      if (result.equipmentPressure.sessionDurationBands.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Session length (completed check-outs)',
                          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        ...result.equipmentPressure.sessionDurationBands.map(
                          (band) => _BarRow(
                            label: band.label,
                            value: '${band.count} sessions',
                            progress: band.count /
                                result.equipmentPressure.sessionDurationBands
                                    .map((b) => b.count)
                                    .fold<int>(0, (a, b) => a + b)
                                    .clamp(1, 999999),
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _SectionTitle(title: 'Day of week', icon: Icons.calendar_view_week_rounded),
                      const SizedBox(height: 8),
                      if (result.dayOfWeek.isEmpty)
                        _EmptyNote(text: 'No day-of-week pattern yet.')
                      else
                        ...result.dayOfWeek.map(
                          (d) => _BarRow(
                            label: d.dayLabel,
                            value: '${d.checkIns} check-ins',
                            progress: d.percentOfPeak / 100,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      if (result.weekendVsWeekday.weekdayCheckIns > 0 ||
                          result.weekendVsWeekday.weekendCheckIns > 0) ...[
                        const SizedBox(height: 8),
                        _InfoChip(
                          icon: Icons.weekend_rounded,
                          text:
                              'Weekday ${result.weekendVsWeekday.weekdayCheckIns} · Weekend ${result.weekendVsWeekday.weekendCheckIns} check-ins',
                        ),
                      ],
                      if (result.checkInMethods.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _SectionTitle(title: 'Check-in methods', icon: Icons.how_to_reg_rounded),
                        const SizedBox(height: 8),
                        ...result.checkInMethods.map(
                          (m) => _BarRow(
                            label: m.label,
                            value: '${m.count} · ${m.percent.toStringAsFixed(0)}%',
                            progress: m.percent / 100,
                            color: theme.colorScheme.primary,
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
  const _SummaryCard({
    required this.summary,
    required this.days,
    required this.timezone,
  });

  final String summary;
  final int days;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary,
            theme.colorScheme.secondary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Attendance intelligence · $days d · $timezone',
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.appColors.mutedText,
              height: 1.35,
            ),
          ),
        ],
      ],
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
