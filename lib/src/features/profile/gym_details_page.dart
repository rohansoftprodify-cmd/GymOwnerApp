import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/features/profile/gym_profile_provider.dart';
import 'package:gym_owner_app/src/features/profile/profile_section.dart';
import 'package:gym_owner_app/src/features/profile/widgets/gym_details_content.dart';

class GymDetailsPage extends ConsumerWidget {
  const GymDetailsPage({super.key, required this.gymId});

  final String gymId;

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(gymProfileProvider(gymId));
    await ref.read(gymProfileProvider(gymId).future);
  }

  void _openSection(BuildContext context, ProfileSection section) {
    context.push('/gym-profile/section?gymId=$gymId&section=${section.routeKey}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(gymProfileProvider(gymId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Unable to load gym details.'));
          }

          return RefreshIndicator(
            onRefresh: () => _onRefresh(ref),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  stretch: true,
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  actions: [
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () => _onRefresh(ref),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    background: GymDetailsHero(profile: profile),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: GymDetailsContent(
                      profile: profile,
                      onManageAmenities: () =>
                          context.push('/gym-amenities?gymId=$gymId'),
                      onOpenTimings: () =>
                          _openSection(context, ProfileSection.gymTiming),
                      onOpenCheckInLocation: () =>
                          context.push('/gym-check-in-location?gymId=$gymId'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
