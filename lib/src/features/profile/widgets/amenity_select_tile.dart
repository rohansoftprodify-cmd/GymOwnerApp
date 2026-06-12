import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/profile/models/gym_amenity.dart';

class AmenitySelectTile extends StatelessWidget {
  const AmenitySelectTile({
    super.key,
    required this.amenity,
    required this.selected,
    required this.onTap,
  });

  final GymAmenity amenity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;
    final accent = colorScheme.primary;

    return Material(
      color: selected ? accent.withValues(alpha: 0.1) : semantics.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.55)
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? accent.withValues(alpha: 0.16)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      amenity.icon,
                      size: 24,
                      color: selected ? accent : semantics.mutedText,
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: semantics.cardBackground, width: 2),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                amenity.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                  height: 1.2,
                  color: selected ? colorScheme.onSurface : semantics.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
