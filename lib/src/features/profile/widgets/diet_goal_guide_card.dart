import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/profile/models/diet_goal_info.dart';

class DietGoalGuideCard extends StatefulWidget {
  const DietGoalGuideCard({
    super.key,
    required this.goal,
    this.initiallyExpanded = false,
  });

  final DietGoalInfo goal;
  final bool initiallyExpanded;

  @override
  State<DietGoalGuideCard> createState() => _DietGoalGuideCardState();
}

class _DietGoalGuideCardState extends State<DietGoalGuideCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  IconData get _icon {
    switch (widget.goal.key) {
      case 'weight_loss':
        return Icons.trending_down_rounded;
      case 'muscle_gain':
        return Icons.fitness_center_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final goal = widget.goal;

    return Material(
      color: semantics.cardBackground,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? colorScheme.primary.withValues(alpha: 0.45)
                : colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(_icon, color: colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal.title,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (!_expanded) ...[
                            const SizedBox(height: 4),
                            Text(
                              goal.summary,
                              style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeIn,
              sizeCurve: Curves.easeInOut,
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(goal.summary, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 10),
                    _bullet(theme, 'Calories', goal.calorieStrategy),
                    _bullet(theme, 'Protein', goal.proteinGuide),
                    _bullet(theme, 'Carbs', goal.carbsGuide),
                    _bullet(theme, 'Fats', goal.fatsGuide),
                    const SizedBox(height: 8),
                    Text(
                      'Eat more: ${goal.sampleFoods}',
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Limit: ${goal.avoidFoods}',
                      style: theme.textTheme.labelSmall?.copyWith(color: semantics.accentCoral),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(ThemeData theme, String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.labelSmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
