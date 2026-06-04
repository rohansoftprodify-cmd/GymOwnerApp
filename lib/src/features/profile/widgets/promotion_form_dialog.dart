import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/promotion_item.dart';
import 'package:intl/intl.dart';

Future<void> showPromotionFormDialog(
  BuildContext context,
  WidgetRef ref, {
  required String gymId,
  PromotionItem? existing,
  required VoidCallback onSaved,
}) async {
  final navigator = Navigator.of(context);
  final titleController = TextEditingController(text: existing?.title ?? '');
  final descriptionController = TextEditingController(text: existing?.description ?? '');
  var startDate = existing?.startAt ?? DateTime.now();
  var endDate = existing?.endAt ?? DateTime.now().add(const Duration(days: 7));
  var isActive = existing?.isActive ?? true;

  Future<void> pickDate(
    BuildContext dialogContext,
    StateSetter setDialogState, {
    required bool isStart,
  }) async {
    final initial = isStart ? startDate : endDate;
    final picked = await showDatePicker(
      context: dialogContext,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setDialogState(() {
      if (isStart) {
        startDate = DateTime(picked.year, picked.month, picked.day);
        if (!endDate.isAfter(startDate)) {
          endDate = startDate.add(const Duration(days: 1));
        }
      } else {
        endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final dateFormat = DateFormat.yMMMd();
        return AlertDialog(
          icon: const Icon(Icons.local_offer_rounded),
          title: Text(existing == null ? 'Add exclusive offer' : 'Edit offer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: titleController,
                  label: 'Offer title',
                  prefixIcon: const Icon(Icons.title_rounded, size: 18),
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: descriptionController,
                  label: 'Description',
                  prefixIcon: const Icon(Icons.notes_outlined, size: 18),
                ),
                const SizedBox(height: 10),
                _DateRow(
                  label: 'Starts',
                  value: dateFormat.format(startDate),
                  onTap: () => pickDate(dialogContext, setDialogState, isStart: true),
                ),
                const SizedBox(height: 8),
                _DateRow(
                  label: 'Ends',
                  value: dateFormat.format(endDate),
                  onTap: () => pickDate(dialogContext, setDialogState, isStart: false),
                ),
                if (existing != null) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active offer', style: TextStyle(fontSize: 13)),
                    subtitle: const Text(
                      'Inactive offers are hidden on the home screen',
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
            TextButton(onPressed: () => navigator.pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final description = descriptionController.text.trim();
                if (title.isEmpty) {
                  await showAppErrorDialog(
                    dialogContext,
                    title: 'Missing title',
                    error: 'Enter an offer title.',
                  );
                  return;
                }
                if (description.isEmpty) {
                  await showAppErrorDialog(
                    dialogContext,
                    title: 'Missing description',
                    error: 'Enter a short description.',
                  );
                  return;
                }
                if (!endDate.isAfter(startDate)) {
                  await showAppErrorDialog(
                    dialogContext,
                    title: 'Invalid dates',
                    error: 'End date must be after start date.',
                  );
                  return;
                }

                final startUtc = DateTime.utc(startDate.year, startDate.month, startDate.day);
                final endUtc = DateTime.utc(
                  endDate.year,
                  endDate.month,
                  endDate.day,
                  23,
                  59,
                  59,
                );

                final ok = await runWithErrorDialog(
                  dialogContext,
                  errorTitle: 'Could not save offer',
                  action: () => ref.read(gymRepositoryProvider).upsertPromotion(
                        gymId: gymId,
                        id: existing?.id,
                        title: title,
                        description: description,
                        startAt: startUtc,
                        endAt: endUtc,
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

  titleController.dispose();
  descriptionController.dispose();
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.calendar_today_outlined, size: 16),
        ],
      ),
    );
  }
}
