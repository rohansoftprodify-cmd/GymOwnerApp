import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/domain/report_calculations.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:intl/intl.dart';

enum FeeListMode { pendingFees, renewals }

class FeeHorizontalList extends StatelessWidget {
  const FeeHorizontalList({
    super.key,
    required this.items,
    required this.emptyText,
    this.mode = FeeListMode.pendingFees,
  });

  final List<Map<String, dynamic>> items;
  final String emptyText;
  final FeeListMode mode;

  @override
  Widget build(BuildContext context) {
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

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final item = items[i];
          if (mode == FeeListMode.renewals) {
            return _RenewalCard(item: item);
          }
          return _PendingFeeCard(item: item);
        },
      ),
    );
  }
}

class _PendingFeeCard extends StatelessWidget {
  const _PendingFeeCard({required this.item});

  final Map<String, dynamic> item;

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
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Notify',
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
  const _RenewalCard({required this.item});

  final Map<String, dynamic> item;

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

    return SizedBox(
      width: 260,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: semantics.cardBackground,
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
              child: Text(
                member.toString().trim().isEmpty
                    ? '?'
                    : member.toString()[0].toUpperCase(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
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
    );
  }
}
