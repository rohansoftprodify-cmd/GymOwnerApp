import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';

Future<bool> showAddExerciseCategoryDialog(
  BuildContext context,
  WidgetRef ref, {
  required String gymId,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _AddExerciseCategoryDialog(gymId: gymId),
  );
  return result ?? false;
}

class _AddExerciseCategoryDialog extends ConsumerStatefulWidget {
  const _AddExerciseCategoryDialog({required this.gymId});

  final String gymId;

  @override
  ConsumerState<_AddExerciseCategoryDialog> createState() =>
      _AddExerciseCategoryDialogState();
}

class _AddExerciseCategoryDialogState extends ConsumerState<_AddExerciseCategoryDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add category'),
      content: AppTextField(
        controller: _nameController,
        label: 'Category name (e.g. Chest)',
        prefixIcon: const Icon(Icons.category_outlined, size: 18),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Could not add category',
      action: () => ref.read(gymRepositoryProvider).upsertExerciseCategory(
            gymId: widget.gymId,
            name: name,
          ),
    );
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }
}
