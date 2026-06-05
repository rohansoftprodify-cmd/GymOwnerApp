import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/auth/single_session_provider.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/tenant/gym_setup_provider.dart';
import 'package:gym_owner_app/src/core/tenant/tenant_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/gym_day_hours.dart';
import 'package:gym_owner_app/src/features/profile/models/subscription_plan_item.dart';

class GymOwnerSetupPage extends ConsumerStatefulWidget {
  const GymOwnerSetupPage({super.key});

  @override
  ConsumerState<GymOwnerSetupPage> createState() => _GymOwnerSetupPageState();
}

class _GymOwnerSetupPageState extends ConsumerState<GymOwnerSetupPage> {
  final _pageController = PageController();
  final _gymPhoneController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _planNameController = TextEditingController();
  final _planPriceController = TextEditingController();
  final _planDurationController = TextEditingController(text: '30');

  int _step = 0;
  bool _loading = true;
  bool _busy = false;
  String? _gymId;
  String _gymName = '';
  String? _gymAddress;
  String? _gymEmail;
  String _currencyCode = 'INR';
  String? _timezone;
  List<GymDayHours> _days = GymDayHours.defaultWeek();
  String? _existingPlanId;
  int _planDurationPreset = 30;

  static const _stepTitles = [
    'Welcome',
    'Gym contact',
    'Operating hours',
    'Membership plan',
  ];

  static const _currencyOptions = ['INR', 'USD', 'EUR', 'GBP'];
  static const _planDurationPresets = [
    (label: '1 month', days: 30),
    (label: '3 months', days: 90),
    (label: '6 months', days: 180),
    (label: '1 year', days: 365),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _gymPhoneController.dispose();
    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _planNameController.dispose();
    _planPriceController.dispose();
    _planDurationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final setupRequired = await ref.read(gymOwnerSetupRequiredProvider.future);
    if (!setupRequired) {
      if (mounted) context.go('/');
      return;
    }

    final tenant = await ref.read(tenantContextProvider.future);
    if (tenant == null) {
      if (mounted) context.go('/login');
      return;
    }

    final repo = ref.read(gymRepositoryProvider);
    final gym = await repo.gymById(tenant.gymId);
    final profile = await repo.currentUserProfile();
    final hours = await repo.operatingHours(tenant.gymId);
    final plans = await repo.plans(tenant.gymId);

    if (!mounted) return;

    final byDay = <int, GymDayHours>{
      for (final row in hours) row['day_of_week'] as int: GymDayHours.fromMap(row),
    };
    final activePlan = plans.cast<Map<String, dynamic>>().where((p) => p['is_active'] == true).firstOrNull;

    setState(() {
      _gymId = tenant.gymId;
      _gymName = gym?['name'] as String? ?? tenant.gymName;
      _gymAddress = gym?['address'] as String?;
      _gymEmail = gym?['email'] as String?;
      _gymPhoneController.text = gym?['phone'] as String? ?? '';
      _currencyCode = gym?['currency_code'] as String? ?? 'INR';
      _timezone = gym?['timezone'] as String? ?? 'Asia/Kolkata';
      _ownerNameController.text = profile?['full_name'] as String? ?? '';
      _ownerPhoneController.text = profile?['phone'] as String? ?? '';
      _days = List.generate(7, (i) => byDay[i + 1] ?? GymDayHours.defaultsForDay(i + 1));
      if (activePlan != null) {
        _existingPlanId = activePlan['id'] as String?;
        _planNameController.text = activePlan['name'] as String? ?? '';
        _planPriceController.text = ((activePlan['price'] as num?) ?? 0).toStringAsFixed(0);
        _planDurationController.text = '${activePlan['duration_days'] ?? 30}';
        _planDurationPreset = activePlan['duration_days'] as int? ?? 30;
      }
      _loading = false;
    });
  }

  void _goToStep(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  String? _validateContactStep() {
    if (_gymPhoneController.text.trim().isEmpty) {
      return 'Enter a gym phone number members can reach.';
    }
    if (_ownerNameController.text.trim().isEmpty) {
      return 'Enter your name as the gym owner.';
    }
    return null;
  }

  String? _validateHoursStep() {
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

  String? _validatePlanStep() {
    if (_planNameController.text.trim().isEmpty) {
      return 'Add at least one membership plan name.';
    }
    final price = double.tryParse(_planPriceController.text.trim());
    if (price == null || price < 0) return 'Enter a valid plan price.';
    final days = int.tryParse(_planDurationController.text.trim());
    if (days == null || days <= 0) return 'Plan duration must be at least 1 day.';
    return null;
  }

  Future<void> _saveContactStep() async {
    final repo = ref.read(gymRepositoryProvider);
    await repo.updateGymForSetup(
      gymId: _gymId!,
      phone: _gymPhoneController.text.trim(),
      currencyCode: _currencyCode,
    );
    await repo.updateOwnerProfile(
      fullName: _ownerNameController.text.trim(),
      phone: _ownerPhoneController.text.trim().isEmpty
          ? null
          : _ownerPhoneController.text.trim(),
    );
  }

  Future<void> _saveHoursStep() async {
    final repo = ref.read(gymRepositoryProvider);
    if (_timezone != null) {
      await repo.updateGymTimezone(gymId: _gymId!, timezone: _timezone!);
    }
    await repo.saveOperatingHours(
      gymId: _gymId!,
      rows: _days.map((d) => d.toUpsertRow(_gymId!)).toList(),
    );
  }

  Future<void> _savePlanAndFinish() async {
    final repo = ref.read(gymRepositoryProvider);
    final durationDays = int.parse(_planDurationController.text.trim());
    final price = double.parse(_planPriceController.text.trim());

    await repo.upsertPlan(
      gymId: _gymId!,
      id: _existingPlanId,
      name: _planNameController.text.trim(),
      durationDays: durationDays,
      price: price,
      isActive: true,
    );
    await repo.completeGymSetup(_gymId!);
    ref.invalidate(gymOwnerSetupRequiredProvider);
    ref.invalidate(tenantContextProvider);
  }

  Future<void> _onNext() async {
    if (_gymId == null) return;

    if (_step == 1) {
      final error = _validateContactStep();
      if (error != null) {
        await showAppErrorDialog(context, title: 'Check details', error: error);
        return;
      }
      setState(() => _busy = true);
      final ok = await runWithErrorDialog(
        context,
        errorTitle: 'Save failed',
        action: _saveContactStep,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (!ok) return;
    }

    if (_step == 2) {
      final error = _validateHoursStep();
      if (error != null) {
        await showAppErrorDialog(context, title: 'Invalid hours', error: error);
        return;
      }
      setState(() => _busy = true);
      final ok = await runWithErrorDialog(
        context,
        errorTitle: 'Save failed',
        action: _saveHoursStep,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (!ok) return;
    }

    if (_step < _stepTitles.length - 1) {
      _goToStep(_step + 1);
    }
  }

  Future<void> _onFinish() async {
    final error = _validatePlanStep();
    if (error != null) {
      await showAppErrorDialog(context, title: 'Check plan', error: error);
      return;
    }

    setState(() => _busy = true);
    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Setup failed',
      action: _savePlanAndFinish,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.go('/');
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
    final semantics = context.appColors;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isLast = _step == _stepTitles.length - 1;
    final progress = (_step + 1) / _stepTitles.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your gym'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    await ref.read(singleSessionServiceProvider).signOutLocally();
                    if (context.mounted) context.go('/login');
                  },
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${_step + 1} of ${_stepTitles.length} · ${_stepTitles[_step]}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: semantics.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: progress, minHeight: 6),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _WelcomeStep(
                  gymName: _gymName,
                  address: _gymAddress,
                  email: _gymEmail,
                ),
                _ContactStep(
                  gymName: _gymName,
                  address: _gymAddress,
                  gymPhoneController: _gymPhoneController,
                  ownerNameController: _ownerNameController,
                  ownerPhoneController: _ownerPhoneController,
                  currencyCode: _currencyCode,
                  onCurrencyChanged: (v) => setState(() => _currencyCode = v),
                ),
                _HoursStep(
                  timezone: _timezone,
                  days: _days,
                  onTimezoneChanged: (v) => setState(() => _timezone = v),
                  onDayChanged: (day) {
                    setState(() {
                      final i = _days.indexWhere((d) => d.dayOfWeek == day.dayOfWeek);
                      if (i >= 0) _days[i] = day;
                    });
                  },
                  onPickOpen: (day) => _pickTime(day, isOpen: true),
                  onPickClose: (day) => _pickTime(day, isOpen: false),
                ),
                _PlanStep(
                  currencyCode: _currencyCode,
                  planNameController: _planNameController,
                  planPriceController: _planPriceController,
                  planDurationController: _planDurationController,
                  durationPreset: _planDurationPreset,
                  onPresetSelected: (days) {
                    setState(() {
                      _planDurationPreset = days;
                      _planDurationController.text = '$days';
                    });
                  },
                ),
              ],
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (_step > 0)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _goToStep(_step - 1),
                    child: const Text('Back'),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy
                        ? null
                        : isLast
                            ? _onFinish
                            : _onNext,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLast ? 'Finish & open dashboard' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    required this.gymName,
    this.address,
    this.email,
  });

  final String gymName;
  final String? address;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Icon(Icons.storefront_rounded, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Welcome, $gymName',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text(
          'Your admin account is ready. Next we will collect gym contact details, '
          'opening hours, and membership plans before you use the dashboard.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: semantics.mutedText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _InfoTile(label: 'Gym name', value: gymName),
        if (address != null && address!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _InfoTile(label: 'Address (from admin)', value: address!),
        ],
        if (email != null && email!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _InfoTile(label: 'Login email', value: email!),
        ],
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText)),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ContactStep extends StatelessWidget {
  const _ContactStep({
    required this.gymName,
    this.address,
    required this.gymPhoneController,
    required this.ownerNameController,
    required this.ownerPhoneController,
    required this.currencyCode,
    required this.onCurrencyChanged,
  });

  final String gymName;
  final String? address;
  final TextEditingController gymPhoneController;
  final TextEditingController ownerNameController;
  final TextEditingController ownerPhoneController;
  final String currencyCode;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Gym contact',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Name and address were set when your account was created. Add how members can reach you.',
          style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
        ),
        if (address != null && address!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _InfoTile(label: gymName, value: address!),
        ],
        const SizedBox(height: 16),
        AppTextField(
          controller: gymPhoneController,
          label: 'Gym phone',
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.call_outlined, size: 18),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: ownerNameController,
          label: 'Your name (owner)',
          prefixIcon: const Icon(Icons.person_outline, size: 18),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: ownerPhoneController,
          label: 'Your phone (optional)',
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_android_outlined, size: 18),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: currencyCode,
          decoration: const InputDecoration(labelText: 'Currency for fees'),
          items: _GymOwnerSetupPageState._currencyOptions
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            if (v != null) onCurrencyChanged(v);
          },
        ),
      ],
    );
  }
}

class _HoursStep extends StatelessWidget {
  const _HoursStep({
    required this.timezone,
    required this.days,
    required this.onTimezoneChanged,
    required this.onDayChanged,
    required this.onPickOpen,
    required this.onPickClose,
  });

  final String? timezone;
  final List<GymDayHours> days;
  final ValueChanged<String?> onTimezoneChanged;
  final ValueChanged<GymDayHours> onDayChanged;
  final void Function(GymDayHours day) onPickOpen;
  final void Function(GymDayHours day) onPickClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;

    final timezoneChoices = timezone != null && !_gymTimingTimezoneOptions.contains(timezone)
        ? [timezone!, ..._gymTimingTimezoneOptions]
        : _gymTimingTimezoneOptions;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'When is your gym open?',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: timezone ?? timezoneChoices.first,
          decoration: const InputDecoration(labelText: 'Timezone'),
          items: timezoneChoices.map((tz) => DropdownMenuItem(value: tz, child: Text(tz))).toList(),
          onChanged: onTimezoneChanged,
        ),
        const SizedBox(height: 8),
        Text(
          'Set hours for each day. You can change these later under Gym Profile.',
          style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
        ),
        const SizedBox(height: 12),
        for (final day in days)
          _SetupDayCard(
            day: day,
            onClosedChanged: (closed) {
              if (closed) {
                onDayChanged(day.copyWith(isClosed: true, clearOpen: true, clearClose: true));
              } else {
                final defaults = GymDayHours.defaultsForDay(day.dayOfWeek);
                onDayChanged(
                  day.copyWith(
                    isClosed: false,
                    openTime: day.openTime ?? defaults.openTime,
                    closeTime: day.closeTime ?? defaults.closeTime,
                  ),
                );
              }
            },
            onPickOpen: () => onPickOpen(day),
            onPickClose: () => onPickClose(day),
          ),
      ],
    );
  }
}

// Reuse timezone list from gym timing without importing private symbols.
const _gymTimingTimezoneOptions = <String>[
  'Asia/Kolkata',
  'Asia/Dubai',
  'Asia/Singapore',
  'Europe/London',
  'America/New_York',
  'UTC',
];

class _SetupDayCard extends StatelessWidget {
  const _SetupDayCard({
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
    final semantics = context.appColors;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(day.dayLabel, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Switch(
                value: !day.isClosed,
                onChanged: (open) => onClosedChanged(!open),
              ),
            ],
          ),
          if (!day.isClosed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPickOpen,
                    child: Text('Open ${day.openTime != null ? GymDayHours.formatTime(day.openTime!) : 'Set'}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onPickClose,
                    child: Text('Close ${day.closeTime != null ? GymDayHours.formatTime(day.closeTime!) : 'Set'}'),
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

class _PlanStep extends StatelessWidget {
  const _PlanStep({
    required this.currencyCode,
    required this.planNameController,
    required this.planPriceController,
    required this.planDurationController,
    required this.durationPreset,
    required this.onPresetSelected,
  });

  final String currencyCode;
  final TextEditingController planNameController;
  final TextEditingController planPriceController;
  final TextEditingController planDurationController;
  final int durationPreset;
  final ValueChanged<int> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final symbol = currencySymbol(currencyCode);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'First membership plan',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'You can add more plans later under Gym Profile → Fee structure.',
          style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: planNameController,
          label: 'Plan name',
          prefixIcon: const Icon(Icons.card_membership_outlined, size: 18),
        ),
        const SizedBox(height: 12),
        AppTextField(
          controller: planPriceController,
          label: 'Price ($symbol)',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final preset in _GymOwnerSetupPageState._planDurationPresets)
              ChoiceChip(
                label: Text(preset.label),
                selected: durationPreset == preset.days,
                onSelected: (_) => onPresetSelected(preset.days),
              ),
          ],
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: planDurationController,
          label: 'Duration (days)',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }
}
