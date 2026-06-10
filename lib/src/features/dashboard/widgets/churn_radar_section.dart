import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
          title: 'Retention AI',
          actionLabel: 'Full report',
          onAction: () => context.push('/member-retention?gymId=$gymId'),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (result.summary.critical > 0)
              _SummaryChip(
                label: 'Critical',
                count: result.summary.critical,
                color: semantics.accentCoral,
              ),
            if (result.summary.critical > 0) const SizedBox(width: 8),
            _SummaryChip(
              label: 'High',
              count: result.summary.high,
              color: Colors.orange.shade700,
            ),
            const SizedBox(width: 8),
            _SummaryChip(
              label: 'Medium',
              count: result.summary.medium,
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
                member.displayAlert,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              trailing: _ProbabilityBadge(
                probability: member.leaveProbability30d,
                level: member.riskLevel,
              ),
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
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _ProbabilityBadge extends StatelessWidget {
  const _ProbabilityBadge({required this.probability, required this.level});

  final int probability;
  final String level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'critical' => context.appColors.accentCoral,
      'high' => Colors.orange.shade700,
      'medium' => Colors.amber.shade800,
      _ => Colors.grey.shade600,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$probability%',
          style: TextStyle(fontWeight: FontWeight.w800, color: color),
        ),
        Text(
          level.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontSize: 9),
        ),
      ],
    );
  }
}

Color _riskColor(String level, AppSemanticColors semantics) {
  switch (level) {
    case 'critical':
    case 'high':
      return semantics.accentCoral;
    case 'medium':
      return Colors.orange.shade700;
    default:
      return Colors.amber.shade800;
  }
}
