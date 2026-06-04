class MemberListItem {
  MemberListItem({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    required this.status,
    required this.joinedOn,
    this.hasLogin = false,
    this.planName,
    this.endDate,
    this.paymentStatus,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String status;
  final DateTime? joinedOn;
  final bool hasLogin;
  final String? planName;
  final DateTime? endDate;
  final String? paymentStatus;

  factory MemberListItem.fromMap(Map<String, dynamic> map) {
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

    final plan = activeSub?['subscription_plans'] as Map<String, dynamic>?;
    final endRaw = activeSub?['end_date'] as String?;

    return MemberListItem(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String?,
      status: map['status'] as String? ?? 'active',
      joinedOn: _parseDate(map['joined_on'] as String?),
      hasLogin: map['user_id'] != null,
      planName: plan?['name'] as String?,
      endDate: _parseDate(endRaw),
      paymentStatus: activeSub?['payment_status'] as String?,
    );
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
