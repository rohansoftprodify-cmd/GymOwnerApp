import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/diet_plan_editor_page.dart';
import 'package:gym_owner_app/src/features/profile/models/diet_models.dart';
import 'package:gym_owner_app/src/features/profile/widgets/diet_goal_guide_card.dart';

class DietPlansPage extends ConsumerStatefulWidget {
  const DietPlansPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<DietPlansPage> createState() => _DietPlansPageState();
}

class _DietPlansPageState extends ConsumerState<DietPlansPage> {
  bool _loading = true;
  List<DietCategoryItem> _categories = [];
  List<DietPlanSummary> _plans = [];
  String? _filterCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  List<DietCategoryItem> get _visibleGuideCategories {
    if (_filterCategoryId == null) {
      return _categories.where((c) => c.goalInfo != null).toList();
    }
    return _categories.where((c) => c.id == _filterCategoryId && c.goalInfo != null).toList();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(gymRepositoryProvider);
      var categories = await repo.dietPlanCategories(widget.gymId);
      if (categories.isEmpty) {
        await repo.ensureDefaultDietCategories(widget.gymId);
        categories = await repo.dietPlanCategories(widget.gymId);
      }
      final rows = await repo.dietPlans(widget.gymId, categoryId: _filterCategoryId);
      if (!mounted) return;

      setState(() {
        _categories = categories.map(DietCategoryItem.fromMap).toList();
        _plans = rows
            .map((r) => DietPlanSummary.fromMap(r, imageUrlResolver: repo.dietImageUrl))
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    }
  }

  Future<void> _applyFilter(String? categoryId) async {
    if (_filterCategoryId == categoryId) return;
    _filterCategoryId = categoryId;
    await _load();
  }

  Future<void> _openEditor({String? planId}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DietPlanEditorPage(
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
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final guideCategories = _visibleGuideCategories;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Goals: Lose · Gain · Healthy',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: semantics.mutedText,
                  fontWeight: FontWeight.w600,
                ),
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
                    onSelected: () => _applyFilter(null),
                  ),
                  for (final cat in _categories)
                    _GoalChip(
                      label: cat.goalInfo?.shortLabel ?? cat.name,
                      selected: _filterCategoryId == cat.id,
                      onSelected: () => _applyFilter(cat.id),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _plans.isEmpty && guideCategories.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_menu_rounded, size: 48, color: colorScheme.primary),
                            const SizedBox(height: 12),
                            Text(
                              'No diet plans yet',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create plans for weight loss, muscle gain, or healthy eating.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      children: [
                        for (final cat in guideCategories) ...[
                          DietGoalGuideCard(goal: cat.goalInfo!),
                          const SizedBox(height: 10),
                        ],
                        if (_plans.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No diet plans for this goal yet.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                            ),
                          )
                        else
                          for (var i = 0; i < _plans.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _PlanCard(
                              plan: _plans[i],
                              onTap: () {
                                final id = _plans[i].id;
                                if (id != null) _openEditor(planId: id);
                              },
                            ),
                          ],
                      ],
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
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add diet plan'),
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
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onTap,
  });

  final DietPlanSummary plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Material(
      color: semantics.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: plan.imageUrl != null
                      ? Image.network(plan.imageUrl!, fit: BoxFit.cover)
                      : ColoredBox(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.restaurant, color: colorScheme.primary),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      plan.categoryName,
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (plan.targetCalories != null) '${plan.targetCalories} kcal/day',
                        '${plan.durationDays} day plan',
                        '${plan.mealCount} meals',
                      ].join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: semantics.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}
