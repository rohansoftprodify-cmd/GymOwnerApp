import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/members/add_member_page.dart';
import 'package:gym_owner_app/src/features/members/member_detail_page.dart';
import 'package:gym_owner_app/src/features/members/models/member_list_item.dart';
import 'package:intl/intl.dart';

class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key, required this.gymId, this.initialTab});

  final String gymId;
  final String? initialTab;

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  bool _loading = true;
  List<MemberListItem> _members = [];
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final rows =
          await ref.read(gymRepositoryProvider).membersWithSubscriptions(widget.gymId);
      if (!mounted) return;
      setState(() {
        _members = rows.map(MemberListItem.fromMap).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    }
  }

  Future<void> _openAddMember() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddMemberPage(gymId: widget.gymId),
      ),
    );
    if (created == true && mounted) await _load();
  }

  Future<void> _openDetail(MemberListItem member) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MemberDetailPage(
          gymId: widget.gymId,
          memberId: member.id,
        ),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    final filteredMembers = _members.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return m.fullName.toLowerCase().contains(q) ||
          m.phone.contains(q) ||
          (m.email?.toLowerCase().contains(q) ?? false);
    }).toList();

    final activeMembers = filteredMembers.where((m) => m.status == 'active').toList();
    final inactiveMembers = filteredMembers.where((m) => m.status == 'inactive').toList();
    final leftMembers = filteredMembers.where((m) => m.status == 'left').toList();

    Widget buildList(List<MemberListItem> list, String emptyMessage) {
      if (list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline_rounded, size: 48, color: colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'No members',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                ),
              ],
            ),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: list.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final member = list[i];
          final avatarUrl = ref.read(gymRepositoryProvider).memberAvatarUrl(member.avatarUrl);
          return _MemberCard(
            member: member,
            resolvedAvatarUrl: avatarUrl,
            onTap: () => _openDetail(member),
          );
        },
      );
    }

    int initialIndex = 0;
    if (widget.initialTab == 'inactive') {
      initialIndex = 1;
    } else if (widget.initialTab == 'left') {
      initialIndex = 2;
    }

    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: 16,
          title: Container(
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name, phone or email...',
                hintStyle: TextStyle(color: semantics.mutedText, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: colorScheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              labelColor: colorScheme.primary,
              unselectedLabelColor: semantics.mutedText,
              indicatorColor: colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              tabs: [
                Tab(text: 'Active (${activeMembers.length})'),
                Tab(text: 'Inactive (${inactiveMembers.length})'),
                Tab(text: 'Left Gym (${leftMembers.length})'),
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                buildList(activeMembers, 'No active members found in this gym.'),
                buildList(inactiveMembers, 'No inactive members found in this gym.'),
                buildList(leftMembers, 'No members marked as having left this gym.'),
              ],
            ),
            if (_loading)
              Positioned.fill(
                child: ColoredBox(
                  color: context.loadingScrimColor,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            if (!_loading)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  onPressed: _openAddMember,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                  label: const Text('Add member'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    this.resolvedAvatarUrl,
    required this.onTap,
  });

  final MemberListItem member;
  final String? resolvedAvatarUrl;
  final VoidCallback onTap;

  Widget _buildFallbackAvatar(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Text(
        member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final dateFormat = DateFormat.yMMMd();

    return Material(
      color: semantics.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 120,
                  height: 90  ,
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  child: resolvedAvatarUrl != null && resolvedAvatarUrl!.isNotEmpty
                      ? Image.network(
                          resolvedAvatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackAvatar(theme, colorScheme),
                        )
                      : _buildFallbackAvatar(theme, colorScheme),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      [
                        if (member.phone.isNotEmpty) member.phone,
                        if (member.email != null && member.email!.isNotEmpty) member.email!,
                      ].join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (member.planName != null) member.planName!,
                        if (member.endDate != null) 'Until ${dateFormat.format(member.endDate!)}',
                        if (member.paymentStatus != null) member.paymentStatus!.toUpperCase(),
                      ].join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: member.hasLogin
                          ? semantics.accentLime.withValues(alpha: 0.2)
                          : semantics.accentCoral.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      member.hasLogin ? 'APP' : 'NO LOGIN',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: member.hasLogin ? semantics.onAccentLime : semantics.accentCoral,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right_rounded, color: semantics.mutedText),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
