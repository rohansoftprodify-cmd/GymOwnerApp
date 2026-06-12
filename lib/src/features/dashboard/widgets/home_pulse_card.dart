import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';

class HomePulseCard extends StatelessWidget {
  const HomePulseCard({
    super.key,
    required this.checkInsToday,
    required this.activeMembers,
    required this.pendingFeesCount,
  });

  final int checkInsToday;
  final int activeMembers;
  final int pendingFeesCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.55),
            semantics.cardBackground,
          ],
        ),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                "Today's pulse",
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PulseStat(
                  label: 'Check-ins',
                  value: '$checkInsToday',
                  icon: Icons.how_to_reg_rounded,
                  color: colorScheme.primary,
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              Expanded(
                child: _PulseStat(
                  label: 'Active plans',
                  value: '$activeMembers',
                  icon: Icons.card_membership_rounded,
                  color: colorScheme.secondary,
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              Expanded(
                child: _PulseStat(
                  label: 'Fee due',
                  value: '$pendingFeesCount',
                  icon: Icons.payments_outlined,
                  color: semantics.accentCoral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseStat extends StatelessWidget {
  const _PulseStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;

    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            height: 1,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: semantics.mutedText,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
