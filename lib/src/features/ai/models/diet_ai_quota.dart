class DietAiQuota {
  const DietAiQuota({
    required this.used,
    required this.limit,
    required this.remaining,
    this.month,
  });

  final int used;
  final int limit;
  final int remaining;
  final String? month;

  factory DietAiQuota.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const DietAiQuota(used: 0, limit: 5, remaining: 5);
    }
    return DietAiQuota(
      used: map['used'] as int? ?? 0,
      limit: map['limit'] as int? ?? 5,
      remaining: map['remaining'] as int? ?? 0,
      month: map['month'] as String?,
    );
  }
}
