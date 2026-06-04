enum PromotionDisplayStatus {
  active,
  upcoming,
  expired,
  inactive;

  String get label {
    switch (this) {
      case PromotionDisplayStatus.active:
        return 'ACTIVE';
      case PromotionDisplayStatus.upcoming:
        return 'UPCOMING';
      case PromotionDisplayStatus.expired:
        return 'EXPIRED';
      case PromotionDisplayStatus.inactive:
        return 'INACTIVE';
    }
  }
}

class PromotionItem {
  PromotionItem({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.endAt,
    this.isActive = true,
  });

  final String? id;
  final String title;
  final String description;
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;

  factory PromotionItem.fromMap(Map<String, dynamic> map) {
    return PromotionItem(
      id: map['id'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      startAt: DateTime.parse(map['start_at'] as String).toLocal(),
      endAt: DateTime.parse(map['end_at'] as String).toLocal(),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  PromotionDisplayStatus displayStatus({DateTime? reference}) {
    final now = reference ?? DateTime.now();
    if (!isActive) return PromotionDisplayStatus.inactive;
    if (now.isBefore(startAt)) return PromotionDisplayStatus.upcoming;
    if (now.isAfter(endAt)) return PromotionDisplayStatus.expired;
    return PromotionDisplayStatus.active;
  }

  Map<String, dynamic> toOfferMap() => {
        'id': id,
        'title': title,
        'description': description,
        'start_at': startAt.toUtc().toIso8601String(),
        'end_at': endAt.toUtc().toIso8601String(),
        'is_active': isActive,
      };
}
