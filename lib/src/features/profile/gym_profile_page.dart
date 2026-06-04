import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/profile/gym_profile_provider.dart';
import 'package:gym_owner_app/src/features/profile/profile_section.dart';
import 'package:gym_owner_app/src/features/profile/widgets/appearance_settings_card.dart';
import 'package:gym_owner_app/src/features/profile/widgets/gym_details_card.dart';
import 'package:gym_owner_app/src/features/profile/widgets/profile_menu_card.dart';

class GymProfilePage extends ConsumerWidget {
  const GymProfilePage({super.key, required this.gymId});

  final String gymId;

  void _openSection(BuildContext context, ProfileSection section) {
    context.push(
      '/gym-profile/section?gymId=$gymId&section=${section.routeKey}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(gymProfileProvider(gymId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Profile'),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Unable to load gym profile.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GymDetailsCard(profile: profile),
              const SizedBox(height: 20),
              Text(
                'Manage',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure plans, timings, and member resources',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: context.appColors.mutedText,
                ),
              ),
              const SizedBox(height: 12),
              ProfileMenuCard(
                icon: Icons.people_alt_rounded,
                title: 'Members',
                subtitle: 'Create accounts, assign plans & login access',
                onTap: () => context.push('/members?gymId=$gymId'),
              ),
              const SizedBox(height: 10),
              ProfileMenuCard(
                icon: ProfileSection.dietPlan.icon,
                title: 'Diet Plans',
                subtitle: ProfileSection.dietPlan.subtitle,
                onTap: () => _openSection(context, ProfileSection.dietPlan),
              ),
              const SizedBox(height: 10),
              ProfileMenuCard(
                icon: ProfileSection.exercises.icon,
                title: ProfileSection.exercises.title,
                subtitle: ProfileSection.exercises.subtitle,
                onTap: () => _openSection(context, ProfileSection.exercises),
              ),
              const SizedBox(height: 10),
              ProfileMenuCard(
                icon: ProfileSection.gymTiming.icon,
                title: ProfileSection.gymTiming.title,
                subtitle: ProfileSection.gymTiming.subtitle,
                onTap: () => _openSection(context, ProfileSection.gymTiming),
              ),
              const SizedBox(height: 10),
              ProfileMenuCard(
                icon: ProfileSection.feeStructure.icon,
                title: ProfileSection.feeStructure.title,
                subtitle: ProfileSection.feeStructure.subtitle,
                onTap: () => _openSection(context, ProfileSection.feeStructure),
              ),
              const SizedBox(height: 10),
              ProfileMenuCard(
                icon: ProfileSection.exclusiveOffers.icon,
                title: ProfileSection.exclusiveOffers.title,
                subtitle: ProfileSection.exclusiveOffers.subtitle,
                onTap: () => _openSection(context, ProfileSection.exclusiveOffers),
              ),
              const SizedBox(height: 20),
              Text(
                'Settings',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const AppearanceSettingsCard(),
            ],
          );
        },
      ),
    );
  }
}
