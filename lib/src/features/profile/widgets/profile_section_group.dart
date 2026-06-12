import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';

class ProfileMenuItem {
  const ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accentColor;
  final String? badge;
}

class ProfileSectionGroup extends StatelessWidget {
  const ProfileSectionGroup({
    super.key,
    required this.title,
    required this.items,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: colorScheme.primary),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
          ),
        ],
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: semantics.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 58,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ProfileMenuRow(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileMenuRow extends StatelessWidget {
  const ProfileMenuRow({super.key, required this.item});

  final ProfileMenuItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;
    final accent = item.accentColor ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(item.icon, color: accent, size: 20),
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
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (item.badge != null)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.badge!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: accent,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: semantics.mutedText,
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: semantics.mutedText, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
