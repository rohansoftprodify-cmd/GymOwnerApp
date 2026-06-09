class ChurnRiskMember {
  const ChurnRiskMember({
    required this.memberId,
    required this.fullName,
    this.phone,
    required this.riskScore,
    required this.riskLevel,
    required this.reasons,
    this.suggestedAction,
  });

  final String memberId;
  final String fullName;
  final String? phone;
  final int riskScore;
  final String riskLevel;
  final List<String> reasons;
  final String? suggestedAction;

  factory ChurnRiskMember.fromMap(Map<String, dynamic> map) {
    final rawReasons = map['reasons'];
    return ChurnRiskMember(
      memberId: map['member_id'] as String,
      fullName: map['full_name'] as String? ?? 'Member',
      phone: map['phone'] as String?,
      riskScore: map['risk_score'] as int? ?? 0,
      riskLevel: map['risk_level'] as String? ?? 'low',
      reasons: rawReasons is List
          ? rawReasons.map((e) => e.toString()).toList()
          : const [],
      suggestedAction: map['suggested_action'] as String?,
    );
  }
}

class ChurnRiskSummary {
  const ChurnRiskSummary({
    this.high = 0,
    this.medium = 0,
    this.low = 0,
    this.totalAtRisk = 0,
  });

  final int high;
  final int medium;
  final int low;
  final int totalAtRisk;

  factory ChurnRiskSummary.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ChurnRiskSummary();
    return ChurnRiskSummary(
      high: map['high'] as int? ?? 0,
      medium: map['medium'] as int? ?? 0,
      low: map['low'] as int? ?? 0,
      totalAtRisk: map['total_at_risk'] as int? ?? 0,
    );
  }
}

class ChurnRiskResult {
  const ChurnRiskResult({
    required this.members,
    required this.summary,
  });

  final List<ChurnRiskMember> members;
  final ChurnRiskSummary summary;

  factory ChurnRiskResult.fromMap(Map<String, dynamic> map) {
    final rawMembers = map['members'] as List<dynamic>? ?? [];
    return ChurnRiskResult(
      members: rawMembers
          .map((e) => ChurnRiskMember.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      summary: ChurnRiskSummary.fromMap(
        map['summary'] is Map ? Map<String, dynamic>.from(map['summary'] as Map) : null,
      ),
    );
  }
}
