import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/gym_day_hours.dart';

const _timezoneOptions = <String>[
  'Asia/Kolkata',
  'Asia/Dubai',
  'Asia/Singapore',
  'Europe/London',
  'America/New_York',
  'UTC',
];

class GymTimingPage extends ConsumerStatefulWidget {
  const GymTimingPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymTimingPage> createState() => _GymTimingPageState();
}

class _GymTimingPageState extends ConsumerState<GymTimingPage> {
  bool _loading = true;
  bool _saving = false;
  String? _timezone;
  List<GymDayHours> _days = GymDayHours.defaultWeek();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(gymRepositoryProvider);
      final gym = await repo.gymById(widget.gymId);
      final rows = await repo.operatingHours(widget.gymId);
      if (!mounted) return;

      final byDay = <int, GymDayHours>{
        for (final row in rows) row['day_of_week'] as int: GymDayHours.fromMap(row),
      };

      setState(() {
        _timezone = gym?['timezone'] as String? ?? 'Asia/Kolkata';
        _days = List.generate(
          7,
          (i) => byDay[i + 1] ?? GymDayHours.defaultsForDay(i + 1),
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    }
  }

  String? _validate() {
    for (final day in _days) {
      if (day.isClosed) continue;
      if (day.openTime == null || day.closeTime == null) {
        return 'Set open and close times for ${day.dayLabel}, or mark it closed.';
      }
      final openMins = day.openTime!.hour * 60 + day.openTime!.minute;
      final closeMins = day.closeTime!.hour * 60 + day.closeTime!.minute;
      if (closeMins <= openMins) {
        return 'Close time must be after open time on ${day.dayLabel}.';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final validation = _validate();
    if (validation != null) {
      await showAppErrorDialog(context, title: 'Invalid hours', error: validation);
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(gymRepositoryProvider);

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Save failed',
      action: () async {
        if (_timezone != null) {
          await repo.updateGymTimezone(gymId: widget.gymId, timezone: _timezone!);
        }
        await repo.saveOperatingHours(
          gymId: widget.gymId,
          rows: _days.map((d) => d.toUpsertRow(widget.gymId)).toList(),
        );
      },
    );

    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gym timing saved')),
        );
      }
    }
  }

  Future<void> _pickTime(GymDayHours day, {required bool isOpen}) async {
    final initial = isOpen ? day.openTime : day.closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? const TimeOfDay(hour: 6, minute: 0),
    );
    if (picked == null || !mounted) return;

    setState(() {
      final index = _days.indexWhere((d) => d.dayOfWeek == day.dayOfWeek);
      if (index < 0) return;
      _days[index] = day.copyWith(
        isClosed: false,
        openTime: isOpen ? picked : day.openTime,
        closeTime: isOpen ? day.closeTime : picked,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final timezoneChoices = _timezone != null && !_timezoneOptions.contains(_timezone)
        ? [_timezone!, ..._timezoneOptions]
        : _timezoneOptions;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: semantics.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: _timezone ?? timezoneChoices.first,
                  decoration: const InputDecoration(
                    labelText: 'Gym timezone',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.public_rounded, size: 20),
                  ),
                  items: timezoneChoices
                      .map((tz) => DropdownMenuItem(value: tz, child: Text(tz)))
                      .toList(),
                  onChanged: (v) => setState(() => _timezone = v),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hours use your gym timezone. Members see when you are open each day.',
                style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
              ),
              const SizedBox(height: 16),
              for (final day in _days) _DayHoursCard(
                day: day,
                onClosedChanged: (closed) {
                  setState(() {
                    final i = _days.indexWhere((d) => d.dayOfWeek == day.dayOfWeek);
                    if (i < 0) return;
                    if (closed) {
                      _days[i] = day.copyWith(isClosed: true, clearOpen: true, clearClose: true);
                    } else {
                      final defaults = GymDayHours.defaultsForDay(day.dayOfWeek);
                      _days[i] = day.copyWith(
                        isClosed: false,
                        openTime: day.openTime ?? defaults.openTime,
                        closeTime: day.closeTime ?? defaults.closeTime,
                      );
                    }
                  });
                },
                onPickOpen: () => _pickTime(day, isOpen: true),
                onPickClose: () => _pickTime(day, isOpen: false),
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save gym timing'),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayHoursCard extends StatelessWidget {
  const _DayHoursCard({
    required this.day,
    required this.onClosedChanged,
    required this.onPickOpen,
    required this.onPickClose,
  });

  final GymDayHours day;
  final ValueChanged<bool> onClosedChanged;
  final VoidCallback onPickOpen;
  final VoidCallback onPickClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day.dayLabel,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                'Closed',
                style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
              ),
              const SizedBox(width: 6),
              Switch.adaptive(
                value: day.isClosed,
                onChanged: onClosedChanged,
                activeColor: colorScheme.primary,
              ),
            ],
          ),
          if (day.isClosed)
            Text(
              'Closed all day',
              style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
            )
          else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _TimeChip(
                    label: 'Opens',
                    value: day.openTime == null
                        ? 'Set time'
                        : GymDayHours.formatTime(day.openTime!),
                    onTap: onPickOpen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeChip(
                    label: 'Closes',
                    value: day.closeTime == null
                        ? 'Set time'
                        : GymDayHours.formatTime(day.closeTime!),
                    onTap: onPickClose,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: Alignment.centerLeft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
