enum TransactionKind { storeSale, membership }

class TransactionHistoryItem {
  const TransactionHistoryItem({
    required this.id,
    required this.kind,
    required this.occurredAt,
    required this.amount,
    required this.title,
    this.subtitle,
    this.memberName,
    this.paymentStatus,
  });

  final String id;
  final TransactionKind kind;
  final DateTime occurredAt;
  final double amount;
  final String title;
  final String? subtitle;
  final String? memberName;
  final String? paymentStatus;

  factory TransactionHistoryItem.storeSale(Map<String, dynamic> row) {
    final member = row['members'];
    final memberMap = member is Map ? Map<String, dynamic>.from(member) : null;
    final memberName = memberMap?['full_name'] as String?;

    final itemsRaw = row['sales_order_items'];
    final itemLabels = <String>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is! Map) continue;
        final itemMap = Map<String, dynamic>.from(item);
        final qty = itemMap['qty'] as int? ?? 1;
        final product = itemMap['products'];
        final productName = product is Map
            ? product['name'] as String? ?? 'Product'
            : 'Product';
        itemLabels.add('$qty× $productName');
      }
    }

    return TransactionHistoryItem(
      id: row['id'] as String,
      kind: TransactionKind.storeSale,
      occurredAt: DateTime.parse(row['created_at'] as String).toLocal(),
      amount: (row['total_amount'] as num?)?.toDouble() ?? 0,
      title: 'Store sale',
      subtitle: itemLabels.isEmpty ? null : itemLabels.join(' · '),
      memberName: memberName,
    );
  }

  factory TransactionHistoryItem.membership(Map<String, dynamic> row) {
    final member = row['members'];
    final memberMap = member is Map ? Map<String, dynamic>.from(member) : null;
    final plan = row['subscription_plans'];
    final planMap = plan is Map ? Map<String, dynamic>.from(plan) : null;
    final planName = planMap?['name'] as String? ?? 'Membership plan';
    final planPrice = (planMap?['price'] as num?)?.toDouble();

    return TransactionHistoryItem(
      id: row['id'] as String,
      kind: TransactionKind.membership,
      occurredAt: DateTime.parse(row['created_at'] as String).toLocal(),
      amount: (row['amount_paid'] as num?)?.toDouble() ?? 0,
      title: planName,
      subtitle: planPrice != null ? 'Plan value ₹${planPrice.round()}' : null,
      memberName: memberMap?['full_name'] as String?,
      paymentStatus: row['payment_status'] as String?,
    );
  }
}
