class MemberSubscriptionDetail {
  MemberSubscriptionDetail({
    this.id,
    required this.planId,
    required this.planName,
    required this.planPrice,
    required this.durationDays,
    required this.startDate,
    required this.endDate,
    required this.paymentStatus,
    required this.amountPaid,
    required this.status,
  });

  final String? id;
  final String planId;
  final String planName;
  final double planPrice;
  final int durationDays;
  final DateTime startDate;
  final DateTime endDate;
  final String paymentStatus;
  final double amountPaid;
  final String status;

  factory MemberSubscriptionDetail.fromMap(Map<String, dynamic> map) {
    final plan = map['subscription_plans'] as Map<String, dynamic>? ?? const {};
    return MemberSubscriptionDetail(
      id: map['id'] as String?,
      planId: map['plan_id'] as String? ?? plan['id'] as String? ?? '',
      planName: plan['name'] as String? ?? '-',
      planPrice: (plan['price'] as num?)?.toDouble() ?? 0,
      durationDays: plan['duration_days'] as int? ?? 30,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      paymentStatus: map['payment_status'] as String? ?? 'due',
      amountPaid: (map['amount_paid'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'active',
    );
  }
}

class MemberDetail {
  MemberDetail({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.status,
    this.joinedOn,
    this.hasLogin = false,
    this.dateOfBirth,
    this.emergencyContact,
    this.notes,
    this.activeSubscription,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String status;
  final DateTime? joinedOn;
  final bool hasLogin;
  final DateTime? dateOfBirth;
  final String? emergencyContact;
  final String? notes;
  final MemberSubscriptionDetail? activeSubscription;

  factory MemberDetail.fromMap(Map<String, dynamic> map) {
    final subs = (map['member_subscriptions'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    subs.sort((a, b) {
      final aEnd = a['end_date'] as String? ?? '';
      final bEnd = b['end_date'] as String? ?? '';
      return bEnd.compareTo(aEnd);
    });

    Map<String, dynamic>? activeSub;
    for (final sub in subs) {
      if ((sub['status'] as String? ?? 'active') == 'active') {
        activeSub = sub;
        break;
      }
    }
    activeSub ??= subs.isNotEmpty ? subs.first : null;

    return MemberDetail(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String?,
      status: map['status'] as String? ?? 'active',
      joinedOn: _parseDate(map['joined_on'] as String?),
      hasLogin: map['user_id'] != null,
      dateOfBirth: _parseDate(map['date_of_birth'] as String?),
      emergencyContact: map['emergency_contact'] as String?,
      notes: map['notes'] as String?,
      activeSubscription:
          activeSub == null ? null : MemberSubscriptionDetail.fromMap(activeSub),
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
