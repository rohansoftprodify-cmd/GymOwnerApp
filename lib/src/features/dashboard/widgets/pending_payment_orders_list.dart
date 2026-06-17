import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:intl/intl.dart';

class PendingPaymentOrdersList extends StatelessWidget {
  const PendingPaymentOrdersList({
    super.key,
    required this.orders,
    required this.onConfirm,
    required this.onReject,
    this.processingOrderId,
  });

  final List<Map<String, dynamic>> orders;
  final Future<void> Function(String orderId) onConfirm;
  final Future<void> Function(String orderId) onReject;
  final String? processingOrderId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;

    if (orders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: semantics.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
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
              'No pending payments.',
              style: theme.textTheme.labelMedium?.copyWith(color: semantics.mutedText),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _PendingOrderCard(
          order: orders[i],
          onConfirm: onConfirm,
          onReject: onReject,
          isProcessing: processingOrderId == orders[i]['id'],
        ),
      ),
    );
  }
}

class _PendingOrderCard extends StatelessWidget {
  const _PendingOrderCard({
    required this.order,
    required this.onConfirm,
    required this.onReject,
    required this.isProcessing,
  });

  final Map<String, dynamic> order;
  final Future<void> Function(String orderId) onConfirm;
  final Future<void> Function(String orderId) onReject;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;
    final orderId = order['id'] as String;
    final memberName =
        (order['members'] as Map<String, dynamic>? ?? const {})['full_name'] as String? ??
        'Member';
    final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '')?.toLocal();
    final timeLabel = createdAt == null ? '—' : DateFormat.jm().format(createdAt);
    final itemSummary = itemSummaryForOrder(order);

    return SizedBox(
      width: 300,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: semantics.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_actions_rounded, size: 18, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    memberName,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '₹${NumberFormat('#,##0').format(amount.round())}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              itemSummary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              'Submitted $timeLabel',
              style: theme.textTheme.labelSmall?.copyWith(
                color: semantics.mutedText,
                fontSize: 10,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isProcessing ? null : () => onReject(orderId),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: semantics.accentCoral,
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: isProcessing ? null : () => onConfirm(orderId),
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirm'),
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

String itemSummaryForOrder(Map<String, dynamic> order) {
  final itemsRaw = order['sales_order_items'];
  if (itemsRaw is! List || itemsRaw.isEmpty) return 'Store order';

  final labels = <String>[];
  for (final item in itemsRaw) {
    if (item is! Map) continue;
    final itemMap = Map<String, dynamic>.from(item);
    final qty = itemMap['qty'] as int? ?? 1;
    final product = itemMap['products'];
    final productName = product is Map
        ? product['name'] as String? ?? 'Product'
        : 'Product';
    labels.add('$qty× $productName');
  }
  return labels.join(' · ');
}

class PendingOrderListTile extends StatelessWidget {
  const PendingOrderListTile({
    super.key,
    required this.order,
    required this.onConfirm,
    required this.onReject,
    this.isProcessing = false,
  });

  final Map<String, dynamic> order;
  final Future<void> Function(String orderId) onConfirm;
  final Future<void> Function(String orderId) onReject;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;
    final orderId = order['id'] as String;
    final memberName =
        (order['members'] as Map<String, dynamic>? ?? const {})['full_name'] as String? ??
        'Member';
    final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '')?.toLocal();
    final timeLabel = createdAt == null ? '—' : DateFormat.yMMMd().add_jm().format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  memberName,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '₹${NumberFormat('#,##0').format(amount.round())}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            itemSummaryForOrder(order),
            style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
          ),
          const SizedBox(height: 4),
          Text(
            timeLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: semantics.mutedText,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing ? null : () => onReject(orderId),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: isProcessing ? null : () => onConfirm(orderId),
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirm payment'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
