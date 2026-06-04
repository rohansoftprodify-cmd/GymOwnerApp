import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/gym_repository.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/profile/diet_plans_page.dart';
import 'package:gym_owner_app/src/features/profile/exercises_page.dart';
import 'package:gym_owner_app/src/features/profile/exclusive_offers_page.dart';
import 'package:gym_owner_app/src/features/profile/fee_structure_page.dart';
import 'package:gym_owner_app/src/features/profile/gym_timing_page.dart';
import 'package:gym_owner_app/src/features/profile/profile_section.dart';

class GymProfileSectionPage extends ConsumerWidget {
  const GymProfileSectionPage({
    super.key,
    required this.gymId,
    required this.section,
  });

  final String gymId;
  final ProfileSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(gymRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(section.title)),
      body: section == ProfileSection.gymTiming
          ? GymTimingPage(gymId: gymId)
          : section == ProfileSection.feeStructure
              ? FeeStructurePage(gymId: gymId)
              : section == ProfileSection.exclusiveOffers
                  ? ExclusiveOffersPage(gymId: gymId)
                  : section == ProfileSection.exercises
                      ? ExercisesPage(gymId: gymId)
                      : section == ProfileSection.dietPlan
                          ? DietPlansPage(gymId: gymId)
                          : FutureBuilder<List<dynamic>>(
        future: _loadData(repo),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return switch (section) {
            ProfileSection.feeStructure => const SizedBox.shrink(),
            ProfileSection.exclusiveOffers => const SizedBox.shrink(),
            ProfileSection.gymTiming => const SizedBox.shrink(),
            ProfileSection.dietPlan => _PlaceholderBody(
                icon: section.icon,
                title: 'Add Diet Plan',
                message: 'Create meal plans and assign them to members. Coming soon.',
                actionLabel: 'Add diet plan',
              ),
            ProfileSection.exercises => const SizedBox.shrink(),
          };
        },
      ),
    );
  }

  Future<List<dynamic>> _loadData(GymRepository repo) async {
    switch (section) {
      case ProfileSection.feeStructure:
        throw StateError('Fee structure loads in FeeStructurePage');
      case ProfileSection.exclusiveOffers:
        throw StateError('Exclusive offers loads in ExclusiveOffersPage');
      case ProfileSection.gymTiming:
        throw StateError('Gym timing loads in GymTimingPage');
      case ProfileSection.exercises:
        throw StateError('Exercises loads in ExercisesPage');
      case ProfileSection.dietPlan:
        throw StateError('Diet plans loads in DietPlansPage');
    }
  }
}

class _PlaceholderBody extends StatelessWidget {
  const _PlaceholderBody({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: semantics.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 48, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$actionLabel — coming soon')),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
