import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/diet_models.dart';

const kDietMealLabels = [
  'Breakfast',
  'Morning Snack',
  'Lunch',
  'Evening Snack',
  'Dinner',
  'Pre-workout',
  'Post-workout',
];

Future<bool> showDietMealEditorSheet(
  BuildContext context,
  WidgetRef ref, {
  required String gymId,
  required String planId,
  DietMealItem? existing,
  required int sortOrder,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _DietMealEditorSheet(
      gymId: gymId,
      planId: planId,
      existing: existing,
      sortOrder: sortOrder,
    ),
  );
  return result ?? false;
}

class _DietMealEditorSheet extends ConsumerStatefulWidget {
  const _DietMealEditorSheet({
    required this.gymId,
    required this.planId,
    this.existing,
    required this.sortOrder,
  });

  final String gymId;
  final String planId;
  final DietMealItem? existing;
  final int sortOrder;

  @override
  ConsumerState<_DietMealEditorSheet> createState() => _DietMealEditorSheetState();
}

class _DietMealEditorSheetState extends ConsumerState<_DietMealEditorSheet> {
  late String _mealLabel;
  late final TextEditingController _timeController;
  late final TextEditingController _guidanceController;
  final List<_FoodRow> _foods = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _mealLabel = e?.mealLabel ?? kDietMealLabels.first;
    _timeController = TextEditingController(text: e?.mealTime ?? '');
    _guidanceController = TextEditingController(text: e?.guidance ?? '');
    if (e != null) {
      for (final f in e.foods) {
        _foods.add(_FoodRow.fromFood(f));
      }
    }
    if (_foods.isEmpty) _foods.add(_FoodRow.empty());
  }

  @override
  void dispose() {
    _timeController.dispose();
    _guidanceController.dispose();
    for (final f in _foods) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(gymRepositoryProvider);
    final validFoods = _foods.where((f) => f.nameController.text.trim().isNotEmpty).toList();
    if (validFoods.isEmpty) {
      await showAppErrorDialog(
        context,
        title: 'Add foods',
        error: 'Add at least one food item for this meal.',
      );
      return;
    }

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Save failed',
      action: () async {
        final mealRow = await repo.upsertDietMeal(
          gymId: widget.gymId,
          planId: widget.planId,
          id: widget.existing?.id,
          mealLabel: _mealLabel,
          mealTime: _timeController.text.trim().isEmpty ? null : _timeController.text.trim(),
          guidance: _guidanceController.text.trim().isEmpty ? null : _guidanceController.text.trim(),
          sortOrder: widget.sortOrder,
        );
        final mealId = mealRow['id'] as String;

        if (widget.existing != null) {
          for (final old in widget.existing!.foods) {
            if (old.id != null) {
              await repo.deleteDietFoodItem(gymId: widget.gymId, foodId: old.id!);
            }
          }
        }

        var order = 0;
        for (final f in validFoods) {
          await repo.upsertDietFoodItem(
            f.toFoodItem(sortOrder: order++).toRow(widget.gymId, mealId),
          );
        }
      },
    );

    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.existing == null ? 'Add meal' : 'Edit meal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: kDietMealLabels.contains(_mealLabel) ? _mealLabel : kDietMealLabels.first,
            decoration: const InputDecoration(labelText: 'Meal'),
            items: kDietMealLabels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
            onChanged: (v) => setState(() => _mealLabel = v ?? _mealLabel),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _timeController,
            label: 'Time (optional)',
            prefixIcon: const Icon(Icons.schedule_outlined, size: 18),
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _guidanceController,
            label: 'Meal notes (optional)',
            prefixIcon: const Icon(Icons.notes_outlined, size: 18),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Food items',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _foods.add(_FoodRow.empty())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add food', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _foods.length,
              itemBuilder: (_, i) => _FoodEditorCard(
                row: _foods[i],
                onRemove: _foods.length > 1 ? () => setState(() => _foods.removeAt(i)) : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _save, child: const Text('Save meal')),
        ],
      ),
    );
  }
}

class _FoodRow {
  _FoodRow({
    required this.nameController,
    required this.portionController,
    required this.caloriesController,
    required this.proteinController,
    required this.carbsController,
    required this.fatController,
  });

  final TextEditingController nameController;
  final TextEditingController portionController;
  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController carbsController;
  final TextEditingController fatController;

  factory _FoodRow.empty() => _FoodRow(
        nameController: TextEditingController(),
        portionController: TextEditingController(),
        caloriesController: TextEditingController(),
        proteinController: TextEditingController(),
        carbsController: TextEditingController(),
        fatController: TextEditingController(),
      );

  factory _FoodRow.fromFood(DietFoodItem f) => _FoodRow(
        nameController: TextEditingController(text: f.foodName),
        portionController: TextEditingController(text: f.portion ?? ''),
        caloriesController: TextEditingController(text: f.calories?.toString() ?? ''),
        proteinController: TextEditingController(text: f.proteinG?.toString() ?? ''),
        carbsController: TextEditingController(text: f.carbsG?.toString() ?? ''),
        fatController: TextEditingController(text: f.fatG?.toString() ?? ''),
      );

  void dispose() {
    nameController.dispose();
    portionController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
  }

  DietFoodItem toFoodItem({required int sortOrder}) {
    return DietFoodItem(
      foodName: nameController.text.trim(),
      portion: portionController.text.trim().isEmpty ? null : portionController.text.trim(),
      calories: int.tryParse(caloriesController.text.trim()),
      proteinG: double.tryParse(proteinController.text.trim()),
      carbsG: double.tryParse(carbsController.text.trim()),
      fatG: double.tryParse(fatController.text.trim()),
      sortOrder: sortOrder,
    );
  }
}

class _FoodEditorCard extends StatelessWidget {
  const _FoodEditorCard({required this.row, this.onRemove});

  final _FoodRow row;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: SizedBox()),
                if (onRemove != null)
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            AppTextField(
              controller: row.nameController,
              label: 'Food name',
              prefixIcon: const Icon(Icons.restaurant_outlined, size: 18),
            ),
            const SizedBox(height: 6),
            AppTextField(
              controller: row.portionController,
              label: 'Portion (e.g. 2 eggs, 150g rice)',
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: row.caloriesController,
                    label: 'Cal',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: AppTextField(
                    controller: row.proteinController,
                    label: 'P (g)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
