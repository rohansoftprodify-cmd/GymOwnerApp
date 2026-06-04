import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/exercise_form_page.dart';
import 'package:gym_owner_app/src/features/profile/models/exercise_item.dart';
import 'package:gym_owner_app/src/features/profile/widgets/add_exercise_category_dialog.dart';

class ExercisesPage extends ConsumerStatefulWidget {
  const ExercisesPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends ConsumerState<ExercisesPage> {
  bool _loading = true;
  List<ExerciseCategoryItem> _categories = [];
  List<ExerciseItem> _exercises = [];
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
      final categories = await repo.exerciseCategories(widget.gymId);
      final rows = await repo.exercises(
        widget.gymId,
        categoryId: _filterCategoryId,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories.map(ExerciseCategoryItem.fromMap).toList();
        _exercises = rows
            .map(
              (r) => ExerciseItem.fromMap(
                r,
                imageUrlResolver: repo.exerciseImageUrl,
              ),
            )
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

  Future<void> _addCategory() async {
    final saved = await showAddExerciseCategoryDialog(
      context,
      ref,
      gymId: widget.gymId,
    );
    if (saved && mounted) {
      await _load();
    }
  }

  Future<void> _openForm({ExerciseItem? exercise}) async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a category first')),
      );
      return;
    }

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ExerciseFormPage(
          gymId: widget.gymId,
          exercise: exercise,
          categories: _categories,
        ),
      ),
    );
    if (saved == true && mounted) {
      await _load();
    }
  }

  Future<void> _toggleActive(ExerciseItem exercise) async {
    if (exercise.id == null) return;
    if (exercise.isActive) {
      final confirm = await showConfirmDialog(
        context,
        title: 'Deactivate exercise?',
        message: '“${exercise.name}” will be hidden from the library.',
        confirmLabel: 'Deactivate',
      );
      if (!confirm || !mounted) return;
    }

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Update failed',
      action: () => ref.read(gymRepositoryProvider).setExerciseActive(
            gymId: widget.gymId,
            exerciseId: exercise.id!,
            isActive: !exercise.isActive,
          ),
    );
    if (ok && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Text(
                    'Filter',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: semantics.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _loading ? null : _addCategory,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Category', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: _filterCategoryId == null,
                    onSelected: () => _applyFilter(null),
                  ),
                  for (final cat in _categories)
                    _CategoryChip(
                      label: cat.name,
                      selected: _filterCategoryId == cat.id,
                      onSelected: () => _applyFilter(cat.id),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _exercises.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 48,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No exercises yet',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _categories.isEmpty
                                  ? 'Add a category, then create your first exercise.'
                                  : 'Add exercises with images, benefits, and precautions.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: semantics.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: _exercises.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final item = _exercises[i];
                        return _ExerciseCard(
                          exercise: item,
                          onTap: () => _openForm(exercise: item),
                          onToggleActive: () => _toggleActive(item),
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
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add exercise'),
            ),
          ),
      ],
    );
  }
}

/// ChoiceChip avoids FilterChip label animation issues during parent rebuilds.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
        visualDensity: VisualDensity.compact,
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
        labelStyle: TextStyle(
          color: selected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onTap,
    required this.onToggleActive,
  });

  final ExerciseItem exercise;
  final VoidCallback onTap;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Opacity(
      opacity: exercise.isActive ? 1 : 0.65,
      child: Material(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: exercise.imageUrl != null
                        ? Image.network(
                            exercise.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _thumbPlaceholder(colorScheme),
                          )
                        : _thumbPlaceholder(colorScheme),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!exercise.isActive)
                            Text(
                              'INACTIVE',
                              style: TextStyle(
                                color: semantics.accentCoral,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          exercise.categoryName,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.setsRepsLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (exercise.benefits != null && exercise.benefits!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          exercise.benefits!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: semantics.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      Row(
                        children: [
                          TextButton(
                            onPressed: onTap,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Edit', style: TextStyle(fontSize: 11)),
                          ),
                          TextButton(
                            onPressed: onToggleActive,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              foregroundColor: exercise.isActive
                                  ? semantics.accentCoral
                                  : colorScheme.primary,
                            ),
                            child: Text(
                              exercise.isActive ? 'Deactivate' : 'Activate',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(Icons.fitness_center_rounded, color: colorScheme.primary),
    );
  }
}
