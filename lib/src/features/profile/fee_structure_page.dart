import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/profile/models/subscription_plan_item.dart';
import 'package:gym_owner_app/src/features/profile/widgets/plan_form_dialog.dart';

class FeeStructurePage extends ConsumerStatefulWidget {
  const FeeStructurePage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<FeeStructurePage> createState() => _FeeStructurePageState();
}

class _FeeStructurePageState extends ConsumerState<FeeStructurePage> {
  bool _loading = true;
  List<SubscriptionPlanItem> _plans = [];
  String _currencySymbol = '₹';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final repo = ref.read(gymRepositoryProvider);
      final gym = await repo.gymById(widget.gymId);
      final rows = await repo.plans(widget.gymId);
      if (!mounted) return;
      setState(() {
        _currencySymbol = currencySymbol(gym?['currency_code'] as String?);
        _plans = rows.map(SubscriptionPlanItem.fromMap).toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    }
  }

  Future<void> _openPlanForm({SubscriptionPlanItem? existing}) async {
    await showPlanFormDialog(
      context,
      ref,
      gymId: widget.gymId,
      existing: existing,
      onSaved: () => _load(showLoading: false),
    );
  }

  Future<void> _toggleActive(SubscriptionPlanItem plan) async {
    if (plan.id == null) return;

    if (plan.isActive) {
      final confirm = await showConfirmDialog(
        context,
        title: 'Deactivate plan?',
        message:
            '“${plan.name}” will be hidden for new member subscriptions. Existing subscriptions are not changed.',
        confirmLabel: 'Deactivate',
        icon: Icons.pause_circle_outline_rounded,
      );
      if (!confirm || !mounted) return;
    }

    final ok = await runWithErrorDialog(
      context,
      errorTitle: 'Update failed',
      action: () => ref.read(gymRepositoryProvider).setPlanActive(
            gymId: widget.gymId,
            planId: plan.id!,
            isActive: !plan.isActive,
          ),
    );
    if (ok) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        if (_plans.isEmpty)
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: semantics.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.payments_rounded, size: 48, color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'No membership plans',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create plans for monthly, quarterly, or annual memberships.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _openPlanForm(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add first plan'),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: _plans.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final plan = _plans[i];
              return _PlanCard(
                plan: plan,
                currencySymbol: _currencySymbol,
                onEdit: () => _openPlanForm(existing: plan),
                onToggleActive: () => _toggleActive(plan),
              );
            },
          ),
        if (_plans.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => _openPlanForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add plan'),
            ),
          ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.currencySymbol,
    required this.onEdit,
    required this.onToggleActive,
  });

  final SubscriptionPlanItem plan;
  final String currencySymbol;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return Opacity(
      opacity: plan.isActive ? 1 : 0.65,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: semantics.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: plan.isActive
                ? colorScheme.outlineVariant.withValues(alpha: 0.35)
                : semantics.accentCoral.withValues(alpha: 0.4),
          ),
        ),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (!plan.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: semantics.accentCoral.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'INACTIVE',
                                style: TextStyle(
                                  color: semantics.accentCoral,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.durationLabel(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$currencySymbol${plan.price.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            if (plan.description != null && plan.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                plan.description!,
                style: theme.textTheme.bodySmall?.copyWith(color: semantics.mutedText),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: onToggleActive,
                  icon: Icon(
                    plan.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                  ),
                  label: Text(
                    plan.isActive ? 'Deactivate' : 'Activate',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: plan.isActive ? semantics.accentCoral : colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
