import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/ai/models/churn_risk_result.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/section_header.dart';
import 'package:gym_owner_app/src/features/members/member_detail_page.dart';

class ChurnRadarSection extends StatelessWidget {
  const ChurnRadarSection({
    super.key,
    required this.gymId,
    required this.result,
  });

  final String gymId;
  final ChurnRiskResult result;

  @override
  Widget build(BuildContext context) {
    if (result.summary.totalAtRisk == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final semantics = context.appColors;
    final preview = result.members.take(3).toList();

    return Column(
      children: [
        const SizedBox(height: 4),
        SectionHeader(
          title: 'Churn radar',
          actionLabel: 'View all',
          onAction: () => _showAll(context),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _SummaryChip(
              label: 'High',
              count: result.summary.high,
              color: semantics.accentCoral,
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              label: 'Medium',
              count: result.summary.medium,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              label: 'Low',
              count: result.summary.low,
              color: Colors.amber.shade800,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...preview.map(
          (member) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => _openMember(context, member.memberId),
              leading: CircleAvatar(
                backgroundColor: _riskColor(member.riskLevel, semantics).withValues(alpha: 0.15),
                child: Icon(
                  Icons.person_outline,
                  color: _riskColor(member.riskLevel, semantics),
                  size: 20,
                ),
              ),
              title: Text(
                member.fullName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                member.reasons.join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              trailing: _RiskBadge(level: member.riskLevel, score: member.riskScore),
            ),
          ),
        ),
      ],
    );
  }

  void _openMember(BuildContext context, String memberId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemberDetailPage(gymId: gymId, memberId: memberId),
      ),
    );
  }

  void _showAll(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) {
          final semantics = sheetContext.appColors;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  'At-risk members',
                  style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: result.members.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final member = result.members[index];
                      return Card(
                        child: ListTile(
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _openMember(context, member.memberId);
                          },
                          title: Text(
                            member.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (member.phone != null && member.phone!.isNotEmpty)
                                Text(member.phone!),
                              Text(member.reasons.join(' · ')),
                              if (member.suggestedAction != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  member.suggestedAction!,
                                  style: TextStyle(
                                    color: semantics.mutedText,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: _RiskBadge(level: member.riskLevel, score: member.riskScore),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _riskColor(String level, AppSemanticColors semantics) {
    switch (level) {
      case 'high':
        return semantics.accentCoral;
      case 'medium':
        return Colors.orange.shade700;
      default:
        return Colors.amber.shade800;
    }
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.level, required this.score});

  final String level;
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'high' => context.appColors.accentCoral,
      'medium' => Colors.orange.shade700,
      _ => Colors.amber.shade800,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$score',
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          level.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
