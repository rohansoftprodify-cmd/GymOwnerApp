import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/profile/gym_profile_provider.dart';
import 'package:gym_owner_app/src/features/profile/models/gym_amenity.dart';

class GymDetailsCard extends StatelessWidget {
  const GymDetailsCard({super.key, required this.profile});

  final GymProfileInfo profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              color: colorScheme.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile.gymName,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: semantics.accentLime,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              profile.role.toUpperCase(),
              style: TextStyle(
                color: semantics.onAccentLime,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          if (profile.ownerName != null && profile.ownerName!.isNotEmpty)
            _DetailRow(
              icon: Icons.person_outline_rounded,
              label: 'Owner',
              value: profile.ownerName!,
            ),
          if (profile.ownerPhone != null && profile.ownerPhone!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Contact',
              value: profile.ownerPhone!,
            ),
          ],
          if (profile.gymEmail != null && profile.gymEmail!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile.gymEmail!,
            ),
          ],
          if (profile.gymPhone != null && profile.gymPhone!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.call_outlined,
              label: 'Gym phone',
              value: profile.gymPhone!,
            ),
          ],
          if (profile.address != null && profile.address!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: profile.address!,
            ),
          ],
          if (profile.timezone != null && profile.timezone!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.public_rounded,
              label: 'Timezone',
              value: profile.timezone!,
            ),
          ],
          if (profile.amenities.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Facilities',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: semantics.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final amenity in gymAmenitiesFromKeys(profile.amenities))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(amenity.icon, size: 14, color: colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          amenity.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: semantics.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
