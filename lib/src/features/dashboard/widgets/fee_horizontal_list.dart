import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/domain/report_calculations.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/members/member_detail_page.dart';
import 'package:intl/intl.dart';

enum FeeListMode { pendingFees, renewals }

class FeeHorizontalList extends ConsumerWidget {
  const FeeHorizontalList({
    super.key,
    required this.items,
    required this.emptyText,
    this.mode = FeeListMode.pendingFees,
    this.onRefresh,
    this.onViewAll,
  });

  final List<Map<String, dynamic>> items;
  final String emptyText;
  final FeeListMode mode;
  final VoidCallback? onRefresh;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: semantics.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: colorScheme.primary.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              emptyText,
              style: theme.textTheme.labelMedium?.copyWith(
                color: semantics.mutedText,
              ),
            ),
          ],
        ),
      );
    }

    final height = mode == FeeListMode.pendingFees ? 148.0 : 108.0;
    final showViewAll = onViewAll != null;

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + (showViewAll ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (showViewAll && i == items.length) {
            return _ViewAllCard(onTap: onViewAll!);
          }
          final item = items[i];
          if (mode == FeeListMode.renewals) {
            return _RenewalCard(item: item, ref: ref, onRefresh: onRefresh);
          }
          return _PendingFeeCard(item: item, ref: ref, onRefresh: onRefresh);
        },
      ),
    );
  }
}

class _ViewAllCard extends StatelessWidget {
  const _ViewAllCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    return SizedBox(
      width: 120,
      child: Material(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'View All',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingFeeCard extends StatelessWidget {
  const _PendingFeeCard({
    required this.item,
    required this.ref,
    this.onRefresh,
  });

  final Map<String, dynamic> item;
  final WidgetRef ref;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    final member =
        (item['members'] as Map<String, dynamic>? ?? const {})['full_name'] ??
        'Unknown';
    final plan =
        (item['subscription_plans'] as Map<String, dynamic>? ??
            const {})['name'] ??
        '-';
    final planPrice =
        ((item['subscription_plans'] as Map<String, dynamic>?)?['price']
                as num?)
            ?.toDouble() ??
        0;
    final amountPaid = (item['amount_paid'] as num?)?.toDouble() ?? 0;
    final remaining = pendingAmount(
      planPrice: planPrice,
      amountPaid: amountPaid,
    );
    final status = (item['payment_status'] as String? ?? '-').toUpperCase();
    final endDateRaw = item['end_date'] as String?;
    final dueLabel = endDateRaw != null
        ? 'Due ${DateFormat.yMMMd().format(DateTime.parse(endDateRaw))}'
        : 'Due —';

    final avatarPath =
        ((item['members'] as Map<String, dynamic>?)?['avatar_url'] as String?);
    final resolvedAvatarUrl =
        ref.read(gymRepositoryProvider).memberAvatarUrl(avatarPath);

    return SizedBox(
      width: 280,
      child: Container(
        decoration: BoxDecoration(
          color: semantics.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: semantics.accentCoral,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                                backgroundImage: resolvedAvatarUrl != null && resolvedAvatarUrl.isNotEmpty
                                    ? NetworkImage(resolvedAvatarUrl)
                                    : null,
                                child: resolvedAvatarUrl == null || resolvedAvatarUrl.isEmpty
                                    ? Text(
                                        member.toString().trim().isEmpty ? '?' : member.toString()[0].toUpperCase(),
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: colorScheme.primary),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  member.toString(),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            plan.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: semantics.accentCoral.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: semantics.accentCoral,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 11,
                                color: semantics.mutedText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                dueLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  color: semantics.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${remaining.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          'REMAINING',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 8,
                            color: semantics.mutedText,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            showDialog<void>(
                              context: context,
                              builder: (_) => _CollectFeeDialog(
                                item: item,
                                ref: ref,
                                onRefresh: onRefresh,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Collect',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RenewalCard extends StatelessWidget {
  const _RenewalCard({
    required this.item,
    required this.ref,
    this.onRefresh,
  });

  final Map<String, dynamic> item;
  final WidgetRef ref;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantics = context.appColors;

    final member =
        (item['members'] as Map<String, dynamic>? ?? const {})['full_name'] ??
        'Unknown';
    final plan =
        (item['subscription_plans'] as Map<String, dynamic>? ??
            const {})['name'] ??
        '-';
    final endDateRaw = item['end_date'] as String?;
    final daysLeft = renewalDaysLeft(endDateRaw);
    final daysLabel = renewalDaysLabel(daysLeft);

    final avatarPath =
        ((item['members'] as Map<String, dynamic>?)?['avatar_url'] as String?);
    final resolvedAvatarUrl =
        ref.read(gymRepositoryProvider).memberAvatarUrl(avatarPath);

    final memberId = item['member_id'] as String?;
    final gymId = item['gym_id'] as String?;

    return SizedBox(
      width: 260,
      child: Material(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: (memberId == null || gymId == null)
              ? null
              : () async {
                  final saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => MemberDetailPage(
                        gymId: gymId,
                        memberId: memberId,
                      ),
                    ),
                  );
                  if (saved == true && onRefresh != null) {
                    onRefresh!();
                  }
                },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                  backgroundImage: resolvedAvatarUrl != null && resolvedAvatarUrl.isNotEmpty
                      ? NetworkImage(resolvedAvatarUrl)
                      : null,
                  child: resolvedAvatarUrl == null || resolvedAvatarUrl.isEmpty
                      ? Text(
                          member.toString().trim().isEmpty
                              ? '?'
                              : member.toString()[0].toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        member.toString(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: semantics.mutedText,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  daysLabel,
                  style: TextStyle(
                    color: semantics.accentLime,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectFeeDialog extends StatefulWidget {
  const _CollectFeeDialog({
    required this.item,
    required this.ref,
    this.onRefresh,
  });

  final Map<String, dynamic> item;
  final WidgetRef ref;
  final VoidCallback? onRefresh;

  @override
  State<_CollectFeeDialog> createState() => _CollectFeeDialogState();
}

class _CollectFeeDialogState extends State<_CollectFeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late double _planPrice;
  late double _currentAmountPaid;
  late String _paymentStatus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _planPrice = ((widget.item['subscription_plans'] as Map<String, dynamic>?)?['price'] as num?)?.toDouble() ?? 0;
    _currentAmountPaid = (widget.item['amount_paid'] as num?)?.toDouble() ?? 0;
    _paymentStatus = (widget.item['payment_status'] as String? ?? 'due').toLowerCase();
    _amountController = TextEditingController(text: _currentAmountPaid.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateStatusFromAmount(double paidAmount) {
    setState(() {
      _currentAmountPaid = paidAmount;
      if (paidAmount >= _planPrice) {
        _paymentStatus = 'paid';
      } else if (paidAmount <= 0) {
        _paymentStatus = 'due';
      } else {
        _paymentStatus = 'partial';
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final newPaid = double.tryParse(_amountController.text) ?? 0;
    final subscriptionId = widget.item['id'] as String;

    setState(() => _saving = true);
    try {
      final repo = widget.ref.read(gymRepositoryProvider);
      await repo.updatePaymentStatusAndAmount(
        subscriptionId: subscriptionId,
        paymentStatus: _paymentStatus,
        amountPaid: newPaid,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment status updated successfully.')),
      );
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final memberName = (widget.item['members'] as Map<String, dynamic>? ?? const {})['full_name'] ?? 'Unknown';
    final planName = (widget.item['subscription_plans'] as Map<String, dynamic>? ?? const {})['name'] ?? '-';
    final remaining = _planPrice - _currentAmountPaid;

    return AlertDialog(
      title: const Text('Collect Fee'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              memberName.toString(),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Plan: $planName (Price: ₹${_planPrice.toStringAsFixed(0)})',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Remaining Due: ₹${remaining < 0 ? 0 : remaining.toStringAsFixed(0)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: remaining > 0 ? colorScheme.error : colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Amount Paid (₹)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                final amount = double.tryParse(val) ?? 0;
                _updateStatusFromAmount(amount);
              },
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Enter amount';
                if (double.tryParse(val) == null) return 'Enter valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentStatus,
              decoration: const InputDecoration(
                labelText: 'Payment Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'paid', child: Text('PAID')),
                DropdownMenuItem(value: 'partial', child: Text('PARTIAL')),
                DropdownMenuItem(value: 'due', child: Text('DUE')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _paymentStatus = val);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
