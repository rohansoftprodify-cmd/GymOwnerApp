import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/ui/app_components.dart';
import 'package:intl/intl.dart';

class HomeWelcomeBanner extends StatelessWidget {
  const HomeWelcomeBanner({
    super.key,
    required this.gymName,
    required this.role,
    this.onTap,
  });

  final String gymName;
  final String role;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final now = DateTime.now();
    final dateLabel = DateFormat('EEEE, d MMM').format(now);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -10,
                top: -18,
                child: Icon(
                  Icons.dashboard_rounded,
                  size: 120,
                  color: colorScheme.onPrimary.withValues(alpha: 0.07),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(size: 52, borderRadius: 14),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary.withValues(alpha: 0.86),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            gymName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _BannerChip(
                                label: dateLabel,
                                icon: Icons.calendar_today_rounded,
                                color: colorScheme.onPrimary,
                              ),
                              _BannerChip(
                                label: role.toUpperCase(),
                                color: colorScheme.onPrimary,
                                filled: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onPrimary.withValues(alpha: 0.9),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _BannerChip extends StatelessWidget {
  const _BannerChip({
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color.withValues(alpha: 0.9)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
