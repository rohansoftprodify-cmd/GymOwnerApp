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
  final navigator = Navigator.of(context);
  final nameController = TextEditingController(text: existing?.name ?? '');
  final descriptionController = TextEditingController(text: existing?.description ?? '');
  final priceController = TextEditingController(
    text: existing != null ? existing.price.toStringAsFixed(0) : '',
  );
  final durationController = TextEditingController(
    text: '${existing?.durationDays ?? 30}',
  );
  var isActive = existing?.isActive ?? true;
  var selectedDurationPreset = _matchPreset(existing?.durationDays ?? 30);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
          icon: const Icon(Icons.payments_rounded),
          title: Text(existing == null ? 'Add membership plan' : 'Edit plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: nameController,
                  label: 'Plan name',
                  prefixIcon: const Icon(Icons.card_membership_outlined, size: 18),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: descriptionController,
                  label: 'Description (optional)',
                  prefixIcon: const Icon(Icons.notes_outlined, size: 18),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: priceController,
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
                    style: Theme.of(dialogContext).textTheme.labelMedium,
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
                        selected: selectedDurationPreset == preset.days,
                        onSelected: (_) {
                          setDialogState(() {
                            selectedDurationPreset = preset.days;
                            durationController.text = '${preset.days}';
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: durationController,
                  label: 'Duration (days)',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    final days = int.tryParse(v);
                    if (days != null) {
                      setDialogState(() => selectedDurationPreset = _matchPreset(days));
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
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim());
                final durationDays = int.tryParse(durationController.text.trim());

                if (name.isEmpty) {
                  await showAppErrorDialog(
                    dialogContext,
                    title: 'Missing name',
                    error: 'Enter a plan name.',
                  );
                  return;
                }
                if (price == null || price < 0) {
                  await showAppErrorDialog(
                    dialogContext,
                    title: 'Invalid price',
                    error: 'Enter a valid price.',
                  );
                  return;
                }
                if (durationDays == null || durationDays <= 0) {
                  await showAppErrorDialog(
                    dialogContext,
                    title: 'Invalid duration',
                    error: 'Duration must be at least 1 day.',
                  );
                  return;
                }

                final ok = await runWithErrorDialog(
                  dialogContext,
                  errorTitle: 'Could not save plan',
                  action: () => ref.read(gymRepositoryProvider).upsertPlan(
                        gymId: gymId,
                        id: existing?.id,
                        name: name,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                        durationDays: durationDays,
                        price: price,
                        isActive: isActive,
                      ),
                );
                if (!dialogContext.mounted) return;
                if (ok) {
                  navigator.pop();
                  onSaved();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );

  nameController.dispose();
  descriptionController.dispose();
  priceController.dispose();
  durationController.dispose();
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
