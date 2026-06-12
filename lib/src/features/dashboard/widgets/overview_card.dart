import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';

class OverviewCard extends StatelessWidget {
  const OverviewCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    return Material(
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
          child: Row(
            children: [
              Container(
                width: 4,
                height: 72,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, size: 16, color: color),
                          ),
                          const Spacer(),
                          if (onTap != null)
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: semantics.mutedText,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        value,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: color,
                          fontSize: 20,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: semantics.mutedText,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
