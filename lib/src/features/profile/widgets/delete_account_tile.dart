import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';

class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: semantics.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: semantics.accentCoral.withValues(alpha: 0.45)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.delete_forever_outlined, color: semantics.accentCoral, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete account',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: semantics.accentCoral,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Permanently remove your login and app data',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: semantics.mutedText,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
