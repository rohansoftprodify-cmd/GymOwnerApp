import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/ai/ai_repository.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/ai/models/churn_risk_result.dart';
import 'package:gym_owner_app/src/features/members/member_detail_page.dart';

class MemberRetentionPage extends ConsumerStatefulWidget {
  const MemberRetentionPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<MemberRetentionPage> createState() => _MemberRetentionPageState();
}

class _MemberRetentionPageState extends ConsumerState<MemberRetentionPage> {
  bool _loading = true;
  ChurnRiskResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await ref.read(aiRepositoryProvider).getChurnRisks(widget.gymId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: e);
    }
  }

  void _copyContact(ChurnRiskMember member) {
    final phone = member.phone?.trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number on file for this member.')),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied $phone — ready to call or message')),
    );
  }

  void _openMember(ChurnRiskMember member) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MemberDetailPage(
          gymId: widget.gymId,
          memberId: member.memberId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final result = _result;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Retention AI'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : result == null
              ? const Center(child: Text('No retention data available.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _HeaderCard(summary: result.summary),
                      const SizedBox(height: 16),
                      Text(
                        'How signals are scored',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const _SignalLegend(
                        icon: Icons.directions_run_rounded,
                        title: 'Attendance',
                        detail: 'Missed visits and drop vs prior 30 days',
                      ),
                      const _SignalLegend(
                        icon: Icons.payments_outlined,
                        title: 'Payments',
                        detail: 'Overdue or partial membership fees',
                      ),
                      const _SignalLegend(
                        icon: Icons.phone_android_rounded,
                        title: 'App engagement',
                        detail: 'Member app logins and self check-ins',
                      ),
                      const SizedBox(height: 16),
                      if (result.members.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No at-risk members right now — retention looks healthy.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: semantics.mutedText,
                            ),
                          ),
                        )
                      else
                        ...result.members.map(
                          (member) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              member.fullName,
                                              style: theme.textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            if (member.phone != null &&
                                                member.phone!.isNotEmpty)
                                              Text(
                                                member.phone!,
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  color: semantics.mutedText,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      _ProbabilityBadge(
                                        probability: member.leaveProbability30d,
                                        level: member.riskLevel,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          size: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            member.displayAlert,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final reason in member.reasons)
                                        Chip(
                                          label: Text(
                                            reason,
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                    ],
                                  ),
                                  if (member.signals != null) ...[
                                    const SizedBox(height: 10),
                                    _SignalRow(
                                      label: 'Attendance',
                                      score: member.signals!.attendance.score,
                                      detail:
                                          '${member.signals!.attendance.checkInsLast30d} visits (was ${member.signals!.attendance.checkInsPrior30d})',
                                    ),
                                    _SignalRow(
                                      label: 'Payment',
                                      score: member.signals!.payment.score,
                                      detail: member.signals!.payment.status ?? 'paid',
                                    ),
                                    _SignalRow(
                                      label: 'Engagement',
                                      score: member.signals!.engagement.score,
                                      detail:
                                          '${member.signals!.engagement.appCheckInsLast30d} app check-ins',
                                    ),
                                  ],
                                  if (member.suggestedAction != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      member.suggestedAction!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: semantics.mutedText,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _copyContact(member),
                                          icon: const Icon(Icons.call_outlined, size: 18),
                                          label: const Text('Contact'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () => _openMember(member),
                                          icon: const Icon(Icons.person_outline, size: 18),
                                          label: const Text('View member'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.summary});

  final ChurnRiskSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            semantics.accentCoral,
            semantics.accentCoral.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                '30-day leave probability',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${summary.totalAtRisk} members need proactive outreach',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CountChip(label: 'Critical', count: summary.critical),
              const SizedBox(width: 8),
              _CountChip(label: 'High', count: summary.high),
              const SizedBox(width: 8),
              _CountChip(label: 'Medium', count: summary.medium),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            '$probability%',
            style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 18),
          ),
          Text(
            level.toUpperCase(),
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _SignalLegend extends StatelessWidget {
  const _SignalLegend({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(detail, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({
    required this.label,
    required this.score,
    required this.detail,
  });

  final String label;
  final int score;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.labelSmall),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: (score / 40).clamp(0.0, 1.0),
              minHeight: 5,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(detail, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
