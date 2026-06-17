import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/features/transactions/models/transaction_history_item.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.item,
    this.onConfirmPayment,
    this.onRejectPayment,
    this.isProcessing = false,
  });

  final TransactionHistoryItem item;
  final Future<void> Function(String orderId)? onConfirmPayment;
  final Future<void> Function(String orderId)? onRejectPayment;
  final bool isProcessing;

  bool get _isPendingStoreOrder =>
      item.kind == TransactionKind.storeSale &&
      (item.paymentStatus?.toLowerCase() == 'pending');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final colorScheme = theme.colorScheme;
    final isStore = item.kind == TransactionKind.storeSale;
    final accent = isStore ? colorScheme.secondary : colorScheme.primary;
    final time = DateFormat.jm().format(item.occurredAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isStore ? Icons.storefront_rounded : Icons.card_membership_rounded,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      _money(item.amount),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _TypeChip(
                      label: isStore ? 'Store' : 'Membership',
                      color: accent,
                    ),
                    if (_shouldShowPaymentStatus(item)) ...[
                      const SizedBox(width: 6),
                      _TypeChip(
                        label: _paymentStatusLabel(item),
                        color: _paymentColor(item.paymentStatus!, semantics),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: semantics.mutedText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                if (item.memberName != null && item.memberName!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 14, color: semantics.mutedText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.memberName!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: semantics.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: semantics.mutedText,
                      height: 1.3,
                    ),
                  ),
                ],
                if (_isPendingStoreOrder &&
                    onConfirmPayment != null &&
                    onRejectPayment != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isProcessing ? null : () => onRejectPayment!(item.id),
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
                          onPressed: isProcessing ? null : () => onConfirmPayment!(item.id),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _money(double value) => '₹${NumberFormat('#,##0').format(value.round())}';

  static bool _shouldShowPaymentStatus(TransactionHistoryItem item) {
    final status = item.paymentStatus?.toLowerCase();
    if (status == null) return false;
    if (item.kind == TransactionKind.membership) return true;
    return status == 'pending' || status == 'rejected';
  }

  static String _paymentStatusLabel(TransactionHistoryItem item) {
    final status = item.paymentStatus!.toLowerCase();
    return switch (status) {
      'pending' => 'AWAITING',
      'confirmed' => 'CONFIRMED',
      _ => item.paymentStatus!.toUpperCase(),
    };
  }

  static Color _paymentColor(String status, AppSemanticColors semantics) {
    return switch (status.toLowerCase()) {
      'paid' || 'confirmed' => Colors.green.shade700,
      'partial' => Colors.orange.shade700,
      'pending' => Colors.orange.shade800,
      'rejected' => semantics.accentCoral,
      _ => semantics.accentCoral,
    };
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
