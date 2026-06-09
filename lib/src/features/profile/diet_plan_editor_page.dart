import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/diet_goal_info.dart';
import 'package:gym_owner_app/src/features/profile/models/diet_models.dart';
import 'package:gym_owner_app/src/features/profile/widgets/ai_generate_diet_dialog.dart';
import 'package:gym_owner_app/src/features/profile/widgets/diet_goal_guide_card.dart';
import 'package:gym_owner_app/src/features/profile/widgets/diet_meal_editor_sheet.dart';
import 'package:image_picker/image_picker.dart';

class DietPlanEditorPage extends ConsumerStatefulWidget {
  const DietPlanEditorPage({
    super.key,
    required this.gymId,
    this.planId,
    required this.categories,
  });

  final String gymId;
  final String? planId;
  final List<DietCategoryItem> categories;

  @override
  ConsumerState<DietPlanEditorPage> createState() => _DietPlanEditorPageState();
}

class _DietPlanEditorPageState extends ConsumerState<DietPlanEditorPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _hydrationController = TextEditingController(text: '3');
  final _durationController = TextEditingController(text: '7');

  String? _categoryId;
  String? _savedPlanId;
  Uint8List? _imageBytes;
  String? _imageUrl;
  bool _isActive = true;
  bool _loading = true;
  bool _saving = false;
  bool _generatingAi = false;
  List<DietMealItem> _meals = [];

  bool get _planPersisted => _savedPlanId != null;

  @override
  void initState() {
    super.initState();
    _savedPlanId = widget.planId;
    if (widget.categories.isNotEmpty) {
      _categoryId = widget.categories.first.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _hydrationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  DietGoalInfo? get _selectedGoal {
    final cat = widget.categories.where((c) => c.id == _categoryId).firstOrNull;
    return cat?.goalInfo;
  }

  Future<void> _load() async {
    if (widget.planId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final repo = ref.read(gymRepositoryProvider);
      final plans = await repo.dietPlans(widget.gymId);
      final plan = plans.where((p) => p['id'] == widget.planId).firstOrNull;
      if (plan == null) throw Exception('Plan not found');

      final meals = await repo.dietMeals(widget.gymId, widget.planId!);
      if (!mounted) return;

      setState(() {
        _nameController.text = plan['name'] as String? ?? '';
        _descriptionController.text = plan['description'] as String? ?? '';
        _caloriesController.text = '${plan['target_calories'] ?? ''}';
        _proteinController.text = '${plan['target_protein_g'] ?? ''}';
        _carbsController.text = '${plan['target_carbs_g'] ?? ''}';
        _fatController.text = '${plan['target_fat_g'] ?? ''}';
        _hydrationController.text = '${plan['hydration_liters'] ?? 3}';
        _durationController.text = '${plan['duration_days'] ?? 7}';
        _categoryId = plan['category_id'] as String?;
        _imageUrl = repo.dietImageUrl(plan['image_path'] as String?);
        _isActive = plan['is_active'] as bool? ?? true;
        _meals = meals.map(DietMealItem.fromMap).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: e);
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageUrl = null;
    });
  }

  Future<void> _savePlan() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _categoryId == null) {
      await showAppErrorDialog(context, title: 'Missing fields', error: 'Name and goal are required.');
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(gymRepositoryProvider);

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Save failed',
      action: () async {
        final row = await repo.upsertDietPlan(
          gymId: widget.gymId,
          id: _savedPlanId,
          categoryId: _categoryId!,
          name: name,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          targetCalories: int.tryParse(_caloriesController.text.trim()),
          targetProteinG: double.tryParse(_proteinController.text.trim()),
          targetCarbsG: double.tryParse(_carbsController.text.trim()),
          targetFatG: double.tryParse(_fatController.text.trim()),
          hydrationLiters: double.tryParse(_hydrationController.text.trim()),
          durationDays: int.tryParse(_durationController.text.trim()) ?? 7,
          isActive: _isActive,
        );
        final planId = row['id'] as String;

        if (_imageBytes != null) {
          final path = await repo.uploadDietImage(
            gymId: widget.gymId,
            planId: planId,
            bytes: _imageBytes!,
          );
          await repo.upsertDietPlan(
            gymId: widget.gymId,
            id: planId,
            categoryId: _categoryId!,
            name: name,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            imagePath: path,
            targetCalories: int.tryParse(_caloriesController.text.trim()),
            targetProteinG: double.tryParse(_proteinController.text.trim()),
            targetCarbsG: double.tryParse(_carbsController.text.trim()),
            targetFatG: double.tryParse(_fatController.text.trim()),
            hydrationLiters: double.tryParse(_hydrationController.text.trim()),
            durationDays: int.tryParse(_durationController.text.trim()) ?? 7,
            isActive: _isActive,
          );
        }

        _savedPlanId = planId;
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      final hadUnsavedMeals = _meals.any((m) => m.id == null);
      if (hadUnsavedMeals) {
        await _persistAiMeals();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan saved — you can add meals below')),
        );
      }
    }
  }

  Future<void> _persistAiMeals() async {
    if (_savedPlanId == null) return;
    final repo = ref.read(gymRepositoryProvider);
    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Save meals failed',
      action: () async {
        var sortOrder = _meals.where((m) => m.id != null).length;
        for (final meal in _meals) {
          if (meal.id != null) continue;
          final mealRow = await repo.upsertDietMeal(
            gymId: widget.gymId,
            planId: _savedPlanId!,
            mealLabel: meal.mealLabel,
            mealTime: meal.mealTime,
            guidance: meal.guidance,
            sortOrder: sortOrder++,
          );
          final mealId = mealRow['id'] as String;
          var foodOrder = 0;
          for (final food in meal.foods) {
            await repo.upsertDietFoodItem(
              food.toRow(widget.gymId, mealId)..['sort_order'] = foodOrder++,
            );
          }
        }
      },
    );
    if (!mounted) return;
    if (ok) {
      await _reloadMeals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan and generated meals saved')),
        );
      }
    }
  }

  Future<void> _openAiGenerate() async {
    if (_generatingAi) return;
    setState(() => _generatingAi = true);
    final plan = await showAiGenerateDietDialog(
      context,
      ref,
      gymId: widget.gymId,
      categories: widget.categories,
      categoryId: _categoryId,
      initialCalories: int.tryParse(_caloriesController.text.trim()),
    );
    if (!mounted) return;
    setState(() => _generatingAi = false);
    if (plan != null) _applyAiPlan(plan);
  }

  void _applyAiPlan(Map<String, dynamic> plan) {
    setState(() {
      final name = plan['name'] as String?;
      if (name != null && name.isNotEmpty) _nameController.text = name;
      final description = plan['description'] as String?;
      if (description != null) _descriptionController.text = description;
      final calories = plan['target_calories'];
      if (calories != null) _caloriesController.text = '$calories';
      final protein = plan['target_protein_g'];
      if (protein != null) _proteinController.text = '$protein';
      final carbs = plan['target_carbs_g'];
      if (carbs != null) _carbsController.text = '$carbs';
      final fat = plan['target_fat_g'];
      if (fat != null) _fatController.text = '$fat';
      final hydration = plan['hydration_liters'];
      if (hydration != null) _hydrationController.text = '$hydration';
      final duration = plan['duration_days'];
      if (duration != null) _durationController.text = '$duration';

      final rawMeals = plan['meals'] as List<dynamic>? ?? [];
      _meals = rawMeals.asMap().entries.map((entry) {
        final meal = Map<String, dynamic>.from(entry.value as Map);
        final rawFoods = meal['foods'] as List<dynamic>? ?? [];
        return DietMealItem(
          id: null,
          mealLabel: meal['meal_label'] as String? ?? 'Meal ${entry.key + 1}',
          mealTime: meal['meal_time'] as String?,
          guidance: meal['guidance'] as String?,
          sortOrder: entry.key,
          foods: rawFoods.asMap().entries.map((foodEntry) {
            final food = Map<String, dynamic>.from(foodEntry.value as Map);
            return DietFoodItem(
              foodName: food['food_name'] as String? ?? '',
              portion: food['portion'] as String?,
              calories: (food['calories'] as num?)?.toInt(),
              proteinG: (food['protein_g'] as num?)?.toDouble(),
              carbsG: (food['carbs_g'] as num?)?.toDouble(),
              fatG: (food['fat_g'] as num?)?.toDouble(),
              notes: food['notes'] as String?,
              sortOrder: foodEntry.key,
            );
          }).toList(),
        );
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _planPersisted
              ? 'Plan applied — tap Update plan to save meals'
              : 'Plan applied — save the plan to store meals',
        ),
      ),
    );
  }

  Future<void> _reloadMeals() async {
    if (_savedPlanId == null) return;
    final meals = await ref.read(gymRepositoryProvider).dietMeals(widget.gymId, _savedPlanId!);
    if (mounted) setState(() => _meals = meals.map(DietMealItem.fromMap).toList());
  }

  Future<void> _addOrEditMeal({DietMealItem? meal}) async {
    if (!_planPersisted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Save plan details first')),
      );
      return;
    }
    final saved = await showDietMealEditorSheet(
      context,
      ref,
      gymId: widget.gymId,
      planId: _savedPlanId!,
      existing: meal,
      sortOrder: meal?.sortOrder ?? _meals.length,
    );
    if (saved) await _reloadMeals();
  }

  Future<void> _deleteMeal(DietMealItem meal) async {
    if (meal.id == null) {
      setState(() => _meals = _meals.where((m) => m != meal).toList());
      return;
    }
    final confirm = await showConfirmDialog(
      context,
      title: 'Delete meal?',
      message: 'Remove ${meal.mealLabel} and all its foods?',
      confirmLabel: 'Delete',
    );
    if (!confirm || !mounted) return;

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Delete failed',
      action: () => ref.read(gymRepositoryProvider).deleteDietMeal(
            gymId: widget.gymId,
            mealId: meal.id!,
          ),
    );
    if (ok) await _reloadMeals();
  }

  void _finish() {
    if (_planPersisted) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.planId == null ? 'New diet plan' : 'Edit diet plan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final semantics = context.appColors;
    final goal = _selectedGoal;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planId == null ? 'New diet plan' : 'Edit diet plan'),
        actions: [
          IconButton(
            tooltip: 'Generate diet plan',
            onPressed: _generatingAi ? null : _openAiGenerate,
            icon: _generatingAi
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
          ),
          TextButton(onPressed: _finish, child: const Text('Done')),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (goal != null) DietGoalGuideCard(goal: goal),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity)
                        : _imageUrl != null
                            ? Image.network(_imageUrl!, fit: BoxFit.cover, width: double.infinity)
                            : const Center(child: Text('Tap to add cover image')),
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _nameController,
                  label: 'Plan name',
                  prefixIcon: const Icon(Icons.label_outline, size: 18),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: widget.categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                  decoration: const InputDecoration(labelText: 'Goal type'),
                  items: widget.categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.goalInfo?.title ?? c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description (optional)',
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _caloriesController,
                  label: 'Target calories / day',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _proteinController,
                        label: 'Protein (g)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextField(
                        controller: _carbsController,
                        label: 'Carbs (g)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _fatController,
                        label: 'Fat (g)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextField(
                        controller: _durationController,
                        label: 'Days',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _hydrationController,
                  label: 'Water (liters / day)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                if (widget.planId != null) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active plan'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _savePlan,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_planPersisted ? 'Update plan' : 'Save plan'),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Meals & foods',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    if (_planPersisted)
                      TextButton.icon(
                        onPressed: () => _addOrEditMeal(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add meal'),
                      ),
                  ],
                ),
                if (!_planPersisted)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _meals.isEmpty
                          ? 'Save the plan above before adding meals, or generate a full plan from a template.'
                          : 'Save the plan above to store ${_meals.length} generated meals.',
                      style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
                    ),
                  ),
                ..._meals.map(
                  (meal) => Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ExpansionTile(
                      title: Text(meal.mealLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        [
                          if (meal.mealTime != null && meal.mealTime!.isNotEmpty) meal.mealTime!,
                          '${meal.foods.length} items',
                          if (meal.totalCalories > 0) '~${meal.totalCalories} kcal',
                        ].join(' · '),
                      ),
                      children: [
                        if (meal.guidance != null && meal.guidance!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(meal.guidance!),
                          ),
                        for (final food in meal.foods)
                          ListTile(
                            dense: true,
                            title: Text(food.foodName),
                            subtitle: Text(
                              [
                                if (food.portion != null) food.portion!,
                                if (food.calories != null) '${food.calories} kcal',
                              ].join(' · '),
                            ),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _addOrEditMeal(meal: meal),
                              child: const Text('Edit'),
                            ),
                            TextButton(
                              onPressed: () => _deleteMeal(meal),
                              child: Text('Delete', style: TextStyle(color: semantics.accentCoral)),
                            ),
                          ],
                        ),
                      ],
                    ),
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
