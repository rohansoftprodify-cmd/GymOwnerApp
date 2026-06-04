class SubscriptionPlanItem {
  SubscriptionPlanItem({
    required this.id,
    required this.name,
    required this.durationDays,
    required this.price,
    this.description,
    this.isActive = true,
  });

  final String? id;
  final String name;
  final String? description;
  final int durationDays;
  final double price;
  final bool isActive;

  factory SubscriptionPlanItem.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlanItem(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      durationDays: map['duration_days'] as int? ?? 30,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  String durationLabel() {
    if (durationDays >= 365 && durationDays % 365 == 0) {
      final years = durationDays ~/ 365;
      return years == 1 ? '1 year' : '$years years';
    }
    if (durationDays >= 30 && durationDays % 30 == 0) {
      final months = durationDays ~/ 30;
      return months == 1 ? '1 month' : '$months months';
    }
    return durationDays == 1 ? '1 day' : '$durationDays days';
  }
}

String currencySymbol(String? currencyCode) {
  switch (currencyCode?.toUpperCase()) {
    case 'INR':
      return '₹';
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    default:
      return '₹';
  }
}
