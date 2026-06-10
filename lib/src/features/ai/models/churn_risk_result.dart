class ChurnRiskMember {
  const ChurnRiskMember({
    required this.memberId,
    required this.fullName,
    this.phone,
    this.email,
    required this.riskScore,
    required this.riskLevel,
    this.leaveProbability30d = 0,
    this.alertMessage,
    required this.reasons,
    this.signals,
    this.suggestedAction,
    this.lastCheckInAt,
    this.paymentStatus,
    this.subscriptionEndDate,
  });

  final String memberId;
  final String fullName;
  final String? phone;
  final String? email;
  final int riskScore;
  final String riskLevel;
  final int leaveProbability30d;
  final String? alertMessage;
  final List<String> reasons;
  final RetentionSignals? signals;
  final String? suggestedAction;
  final String? lastCheckInAt;
  final String? paymentStatus;
  final String? subscriptionEndDate;

  String get displayAlert =>
      alertMessage ??
      '$fullName has $leaveProbability30d% probability of leaving within 30 days.';

  bool get isCritical => leaveProbability30d >= 75 || riskLevel == 'critical';

  factory ChurnRiskMember.fromMap(Map<String, dynamic> map) {
    final rawReasons = map['reasons'];
    return ChurnRiskMember(
      memberId: map['member_id'] as String,
      fullName: map['full_name'] as String? ?? 'Member',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      riskScore: map['risk_score'] as int? ?? 0,
      riskLevel: map['risk_level'] as String? ?? 'low',
      leaveProbability30d: map['leave_probability_30d'] as int? ?? map['risk_score'] as int? ?? 0,
      alertMessage: map['alert_message'] as String?,
      reasons: rawReasons is List
          ? rawReasons.map((e) => e.toString()).toList()
          : const [],
      signals: RetentionSignals.fromMap(
        map['signals'] is Map ? Map<String, dynamic>.from(map['signals'] as Map) : null,
      ),
      suggestedAction: map['suggested_action'] as String?,
      lastCheckInAt: map['last_check_in_at'] as String?,
      paymentStatus: map['payment_status'] as String?,
      subscriptionEndDate: map['subscription_end_date'] as String?,
    );
  }
}

class RetentionSignals {
  const RetentionSignals({
    this.attendance = const AttendanceSignal(),
    this.payment = const PaymentSignal(),
    this.engagement = const EngagementSignal(),
    this.renewal = const RenewalSignal(),
  });

  final AttendanceSignal attendance;
  final PaymentSignal payment;
  final EngagementSignal engagement;
  final RenewalSignal renewal;

  factory RetentionSignals.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const RetentionSignals();
    return RetentionSignals(
      attendance: AttendanceSignal.fromMap(
        map['attendance'] is Map ? Map<String, dynamic>.from(map['attendance'] as Map) : null,
      ),
      payment: PaymentSignal.fromMap(
        map['payment'] is Map ? Map<String, dynamic>.from(map['payment'] as Map) : null,
      ),
      engagement: EngagementSignal.fromMap(
        map['engagement'] is Map ? Map<String, dynamic>.from(map['engagement'] as Map) : null,
      ),
      renewal: RenewalSignal.fromMap(
        map['renewal'] is Map ? Map<String, dynamic>.from(map['renewal'] as Map) : null,
      ),
    );
  }
}

class AttendanceSignal {
  const AttendanceSignal({
    this.score = 0,
    this.checkInsLast30d = 0,
    this.checkInsPrior30d = 0,
    this.lastCheckInAt,
  });

  final int score;
  final int checkInsLast30d;
  final int checkInsPrior30d;
  final String? lastCheckInAt;

  factory AttendanceSignal.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AttendanceSignal();
    return AttendanceSignal(
      score: map['score'] as int? ?? 0,
      checkInsLast30d: map['check_ins_last_30d'] as int? ?? 0,
      checkInsPrior30d: map['check_ins_prior_30d'] as int? ?? 0,
      lastCheckInAt: map['last_check_in_at'] as String?,
    );
  }
}

class PaymentSignal {
  const PaymentSignal({this.score = 0, this.status});

  final int score;
  final String? status;

  factory PaymentSignal.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PaymentSignal();
    return PaymentSignal(
      score: map['score'] as int? ?? 0,
      status: map['status'] as String?,
    );
  }
}

class EngagementSignal {
  const EngagementSignal({
    this.score = 0,
    this.appCheckInsLast30d = 0,
    this.lastAppActivityAt,
  });

  final int score;
  final int appCheckInsLast30d;
  final String? lastAppActivityAt;

  factory EngagementSignal.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const EngagementSignal();
    return EngagementSignal(
      score: map['score'] as int? ?? 0,
      appCheckInsLast30d: map['app_check_ins_last_30d'] as int? ?? 0,
      lastAppActivityAt: map['last_app_activity_at'] as String?,
    );
  }
}

class RenewalSignal {
  const RenewalSignal({this.score = 0, this.subscriptionEndDate});

  final int score;
  final String? subscriptionEndDate;

  factory RenewalSignal.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const RenewalSignal();
    return RenewalSignal(
      score: map['score'] as int? ?? 0,
      subscriptionEndDate: map['subscription_end_date'] as String?,
    );
  }
}

class ChurnRiskSummary {
  const ChurnRiskSummary({
    this.critical = 0,
    this.high = 0,
    this.medium = 0,
    this.low = 0,
    this.totalAtRisk = 0,
  });

  final int critical;
  final int high;
  final int medium;
  final int low;
  final int totalAtRisk;

  factory ChurnRiskSummary.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ChurnRiskSummary();
    return ChurnRiskSummary(
      critical: map['critical'] as int? ?? 0,
      high: map['high'] as int? ?? 0,
      medium: map['medium'] as int? ?? 0,
      low: map['low'] as int? ?? 0,
      totalAtRisk: map['total_at_risk'] as int? ?? 0,
    );
  }
}

class ChurnRiskResult {
  const ChurnRiskResult({
    this.generatedAt,
    required this.members,
    required this.summary,
  });

  final DateTime? generatedAt;
  final List<ChurnRiskMember> members;
  final ChurnRiskSummary summary;

  factory ChurnRiskResult.fromMap(Map<String, dynamic> map) {
    final rawMembers = map['members'] as List<dynamic>? ?? [];
    return ChurnRiskResult(
      generatedAt: DateTime.tryParse(map['generated_at'] as String? ?? ''),
      members: rawMembers
          .map((e) => ChurnRiskMember.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      summary: ChurnRiskSummary.fromMap(
        map['summary'] is Map ? Map<String, dynamic>.from(map['summary'] as Map) : null,
      ),
    );
  }
}
