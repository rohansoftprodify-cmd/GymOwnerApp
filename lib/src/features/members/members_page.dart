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
  const MembersPage({
    super.key,
    required this.gymId,
    this.initialStatus,
  });

  final String gymId;
  final String? initialStatus;

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  bool _loading = true;
  List<MemberListItem> _members = [];
  String _statusFilter = 'active';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null) {
      _statusFilter = widget.initialStatus!;
    }
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

  Future<void> _markMemberLeft(MemberListItem member) async {
    final noteController = TextEditingController();
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark ${member.fullName} as Left'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to manually mark this member as inactive/left? You can optionally add a leaving message or note below.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Leaving message / Note (Optional)',
                hintText: 'e.g., Relocated to another city',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Mark as Left'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(gymRepositoryProvider);
      final noteText = noteController.text.trim();

      await repo.updateMemberStatus(
        gymId: widget.gymId,
        memberId: member.id,
        status: 'inactive',
        notes: noteText.isEmpty ? null : noteText,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.fullName} has been marked as left.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Update status failed', error: e);
    }
  }

  List<MemberListItem> get _filteredMembers {
    return _members.where((m) {
      if (m.status != _statusFilter) return false;

      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = m.fullName.toLowerCase().contains(query);
        final phoneMatch = m.phone.toLowerCase().contains(query);
        final emailMatch = m.email?.toLowerCase().contains(query) ?? false;
        final planMatch = m.planName?.toLowerCase().contains(query) ?? false;
        return nameMatch || phoneMatch || emailMatch || planMatch;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;
    final filtered = _filteredMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'Active',
                      isSelected: _statusFilter == 'active',
                      count: _members.where((m) => m.status == 'active').length,
                      onTap: () => setState(() => _statusFilter = 'active'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TabButton(
                      label: 'Left / Inactive',
                      isSelected: _statusFilter == 'inactive',
                      count: _members.where((m) => m.status == 'inactive').length,
                      onTap: () => setState(() => _statusFilter = 'inactive'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  setState(() => _searchQuery = val);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              filtered.isEmpty && !_loading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusFilter == 'active'
                                  ? Icons.people_outline_rounded
                                  : Icons.person_off_outlined,
                              size: 48,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _statusFilter == 'active'
                                  ? 'No active members'
                                  : 'No inactive/left members',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Try clearing your search query.',
                                style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _MemberCard(
                        member: filtered[i],
                        onTap: () => _openDetail(filtered[i]),
                        onMarkLeft: () => _markMemberLeft(filtered[i]),
                      ),
                    ),
              if (_loading)
                Positioned.fill(
                  child: ColoredBox(
                    color: context.loadingScrimColor,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (!_loading && _statusFilter == 'active')
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
      ],
    );
  }
}

class _MemberCard extends ConsumerWidget {
  const _MemberCard({
    required this.member,
    required this.onTap,
    this.onMarkLeft,
  });

  final MemberListItem member;
  final VoidCallback onTap;
  final VoidCallback? onMarkLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        child: Opacity(
          opacity: member.status == 'inactive' ? 0.6 : 1.0,
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
                  backgroundImage: member.imagePath != null && member.imagePath!.isNotEmpty
                      ? NetworkImage(ref.read(gymRepositoryProvider).memberImageUrl(member.imagePath)!)
                      : null,
                  child: member.imagePath != null && member.imagePath!.isNotEmpty
                      ? null
                      : Text(
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
                      Builder(builder: (ctx) {
                        final double planPrice = member.planPrice ?? 0;
                        final double amountPaid = member.amountPaid ?? 0;
                        final double dues = planPrice - amountPaid;
                        final hasDues = dues > 0 && member.paymentStatus != 'paid';

                        int extraDays = 0;
                        if (member.status == 'inactive' && member.endDate != null) {
                          final daysDiff = member.endDate!.difference(DateTime.now()).inDays;
                          if (daysDiff > 0) {
                            extraDays = daysDiff;
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [
                                if (member.planName != null) member.planName!,
                                if (member.endDate != null) 'Until ${dateFormat.format(member.endDate!)}',
                                if (member.paymentStatus != null) member.paymentStatus!.toUpperCase(),
                              ].join(' · '),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: hasDues ? colorScheme.error : colorScheme.primary,
                              ),
                            ),
                            if (member.status == 'inactive' && (extraDays > 0 || hasDues)) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (extraDays > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$extraDays days unused',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  if (hasDues)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colorScheme.error.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Due: \$${dues.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ] else if (hasDues) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Pending Due: \$${dues.toStringAsFixed(2)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: member.status == 'inactive'
                            ? colorScheme.error.withValues(alpha: 0.15)
                            : member.hasLogin
                                ? semantics.accentLime.withValues(alpha: 0.2)
                                : semantics.accentCoral.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member.status == 'inactive'
                            ? 'LEFT'
                            : member.hasLogin
                                ? 'APP'
                                : 'NO LOGIN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: member.status == 'inactive'
                              ? colorScheme.error
                              : member.hasLogin
                                  ? semantics.onAccentLime
                                  : semantics.accentCoral,
                        ),
                      ),
                    ),
                    if (member.status == 'active' && onMarkLeft != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onMarkLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.error.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_remove_outlined, size: 10, color: colorScheme.error),
                              const SizedBox(width: 4),
                              Text(
                                'Left',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      Icon(Icons.chevron_right_rounded, color: semantics.mutedText),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Material(
      color: isSelected ? colorScheme.primary : semantics.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? colorScheme.onPrimary : semantics.mutedText,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.onPrimary.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
