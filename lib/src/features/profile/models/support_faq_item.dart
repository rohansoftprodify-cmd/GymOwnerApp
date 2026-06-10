class SupportFaqCategory {
  SupportFaqCategory._();

  static const gymTimings = 'gym_timings';
  static const membershipPlans = 'membership_plans';
  static const trainerAvailability = 'trainer_availability';
  static const dietQueries = 'diet_queries';
  static const general = 'general';

  static const all = [
    gymTimings,
    membershipPlans,
    trainerAvailability,
    dietQueries,
    general,
  ];

  static String label(String key) => switch (key) {
        gymTimings => 'Gym timings',
        membershipPlans => 'Membership plans',
        trainerAvailability => 'Trainer availability',
        dietQueries => 'Diet queries',
        _ => 'General',
      };
}

class SupportFaqItem {
  const SupportFaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String category;
  final String question;
  final String answer;
  final int sortOrder;
  final bool isActive;

  factory SupportFaqItem.fromMap(Map<String, dynamic> map) {
    return SupportFaqItem(
      id: map['id'] as String,
      category: map['category'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
