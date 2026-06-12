import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/profile/gym_profile_provider.dart';
import 'package:gym_owner_app/src/features/profile/models/gym_amenity.dart';

class GymDetailsContent extends StatelessWidget {
  const GymDetailsContent({
    super.key,
    required this.profile,
    this.onManageAmenities,
    this.onOpenTimings,
    this.onOpenCheckInLocation,
  });

  final GymProfileInfo profile;
  final VoidCallback? onManageAmenities;
  final VoidCallback? onOpenTimings;
  final VoidCallback? onOpenCheckInLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final amenities = gymAmenitiesFromKeys(profile.amenities);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatStrip(
          role: profile.role,
          currency: profile.currencyCode,
          facilityCount: amenities.length,
        ),
        const SizedBox(height: 16),
        _QuickLinks(
          onFacilities: onManageAmenities,
          onTimings: onOpenTimings,
          onLocation: onOpenCheckInLocation,
        ),
        if (_hasOwnerInfo(profile)) ...[
          const SizedBox(height: 20),
          _SectionHeader(title: 'Owner', icon: Icons.person_outline_rounded),
          const SizedBox(height: 10),
          _InfoCard(
            children: [
              if (profile.ownerName != null && profile.ownerName!.isNotEmpty)
                _DetailRow(
                  icon: Icons.badge_outlined,
                  label: 'Name',
                  value: profile.ownerName!,
                ),
              if (profile.ownerPhone != null && profile.ownerPhone!.isNotEmpty)
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: profile.ownerPhone!,
                  copyable: true,
                ),
            ],
          ),
        ],
        if (_hasContactInfo(profile)) ...[
          const SizedBox(height: 20),
          _SectionHeader(title: 'Gym contact', icon: Icons.contact_mail_outlined),
          const SizedBox(height: 10),
          _InfoCard(
            children: [
              if (profile.gymEmail != null && profile.gymEmail!.isNotEmpty)
                _DetailRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: profile.gymEmail!,
                  copyable: true,
                ),
              if (profile.gymPhone != null && profile.gymPhone!.isNotEmpty)
                _DetailRow(
                  icon: Icons.call_outlined,
                  label: 'Phone',
                  value: profile.gymPhone!,
                  copyable: true,
                ),
            ],
          ),
        ],
        if (_hasLocationInfo(profile)) ...[
          const SizedBox(height: 20),
          _SectionHeader(title: 'Location', icon: Icons.location_on_outlined),
          const SizedBox(height: 10),
          _InfoCard(
            children: [
              if (profile.address != null && profile.address!.isNotEmpty)
                _DetailRow(
                  icon: Icons.map_outlined,
                  label: 'Address',
                  value: profile.address!,
                  copyable: true,
                  multiline: true,
                ),
              if (profile.timezone != null && profile.timezone!.isNotEmpty)
                _DetailRow(
                  icon: Icons.public_rounded,
                  label: 'Timezone',
                  value: profile.timezone!,
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            _SectionHeader(title: 'Facilities', icon: Icons.category_rounded),
            const Spacer(),
            if (onManageAmenities != null)
              TextButton.icon(
                onPressed: onManageAmenities,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Manage'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        if (amenities.isEmpty)
          _EmptyFacilitiesCard(onAdd: onManageAmenities)
        else
          _FacilitiesGrid(amenities: amenities),
        if (!_hasOwnerInfo(profile) &&
            !_hasContactInfo(profile) &&
            !_hasLocationInfo(profile) &&
            amenities.isEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Add contact details and facilities so members see accurate info in the app.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: semantics.mutedText,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  static bool _hasOwnerInfo(GymProfileInfo profile) =>
      (profile.ownerName != null && profile.ownerName!.isNotEmpty) ||
      (profile.ownerPhone != null && profile.ownerPhone!.isNotEmpty);

  static bool _hasContactInfo(GymProfileInfo profile) =>
      (profile.gymEmail != null && profile.gymEmail!.isNotEmpty) ||
      (profile.gymPhone != null && profile.gymPhone!.isNotEmpty);

  static bool _hasLocationInfo(GymProfileInfo profile) =>
      (profile.address != null && profile.address!.isNotEmpty) ||
      (profile.timezone != null && profile.timezone!.isNotEmpty);
}

class GymDetailsHero extends StatelessWidget {
  const GymDetailsHero({super.key, required this.profile});

  final GymProfileInfo profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              Icons.fitness_center_rounded,
              size: 160,
              color: colorScheme.onPrimary.withValues(alpha: 0.07),
            ),
          ),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: colorScheme.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    profile.gymName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({
    required this.role,
    required this.currency,
    required this.facilityCount,
  });

  final String role;
  final String? currency;
  final int facilityCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.shield_outlined,
            label: 'Your role',
            value: role.toUpperCase(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.payments_outlined,
            label: 'Currency',
            value: currency?.isNotEmpty == true ? currency! : '—',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: Icons.category_outlined,
            label: 'Facilities',
            value: '$facilityCount',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: semantics.mutedText,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  const _QuickLinks({
    this.onFacilities,
    this.onTimings,
    this.onLocation,
  });

  final VoidCallback? onFacilities;
  final VoidCallback? onTimings;
  final VoidCallback? onLocation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (onFacilities != null)
            _QuickLinkChip(
              icon: Icons.category_rounded,
              label: 'Manage facilities',
              onTap: onFacilities!,
            ),
          if (onTimings != null) ...[
            const SizedBox(width: 8),
            _QuickLinkChip(
              icon: Icons.schedule_rounded,
              label: 'Gym timings',
              onTap: onTimings!,
            ),
          ],
          if (onLocation != null) ...[
            const SizedBox(width: 8),
            _QuickLinkChip(
              icon: Icons.location_on_rounded,
              label: 'Check-in GPS',
              onTap: onLocation!,
              color: colorScheme.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickLinkChip extends StatelessWidget {
  const _QuickLinkChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;

    return ActionChip(
      avatar: Icon(icon, size: 16, color: accent),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: accent.withValues(alpha: 0.1),
      side: BorderSide(color: accent.withValues(alpha: 0.25)),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: accent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final semantics = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 52,
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            children[i],
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
    this.copyable = false,
    this.multiline = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: semantics.mutedText,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: multiline ? 1.35 : 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              tooltip: 'Copy',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied $label'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(Icons.copy_rounded, size: 18, color: semantics.mutedText),
            ),
        ],
      ),
    );
  }
}

class _FacilitiesGrid extends StatelessWidget {
  const _FacilitiesGrid({required this.amenities});

  final List<GymAmenity> amenities;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 360 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.05,
          ),
          itemCount: amenities.length,
          itemBuilder: (context, index) => _FacilityTile(amenity: amenities[index]),
        );
      },
    );
  }
}

class _FacilityTile extends StatelessWidget {
  const _FacilityTile({required this.amenity});

  final GymAmenity amenity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(amenity.icon, size: 22, color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            amenity.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFacilitiesCard extends StatelessWidget {
  const _EmptyFacilitiesCard({this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.category_outlined, size: 36, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            'No facilities added yet',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Add yoga, pool, PT & more — members see these on your gym profile.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: semantics.mutedText,
              height: 1.35,
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add facilities'),
            ),
          ],
        ],
      ),
    );
  }
}
