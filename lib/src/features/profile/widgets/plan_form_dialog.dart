import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/subscription_plan_item.dart';

Future<void> showPlanFormDialog(
  BuildContext context,
  WidgetRef ref, {
  required String gymId,
  SubscriptionPlanItem? existing,
  required VoidCallback onSaved,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _PlanFormDialog(
      gymId: gymId,
      existing: existing,
    ),
  );

  if (saved == true) {
    onSaved();
  }
}

class _PlanFormDialog extends ConsumerStatefulWidget {
  const _PlanFormDialog({
    required this.gymId,
    required this.existing,
  });

  final String gymId;
  final SubscriptionPlanItem? existing;

  @override
  ConsumerState<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends ConsumerState<_PlanFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late bool _isActive;
  late int _selectedDurationPreset;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _priceController = TextEditingController(
      text: existing != null ? existing.price.toStringAsFixed(0) : '',
    );
    _durationController = TextEditingController(
      text: '${existing?.durationDays ?? 30}',
    );
    _isActive = existing?.isActive ?? true;
    _selectedDurationPreset = _matchPreset(existing?.durationDays ?? 30);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final durationDays = int.tryParse(_durationController.text.trim());

    if (name.isEmpty) {
      await showAppErrorDialog(
        context,
        title: 'Missing name',
        error: 'Enter a plan name.',
      );
      return;
    }
    if (price == null || price < 0) {
      await showAppErrorDialog(
        context,
        title: 'Invalid price',
        error: 'Enter a valid price.',
      );
      return;
    }
    if (durationDays == null || durationDays <= 0) {
      await showAppErrorDialog(
        context,
        title: 'Invalid duration',
        error: 'Duration must be at least 1 day.',
      );
      return;
    }

    setState(() => _saving = true);
    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Could not save plan',
      action: () => ref.read(gymRepositoryProvider).upsertPlan(
            gymId: widget.gymId,
            id: widget.existing?.id,
            name: name,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            durationDays: durationDays,
            price: price,
            isActive: _isActive,
          ),
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;

    return AlertDialog(
      icon: const Icon(Icons.payments_rounded),
      title: Text(existing == null ? 'Add membership plan' : 'Edit plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Plan name',
              prefixIcon: const Icon(Icons.card_membership_outlined, size: 18),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
              prefixIcon: const Icon(Icons.notes_outlined, size: 18),
            ),
            const SizedBox(height: 10),
            AppTextField(
              controller: _priceController,
              label: 'Price',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Duration',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final preset in _durationPresets)
                  ChoiceChip(
                    label: Text(preset.label, style: const TextStyle(fontSize: 11)),
                    selected: _selectedDurationPreset == preset.days,
                    onSelected: (_) {
                      setState(() {
                        _selectedDurationPreset = preset.days;
                        _durationController.text = '${preset.days}';
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _durationController,
              label: 'Duration (days)',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) {
                final days = int.tryParse(v);
                if (days != null) {
                  setState(() => _selectedDurationPreset = _matchPreset(days));
                }
              },
            ),
            if (existing != null) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active plan', style: TextStyle(fontSize: 13)),
                subtitle: const Text(
                  'Inactive plans are hidden when adding members',
                  style: TextStyle(fontSize: 11),
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _DurationPreset {
  const _DurationPreset(this.label, this.days);
  final String label;
  final int days;
}

const _durationPresets = [
  _DurationPreset('1 month', 30),
  _DurationPreset('3 months', 90),
  _DurationPreset('6 months', 180),
  _DurationPreset('1 year', 365),
];

int _matchPreset(int days) {
  for (final preset in _durationPresets) {
    if (preset.days == days) return preset.days;
  }
  return -1;
}
