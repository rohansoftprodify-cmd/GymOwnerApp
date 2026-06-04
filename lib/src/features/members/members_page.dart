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
  const MembersPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  bool _loading = true;
  List<MemberListItem> _members = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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

    return Stack(
      children: [
        _members.isEmpty && !_loading
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 48, color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'No members yet',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a member account with login credentials and assign a plan.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount: _members.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _MemberCard(
                  member: _members[i],
                  onTap: () => _openDetail(_members[i]),
                ),
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
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onTap,
  });

  final MemberListItem member;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                child: Text(
                  member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
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
