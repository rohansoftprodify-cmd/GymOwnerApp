import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/ai/ai_repository.dart';
import 'package:gym_owner_app/src/core/ai/diet_template_generator.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/ai/models/diet_ai_quota.dart';
import 'package:gym_owner_app/src/features/profile/models/diet_models.dart';

Future<Map<String, dynamic>?> showAiGenerateDietDialog(
  BuildContext context,
  WidgetRef ref, {
  required String gymId,
  required List<DietCategoryItem> categories,
  String? categoryId,
  int? initialCalories,
}) async {
  return showDialog<Map<String, dynamic>?>(
    context: context,
    builder: (_) => _AiGenerateDietDialog(
      gymId: gymId,
      categories: categories,
      categoryId: categoryId,
      initialCalories: initialCalories,
    ),
  );
}

class _AiGenerateDietDialog extends ConsumerStatefulWidget {
  const _AiGenerateDietDialog({
    required this.gymId,
    required this.categories,
    this.categoryId,
    this.initialCalories,
  });

  final String gymId;
  final List<DietCategoryItem> categories;
  final String? categoryId;
  final int? initialCalories;

  @override
  ConsumerState<_AiGenerateDietDialog> createState() => _AiGenerateDietDialogState();
}

class _AiGenerateDietDialogState extends ConsumerState<_AiGenerateDietDialog> {
  late String? _categoryId;
  final _caloriesController = TextEditingController();
  final _weightController = TextEditingController();
  final _cuisineController = TextEditingController(text: 'Indian gym-friendly');
  String _dietPref = 'veg';
  bool _generating = false;
  DietAiQuota? _quota;
  bool _loadingQuota = true;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    if (widget.initialCalories != null) {
      _caloriesController.text = '${widget.initialCalories}';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuota());
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _weightController.dispose();
    _cuisineController.dispose();
    super.dispose();
  }

  DietCategoryItem? get _selectedCategory {
    return widget.categories.where((c) => c.id == _categoryId).firstOrNull;
  }

  Future<void> _loadQuota() async {
    try {
      final quota = await ref.read(aiRepositoryProvider).getDietAiQuota(widget.gymId);
      if (mounted) {
        setState(() {
          _quota = quota;
          _loadingQuota = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quota = const DietAiQuota(used: 0, limit: 5, remaining: 5);
          _loadingQuota = false;
        });
      }
    }
  }

  Map<String, dynamic> _requestBody(DietPlanGenerateMode mode) {
    final category = _selectedCategory!;
    return {
      'mode': mode,
      'goalKey': category.goalKey,
      'targetCalories': int.tryParse(_caloriesController.text.trim()),
      'dietaryPreference': _dietPref,
      'memberWeightKg': double.tryParse(_weightController.text.trim()),
      'cuisineHint': _cuisineController.text.trim(),
    };
  }

  Future<void> _generate(DietPlanGenerateMode mode) async {
    final category = _selectedCategory;
    if (category == null) return;

    setState(() => _generating = true);
    try {
      final body = _requestBody(mode);
      final Map<String, dynamic> plan;

      if (mode == DietPlanGenerateMode.template) {
        // Runs on-device — no edge function or OpenAI key required.
        plan = await DietTemplateGenerator.generate(
          goalKey: category.goalKey,
          dietaryPreference: body['dietaryPreference'] as String,
          targetCalories: body['targetCalories'] as int?,
          memberWeightKg: body['memberWeightKg'] as double?,
          cuisineHint: body['cuisineHint'] as String?,
        );
      } else {
        final result = await ref.read(aiRepositoryProvider).generateDietPlan(
              gymId: widget.gymId,
              goalKey: category.goalKey,
              mode: mode,
              targetCalories: body['targetCalories'] as int?,
              dietaryPreference: body['dietaryPreference'] as String,
              memberWeightKg: body['memberWeightKg'] as double?,
              cuisineHint: body['cuisineHint'] as String?,
            );
        final rawPlan = result['plan'];
        if (rawPlan is! Map) {
          throw Exception('Server returned an invalid plan.');
        }
        plan = Map<String, dynamic>.from(rawPlan);
        if (mode == DietPlanGenerateMode.ai) {
          final quota = result['quota'];
          if (quota is Map) {
            _quota = DietAiQuota.fromMap(Map<String, dynamic>.from(quota));
          } else {
            await _loadQuota();
          }
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(plan);
    } catch (e) {
      if (!mounted) return;
      await showAppErrorDialog(
        context,
        title: mode == DietPlanGenerateMode.ai
            ? 'AI enhancement failed'
            : 'Template generation failed',
        error: e,
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantics = context.appColors;
    final quota = _quota;
    final aiRemaining = quota?.remaining ?? 0;
    final canUseAi = !_loadingQuota && aiRemaining > 0;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.restaurant_menu, size: 20),
          SizedBox(width: 8),
          Text('Generate diet plan'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: semantics.mutedText.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Start with a free curated template. Optionally enhance once with AI for more variety (limited per month).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: widget.categories.any((c) => c.id == _categoryId) ? _categoryId : null,
              decoration: const InputDecoration(labelText: 'Goal'),
              items: widget.categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.goalInfo?.title ?? c.name),
                    ),
                  )
                  .toList(),
              onChanged: _generating ? null : (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _caloriesController,
              label: 'Target calories / day',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _dietPref,
              decoration: const InputDecoration(labelText: 'Diet preference'),
              items: const [
                DropdownMenuItem(value: 'veg', child: Text('Vegetarian')),
                DropdownMenuItem(value: 'eggetarian', child: Text('Eggetarian')),
                DropdownMenuItem(value: 'non_veg', child: Text('Non-vegetarian')),
              ],
              onChanged: _generating ? null : (v) => setState(() => _dietPref = v ?? 'veg'),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _weightController,
              label: 'Member weight (kg, optional)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _cuisineController,
              label: 'Cuisine / style hint',
            ),
            if (quota != null) ...[
              const SizedBox(height: 12),
              Text(
                _loadingQuota
                    ? 'Checking AI quota…'
                    : 'AI enhancements this month: ${quota.used}/${quota.limit} used (${quota.remaining} left)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: semantics.mutedText,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _generating ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        OutlinedButton.icon(
          onPressed: _generating || _selectedCategory == null
              ? null
              : () => _generate(DietPlanGenerateMode.ai),
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: Text(canUseAi ? 'Enhance with AI' : 'AI limit reached'),
        ),
        FilledButton.icon(
          onPressed: _generating || _selectedCategory == null
              ? null
              : () => _generate(DietPlanGenerateMode.template),
          icon: _generating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.menu_book_outlined, size: 16),
          label: Text(_generating ? 'Generating…' : 'Use template'),
        ),
      ],
    );
  }
}
