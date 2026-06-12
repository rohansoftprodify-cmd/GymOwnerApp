import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/profile/gym_profile_provider.dart';
import 'package:gym_owner_app/src/features/profile/profile_section.dart';
import 'package:gym_owner_app/src/features/profile/widgets/appearance_settings_card.dart';
import 'package:gym_owner_app/src/features/profile/widgets/profile_quick_actions.dart';
import 'package:gym_owner_app/src/features/profile/widgets/profile_section_group.dart';
import 'package:gym_owner_app/src/features/profile/widgets/profile_settings_search_bar.dart';
import 'package:gym_owner_app/src/features/profile/widgets/profile_summary_card.dart';

class _ProfileSectionConfig {
  const _ProfileSectionConfig({
    required this.title,
    required this.items,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<ProfileMenuItem> items;
}

class GymProfilePage extends ConsumerStatefulWidget {
  const GymProfilePage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymProfilePage> createState() => _GymProfilePageState();
}

class _GymProfilePageState extends ConsumerState<GymProfilePage> {
  static const _sectionGap = 22.0;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _settingsSectionKey = GlobalKey();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text != _searchQuery) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openSection(ProfileSection section) {
    context.push(
      '/gym-profile/section?gymId=${widget.gymId}&section=${section.routeKey}',
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _scrollToSettings() {
    _clearSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _settingsSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    });
  }

  Future<void> _onRefresh() async {
    ref.invalidate(gymProfileProvider(widget.gymId));
    await ref.read(gymProfileProvider(widget.gymId).future);
  }

  List<_ProfileSectionConfig> _allSections(
    ColorScheme colorScheme,
    AppSemanticColors semantics,
  ) {
    return [
      _ProfileSectionConfig(
        title: 'Profile',
        subtitle: 'Gym information',
        icon: Icons.storefront_outlined,
        items: [
          ProfileMenuItem(
            icon: Icons.info_outline_rounded,
            title: 'Gym details',
            subtitle: 'Contact, address, facilities & timezone',
            onTap: () => context.push('/gym-details?gymId=${widget.gymId}'),
          ),
        ],
      ),
      _ProfileSectionConfig(
        title: 'Members & check-in',
        subtitle: 'Accounts, facilities, and attendance setup',
        icon: Icons.people_alt_outlined,
        items: [
          ProfileMenuItem(
            icon: Icons.people_alt_rounded,
            title: 'Members',
            subtitle: 'Create accounts, assign plans & login access',
            onTap: () => context.push('/members?gymId=${widget.gymId}'),
          ),
          ProfileMenuItem(
            icon: Icons.category_rounded,
            title: 'Gym facilities',
            subtitle: 'Personal training, yoga, pool, spa & more',
            onTap: () => context.push('/gym-amenities?gymId=${widget.gymId}'),
          ),
          ProfileMenuItem(
            icon: Icons.location_on_rounded,
            title: 'Check-in location',
            subtitle: 'Gym GPS coordinates & check-in radius',
            onTap: () =>
                context.push('/gym-check-in-location?gymId=${widget.gymId}'),
          ),
          ProfileMenuItem(
            icon: Icons.qr_code_2_rounded,
            title: 'Check-in QR',
            subtitle: 'Print entrance QR for member self check-in',
            onTap: () => context.push('/gym-check-in-qr?gymId=${widget.gymId}'),
          ),
        ],
      ),
      _ProfileSectionConfig(
        title: 'AI intelligence',
        subtitle: 'Analytics, forecasts, and automation',
        icon: Icons.auto_awesome_outlined,
        items: [
          ProfileMenuItem(
            icon: Icons.insights_rounded,
            title: 'AI Attendance Analytics',
            subtitle: 'Peak hours, quiet hours & floor-load insights',
            badge: 'AI',
            accentColor: colorScheme.primary,
            onTap: () =>
                context.push('/attendance-analytics?gymId=${widget.gymId}'),
          ),
          ProfileMenuItem(
            icon: Icons.query_stats_rounded,
            title: 'Membership Sales Forecast',
            subtitle: 'Revenue, renewals & churn projections',
            badge: 'AI',
            onTap: () => context.push('/sales-forecast?gymId=${widget.gymId}'),
          ),
          ProfileMenuItem(
            icon: Icons.shield_outlined,
            title: 'Member Retention AI',
            subtitle: 'Predict cancellations & contact at-risk members',
            badge: 'AI',
            accentColor: semantics.accentCoral,
            onTap: () => context.push('/member-retention?gymId=${widget.gymId}'),
          ),
          ProfileMenuItem(
            icon: Icons.campaign_outlined,
            title: 'AI Marketing Assistant',
            subtitle: 'Instagram posts, offers, captions & push copy',
            badge: 'AI',
            onTap: () =>
                context.push('/marketing-assistant?gymId=${widget.gymId}'),
          ),
          ProfileMenuItem(
            icon: Icons.support_agent_rounded,
            title: 'Member Support Bot',
            subtitle: 'Q&A for timings, plans, trainers & diet',
            onTap: () => context.push('/support-faqs?gymId=${widget.gymId}'),
          ),
          ProfileMenuItem(
            icon: Icons.analytics_outlined,
            title: 'AI Analysis',
            subtitle: 'Joins, sales, attendance & member insights',
            badge: 'AI',
            onTap: () => context.push('/ai-analysis?gymId=${widget.gymId}'),
          ),
        ],
      ),
      _ProfileSectionConfig(
        title: 'Member programs',
        subtitle: 'Workouts, diet, and exercise library',
        icon: Icons.fitness_center_outlined,
        items: [
          ProfileMenuItem(
            icon: ProfileSection.workoutPlans.icon,
            title: 'AI Workout Coach',
            subtitle: ProfileSection.workoutPlans.subtitle,
            badge: 'AI',
            onTap: () => _openSection(ProfileSection.workoutPlans),
          ),
          ProfileMenuItem(
            icon: ProfileSection.dietPlan.icon,
            title: 'Diet Plans',
            subtitle: ProfileSection.dietPlan.subtitle,
            onTap: () => _openSection(ProfileSection.dietPlan),
          ),
          ProfileMenuItem(
            icon: ProfileSection.exercises.icon,
            title: ProfileSection.exercises.title,
            subtitle: ProfileSection.exercises.subtitle,
            onTap: () => _openSection(ProfileSection.exercises),
          ),
        ],
      ),
      _ProfileSectionConfig(
        title: 'Gym setup',
        subtitle: 'Hours, pricing, and promotions',
        icon: Icons.tune_rounded,
        items: [
          ProfileMenuItem(
            icon: ProfileSection.gymTiming.icon,
            title: ProfileSection.gymTiming.title,
            subtitle: ProfileSection.gymTiming.subtitle,
            onTap: () => _openSection(ProfileSection.gymTiming),
          ),
          ProfileMenuItem(
            icon: ProfileSection.feeStructure.icon,
            title: ProfileSection.feeStructure.title,
            subtitle: ProfileSection.feeStructure.subtitle,
            onTap: () => _openSection(ProfileSection.feeStructure),
          ),
          ProfileMenuItem(
            icon: ProfileSection.exclusiveOffers.icon,
            title: ProfileSection.exclusiveOffers.title,
            subtitle: ProfileSection.exclusiveOffers.subtitle,
            onTap: () => _openSection(ProfileSection.exclusiveOffers),
          ),
          ProfileMenuItem(
            icon: Icons.payments_outlined,
            title: 'Payment QR & UPI',
            subtitle: 'Upload QR codes and UPI IDs for member payments',
            onTap: () =>
                context.push('/gym-payment-options?gymId=${widget.gymId}'),
          ),
        ],
      ),
      _ProfileSectionConfig(
        title: 'Settings',
        subtitle: 'App appearance and preferences',
        icon: Icons.settings_outlined,
        items: [
          ProfileMenuItem(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Light, dark & system theme',
            onTap: _scrollToSettings,
          ),
        ],
      ),
    ];
  }

  bool _itemMatches(ProfileMenuItem item, String sectionTitle, String query) {
    if (query.isEmpty) return true;
    final haystack =
        '${item.title} ${item.subtitle} $sectionTitle ${item.badge ?? ''}'
            .toLowerCase();
    return haystack.contains(query);
  }

  List<_ProfileSectionConfig> _filteredSections(List<_ProfileSectionConfig> all) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return all;

    return [
      for (final section in all)
        _ProfileSectionConfig(
          title: section.title,
          subtitle: section.subtitle,
          icon: section.icon,
          items: [
            for (final item in section.items)
              if (_itemMatches(item, section.title, query)) item,
          ],
        ),
    ].where((section) => section.items.isNotEmpty).toList();
  }

  List<Widget> _sectionWidgets(List<_ProfileSectionConfig> sections) {
    final widgets = <Widget>[];
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      if (i > 0) widgets.add(const SizedBox(height: _sectionGap));
      widgets.add(
        ProfileSectionGroup(
          title: section.title,
          subtitle: section.subtitle,
          icon: section.icon,
          items: section.items,
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(gymProfileProvider(widget.gymId));
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Gym Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Unable to load gym profile.'));
          }

          final allSections = _allSections(colorScheme, semantics);
          final filteredSections = _filteredSections(allSections);
          final visibleSections = isSearching
              ? filteredSections
              : filteredSections
                  .where((s) => s.title != 'Profile' && s.title != 'Settings')
                  .toList();
          final totalMatches =
              filteredSections.fold<int>(0, (sum, s) => sum + s.items.length);

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (!isSearching) ...[
                  ProfileSummaryCard(
                    profile: profile,
                    onTap: () =>
                        context.push('/gym-details?gymId=${widget.gymId}'),
                  ),
                  const SizedBox(height: 14),
                  ProfileQuickActions(
                    actions: [
                      ProfileQuickAction(
                        icon: Icons.people_alt_rounded,
                        label: 'Members',
                        onTap: () =>
                            context.push('/members?gymId=${widget.gymId}'),
                      ),
                      ProfileQuickAction(
                        icon: Icons.category_rounded,
                        label: 'Facilities',
                        onTap: () =>
                            context.push('/gym-amenities?gymId=${widget.gymId}'),
                      ),
                      ProfileQuickAction(
                        icon: Icons.schedule_rounded,
                        label: 'Timings',
                        onTap: () => _openSection(ProfileSection.gymTiming),
                      ),
                      ProfileQuickAction(
                        icon: Icons.payments_rounded,
                        label: 'Plans',
                        onTap: () => _openSection(ProfileSection.feeStructure),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                ProfileSettingsSearchBar(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  onClear: _clearSearch,
                ),
                if (isSearching) ...[
                  const SizedBox(height: 10),
                  Text(
                    totalMatches == 0
                        ? 'No results for “${_searchQuery.trim()}”'
                        : '$totalMatches result${totalMatches == 1 ? '' : 's'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: semantics.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: _sectionGap),
                if (isSearching && totalMatches == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: semantics.mutedText.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Try searching for members, diet, QR, AI, theme…',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: semantics.mutedText,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ..._sectionWidgets(visibleSections),
                  if (!isSearching) ...[
                    const SizedBox(height: _sectionGap),
                    KeyedSubtree(
                      key: _settingsSectionKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Settings',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'App appearance and preferences',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: semantics.mutedText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const AppearanceSettingsCard(),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
