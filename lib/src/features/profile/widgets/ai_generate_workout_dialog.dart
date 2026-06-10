import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/ai/ai_repository.dart';
import 'package:gym_owner_app/src/core/ai/workout_template_generator.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/ai/models/diet_ai_quota.dart';
import 'package:gym_owner_app/src/features/profile/models/workout_models.dart';

Future<Map<String, dynamic>?> showAiGenerateWorkoutDialog(
  BuildContext context,
  WidgetRef ref, {
  required String gymId,
  required List<WorkoutCategoryItem> categories,
  String? categoryId,
}) async {
  return showDialog<Map<String, dynamic>?>(
    context: context,
    builder: (_) => _AiGenerateWorkoutDialog(
      gymId: gymId,
      categories: categories,
      categoryId: categoryId,
    ),
  );
}

class _AiGenerateWorkoutDialog extends ConsumerStatefulWidget {
  const _AiGenerateWorkoutDialog({
    required this.gymId,
    required this.categories,
    this.categoryId,
  });

  final String gymId;
  final List<WorkoutCategoryItem> categories;
  final String? categoryId;

  @override
  ConsumerState<_AiGenerateWorkoutDialog> createState() => _AiGenerateWorkoutDialogState();
}

class _AiGenerateWorkoutDialogState extends ConsumerState<_AiGenerateWorkoutDialog> {
  late String? _categoryId;
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _equipmentController = TextEditingController(text: 'dumbbells only');
  final _sessionsController = TextEditingController(text: '4');
  final _weeksController = TextEditingController(text: '4');
  String _experience = 'beginner';
  bool _generating = false;
  DietAiQuota? _quota;
  bool _loadingQuota = true;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuota());
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _equipmentController.dispose();
    _sessionsController.dispose();
    _weeksController.dispose();
    super.dispose();
  }

  WorkoutCategoryItem? get _selectedCategory =>
      widget.categories.where((c) => c.id == _categoryId).firstOrNull;

  Future<void> _loadQuota() async {
    try {
      final quota = await ref.read(aiRepositoryProvider).getWorkoutAiQuota(widget.gymId);
      if (mounted) setState(() { _quota = quota; _loadingQuota = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _quota = const DietAiQuota(used: 0, limit: 5, remaining: 5);
          _loadingQuota = false;
        });
      }
    }
  }

  Future<void> _generate(WorkoutPlanGenerateMode mode) async {
    final category = _selectedCategory;
    if (category == null) return;

    setState(() => _generating = true);
    try {
      final Map<String, dynamic> plan;
      if (mode == WorkoutPlanGenerateMode.template) {
        plan = await WorkoutTemplateGenerator.generate(
          goalKey: category.goalKey,
          experienceLevel: _experience,
          equipmentHint: _equipmentController.text.trim(),
          sessionsPerWeek: int.tryParse(_sessionsController.text.trim()),
          durationWeeks: int.tryParse(_weeksController.text.trim()),
          memberAge: int.tryParse(_ageController.text.trim()),
          memberWeightKg: double.tryParse(_weightController.text.trim()),
        );
      } else {
        final result = await ref.read(aiRepositoryProvider).generateWorkoutPlan(
              gymId: widget.gymId,
              goalKey: category.goalKey,
              mode: mode,
              experienceLevel: _experience,
              equipmentHint: _equipmentController.text.trim(),
              sessionsPerWeek: int.tryParse(_sessionsController.text.trim()),
              durationWeeks: int.tryParse(_weeksController.text.trim()),
              memberAge: int.tryParse(_ageController.text.trim()),
              memberWeightKg: double.tryParse(_weightController.text.trim()),
            );
        final rawPlan = result['plan'];
        if (rawPlan is! Map) throw Exception('Server returned an invalid plan.');
        plan = Map<String, dynamic>.from(rawPlan);
        if (mode == WorkoutPlanGenerateMode.ai) {
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
        title: mode == WorkoutPlanGenerateMode.ai ? 'AI generation failed' : 'Template failed',
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
    final canUseAi = !_loadingQuota && (quota?.remaining ?? 0) > 0;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.fitness_center, size: 20),
          SizedBox(width: 8),
          Text('AI Workout Coach'),
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
                'Generate a personalized plan from age, weight, goal, experience, and equipment. '
                'Free templates available; AI enhancements are quota-limited.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: widget.categories.any((c) => c.id == _categoryId) ? _categoryId : null,
              decoration: const InputDecoration(labelText: 'Fitness goal'),
              items: widget.categories
                  .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.goalInfo?.title ?? c.name),
                      ))
                  .toList(),
              onChanged: _generating ? null : (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _experience,
              decoration: const InputDecoration(labelText: 'Experience level'),
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'intermediate', child: Text('Intermediate')),
                DropdownMenuItem(value: 'advanced', child: Text('Advanced')),
              ],
              onChanged: _generating ? null : (v) => setState(() => _experience = v ?? 'beginner'),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _sessionsController,
              label: 'Sessions per week',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _weeksController,
              label: 'Plan duration (weeks)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _ageController,
              label: 'Member age (optional)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _weightController,
              label: 'Member weight kg (optional)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _equipmentController,
              label: 'Available equipment (e.g. dumbbells only)',
            ),
            if (quota != null) ...[
              const SizedBox(height: 12),
              Text(
                _loadingQuota
                    ? 'Checking AI quota…'
                    : 'AI generations this month: ${quota.used}/${quota.limit} (${quota.remaining} left)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: semantics.mutedText),
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
              : () => _generate(WorkoutPlanGenerateMode.ai),
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: Text(canUseAi ? 'Generate with AI' : 'AI limit reached'),
        ),
        FilledButton.icon(
          onPressed: _generating || _selectedCategory == null
              ? null
              : () => _generate(WorkoutPlanGenerateMode.template),
          icon: _generating
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.menu_book_outlined, size: 16),
          label: Text(_generating ? 'Generating…' : 'Use template'),
        ),
      ],
    );
  }
}
