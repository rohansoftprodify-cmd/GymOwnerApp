import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/workout_models.dart';
import 'package:gym_owner_app/src/features/profile/workout_plan_editor_page.dart';

class WorkoutPlansPage extends ConsumerStatefulWidget {
  const WorkoutPlansPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<WorkoutPlansPage> createState() => _WorkoutPlansPageState();
}

class _WorkoutPlansPageState extends ConsumerState<WorkoutPlansPage> {
  bool _loading = true;
  List<WorkoutCategoryItem> _categories = [];
  List<WorkoutPlanSummary> _plans = [];
  String? _filterCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(gymRepositoryProvider);
      var categories = await repo.workoutPlanCategories(widget.gymId);
      if (categories.isEmpty) {
        await repo.ensureDefaultWorkoutCategories(widget.gymId);
        categories = await repo.workoutPlanCategories(widget.gymId);
      }
      final rows = await repo.workoutPlans(widget.gymId, categoryId: _filterCategoryId);
      if (!mounted) return;
      setState(() {
        _categories = categories.map(WorkoutCategoryItem.fromMap).toList();
        _plans = rows.map(WorkoutPlanSummary.fromMap).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    }
  }

  Future<void> _openEditor({String? planId}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkoutPlanEditorPage(
          gymId: widget.gymId,
          planId: planId,
          categories: _categories,
        ),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'AI Workout Coach — personalized plans by goal, experience & equipment',
                style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _GoalChip(
                    label: 'All',
                    selected: _filterCategoryId == null,
                    onSelected: () {
                      _filterCategoryId = null;
                      _load();
                    },
                  ),
                  for (final cat in _categories)
                    _GoalChip(
                      label: cat.goalInfo?.shortLabel ?? cat.name,
                      selected: _filterCategoryId == cat.id,
                      onSelected: () {
                        _filterCategoryId = cat.id;
                        _load();
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: _plans.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fitness_center_rounded, size: 48, color: theme.colorScheme.primary),
                            const SizedBox(height: 12),
                            Text(
                              'No workout plans yet',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a 4-day muscle gain plan for beginners with dumbbells only — tap + to start.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: _plans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final plan = _plans[i];
                        return Card(
                          child: ListTile(
                            onTap: () {
                              final id = plan.id;
                              if (id != null) _openEditor(planId: id);
                            },
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                              child: Icon(
                                Icons.fitness_center_rounded,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              '${plan.sessionsPerWeek} days/wk · ${plan.experienceLevel} · '
                              '${plan.equipmentHint ?? 'any equipment'}',
                            ),
                            trailing: plan.isActive
                                ? null
                                : Text('Inactive', style: TextStyle(color: semantics.mutedText, fontSize: 11)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        if (_loading)
          Positioned.fill(
            child: ColoredBox(
              color: context.loadingScrimColor,
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        if (!_loading)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('AI workout plan'),
            ),
          ),
      ],
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
      ),
    );
  }
}
