import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/profile/gym_profile_provider.dart';
import 'package:gym_owner_app/src/features/profile/models/gym_amenity.dart';

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.profile,
    required this.onTap,
  });

  final GymProfileInfo profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final amenityCount = gymAmenitiesFromKeys(profile.amenities).length;
    final hasContact = profile.ownerName != null ||
        profile.gymEmail != null ||
        profile.gymPhone != null ||
        profile.address != null;

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
                right: -8,
                top: -16,
                child: Icon(
                  Icons.fitness_center_rounded,
                  size: 100,
                  color: colorScheme.onPrimary.withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Icon(
                        Icons.fitness_center_rounded,
                        color: colorScheme.onPrimary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.gymName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: semantics.accentLime,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  profile.role.toUpperCase(),
                                  style: TextStyle(
                                    color: semantics.onAccentLime,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              if (amenityCount > 0)
                                _MiniChip(
                                  label: '$amenityCount facilities',
                                  color: colorScheme.onPrimary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            hasContact
                                ? 'Contact, facilities & gym info'
                                : 'View gym details',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary.withValues(alpha: 0.82),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                      size: 26,
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
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
