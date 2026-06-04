import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/domain/report_calculations.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/exclusive_offer_card.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/fee_horizontal_list.dart';
import 'package:intl/intl.dart';

void showFeeListSheet(
  BuildContext context,
  List<Map<String, dynamic>> items,
  String title, {
  FeeListMode mode = FeeListMode.pendingFees,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No records found'))
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final member =
                            (item['members'] as Map<String, dynamic>? ??
                                const {})['full_name'] ??
                            'Unknown';
                        final plan =
                            (item['subscription_plans']
                                    as Map<String, dynamic>? ??
                                const {})['name'] ??
                            '-';
                        final semantics = context.appColors;
                        final planPrice =
                            ((item['subscription_plans']
                                        as Map<String, dynamic>?)?['price']
                                    as num?)
                                ?.toDouble() ??
                            0;
                        final amountPaid =
                            (item['amount_paid'] as num?)?.toDouble() ?? 0;
                        final remaining = pendingAmount(
                          planPrice: planPrice,
                          amountPaid: amountPaid,
                        );
                        final status =
                            (item['payment_status'] as String? ?? '-')
                                .toUpperCase();
                        final isPending =
                            status == 'DUE' || status == 'PARTIAL';
                        final isRenewals = mode == FeeListMode.renewals;
                        final daysLeft =
                            renewalDaysLeft(item['end_date'] as String?);
                        final daysLabel = renewalDaysLabel(daysLeft);

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: semantics.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                child: Text(
                                  member[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      '$plan • Exp: ${item['end_date'] != null ? DateFormat.yMMMd().format(DateTime.parse(item['end_date'])) : '-'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isRenewals)
                                    Text(
                                      daysLabel,
                                      style: TextStyle(
                                        color: semantics.accentLime,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    )
                                  else ...[
                                    if (isPending)
                                      Text(
                                        '₹${remaining.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        color: isPending
                                            ? semantics.accentCoral
                                            : Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showPromotionsSheet(
  BuildContext context,
  List<Map<String, dynamic>> promotions,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(  
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exclusive Offers',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: promotions.isEmpty
                  ? const Center(child: Text('No promotions added yet'))
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: promotions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (_, i) {
                        return ExclusiveOfferCard(offer: promotions[i]);
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
