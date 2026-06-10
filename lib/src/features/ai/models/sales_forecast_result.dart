class SalesForecastResult {
  const SalesForecastResult({
    this.generatedAt,
    this.forecastMonths = 3,
    required this.summary,
    required this.overview,
    required this.monthlyHistory,
    required this.monthlyForecast,
    required this.renewals,
    required this.churn,
    required this.staffingHints,
    required this.insights,
  });

  final DateTime? generatedAt;
  final int forecastMonths;
  final String summary;
  final SalesForecastOverview overview;
  final List<MonthlyRevenueStat> monthlyHistory;
  final List<MonthlyForecastStat> monthlyForecast;
  final RenewalsForecast renewals;
  final ChurnForecast churn;
  final StaffingHints staffingHints;
  final List<String> insights;

  factory SalesForecastResult.fromMap(Map<String, dynamic> map) {
    final rawInsights = map['insights'] as List<dynamic>? ?? [];
    return SalesForecastResult(
      generatedAt: DateTime.tryParse(map['generated_at'] as String? ?? ''),
      forecastMonths: map['forecast_months'] as int? ?? 3,
      summary: map['summary'] as String? ?? '',
      overview: SalesForecastOverview.fromMap(
        map['overview'] is Map ? Map<String, dynamic>.from(map['overview'] as Map) : null,
      ),
      monthlyHistory: _parseList(map['monthly_history'], MonthlyRevenueStat.fromMap),
      monthlyForecast: _parseList(map['monthly_forecast'], MonthlyForecastStat.fromMap),
      renewals: RenewalsForecast.fromMap(
        map['renewals'] is Map ? Map<String, dynamic>.from(map['renewals'] as Map) : null,
      ),
      churn: ChurnForecast.fromMap(
        map['churn'] is Map ? Map<String, dynamic>.from(map['churn'] as Map) : null,
      ),
      staffingHints: StaffingHints.fromMap(
        map['staffing_hints'] is Map ? Map<String, dynamic>.from(map['staffing_hints'] as Map) : null,
      ),
      insights: rawInsights.map((e) => e.toString()).where((s) => s.isNotEmpty).toList(),
    );
  }
}

class SalesForecastOverview {
  const SalesForecastOverview({
    this.activeMembers = 0,
    this.activeSubscriptions = 0,
    this.estimatedMrr = 0,
    this.pendingDues = 0,
    this.historicalRenewalRatePercent = 70,
    this.recentChurnRatePercent = 0,
    this.projectedChurnRatePercent = 0,
    this.atRiskMembers = 0,
  });

  final int activeMembers;
  final int activeSubscriptions;
  final double estimatedMrr;
  final double pendingDues;
  final double historicalRenewalRatePercent;
  final double recentChurnRatePercent;
  final double projectedChurnRatePercent;
  final int atRiskMembers;

  factory SalesForecastOverview.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SalesForecastOverview();
    return SalesForecastOverview(
      activeMembers: map['active_members'] as int? ?? 0,
      activeSubscriptions: map['active_subscriptions'] as int? ?? 0,
      estimatedMrr: (map['estimated_mrr'] as num?)?.toDouble() ?? 0,
      pendingDues: (map['pending_dues'] as num?)?.toDouble() ?? 0,
      historicalRenewalRatePercent:
          (map['historical_renewal_rate_percent'] as num?)?.toDouble() ?? 70,
      recentChurnRatePercent: (map['recent_churn_rate_percent'] as num?)?.toDouble() ?? 0,
      projectedChurnRatePercent:
          (map['projected_churn_rate_percent'] as num?)?.toDouble() ?? 0,
      atRiskMembers: map['at_risk_members'] as int? ?? 0,
    );
  }
}

class MonthlyRevenueStat {
  const MonthlyRevenueStat({
    required this.monthKey,
    required this.monthLabel,
    this.membershipRevenue = 0,
    this.newSubscriptions = 0,
    this.storeRevenue = 0,
    this.totalRevenue = 0,
  });

  final String monthKey;
  final String monthLabel;
  final double membershipRevenue;
  final int newSubscriptions;
  final double storeRevenue;
  final double totalRevenue;

  factory MonthlyRevenueStat.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const MonthlyRevenueStat(monthKey: '', monthLabel: '—');
    }
    return MonthlyRevenueStat(
      monthKey: map['month_key'] as String? ?? '',
      monthLabel: map['month_label'] as String? ?? '—',
      membershipRevenue: (map['membership_revenue'] as num?)?.toDouble() ?? 0,
      newSubscriptions: map['new_subscriptions'] as int? ?? 0,
      storeRevenue: (map['store_revenue'] as num?)?.toDouble() ?? 0,
      totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MonthlyForecastStat {
  const MonthlyForecastStat({
    required this.monthKey,
    required this.monthLabel,
    this.predictedMembershipRevenue = 0,
    this.predictedRenewalRevenue = 0,
    this.confidence = 'low',
  });

  final String monthKey;
  final String monthLabel;
  final double predictedMembershipRevenue;
  final double predictedRenewalRevenue;
  final String confidence;

  double get predictedTotal => predictedMembershipRevenue + predictedRenewalRevenue;

  factory MonthlyForecastStat.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const MonthlyForecastStat(monthKey: '', monthLabel: '—');
    }
    return MonthlyForecastStat(
      monthKey: map['month_key'] as String? ?? '',
      monthLabel: map['month_label'] as String? ?? '—',
      predictedMembershipRevenue:
          (map['predicted_membership_revenue'] as num?)?.toDouble() ?? 0,
      predictedRenewalRevenue:
          (map['predicted_renewal_revenue'] as num?)?.toDouble() ?? 0,
      confidence: map['confidence'] as String? ?? 'low',
    );
  }
}

class RenewalWindowStat {
  const RenewalWindowStat({
    this.count = 0,
    this.expectedRevenue = 0,
    this.fullPotentialRevenue = 0,
    this.atRiskCount = 0,
  });

  final int count;
  final double expectedRevenue;
  final double fullPotentialRevenue;
  final int atRiskCount;

  factory RenewalWindowStat.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const RenewalWindowStat();
    return RenewalWindowStat(
      count: map['count'] as int? ?? 0,
      expectedRevenue: (map['expected_revenue'] as num?)?.toDouble() ?? 0,
      fullPotentialRevenue: (map['full_potential_revenue'] as num?)?.toDouble() ?? 0,
      atRiskCount: map['at_risk_count'] as int? ?? 0,
    );
  }
}

class UpcomingRenewal {
  const UpcomingRenewal({
    required this.memberId,
    required this.fullName,
    required this.planName,
    this.planPrice = 0,
    this.endDate,
    this.paymentStatus,
    this.renewalLikelihood = 'medium',
  });

  final String memberId;
  final String fullName;
  final String planName;
  final double planPrice;
  final String? endDate;
  final String? paymentStatus;
  final String renewalLikelihood;

  factory UpcomingRenewal.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const UpcomingRenewal(memberId: '', fullName: 'Member', planName: '—');
    }
    return UpcomingRenewal(
      memberId: map['member_id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? 'Member',
      planName: map['plan_name'] as String? ?? '—',
      planPrice: (map['plan_price'] as num?)?.toDouble() ?? 0,
      endDate: map['end_date'] as String?,
      paymentStatus: map['payment_status'] as String?,
      renewalLikelihood: map['renewal_likelihood'] as String? ?? 'medium',
    );
  }
}

class RenewalsForecast {
  const RenewalsForecast({
    this.historicalRenewalRatePercent = 70,
    this.next30Days = const RenewalWindowStat(),
    this.next60Days = const RenewalWindowStat(),
    this.upcoming = const [],
  });

  final double historicalRenewalRatePercent;
  final RenewalWindowStat next30Days;
  final RenewalWindowStat next60Days;
  final List<UpcomingRenewal> upcoming;

  factory RenewalsForecast.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const RenewalsForecast();
    return RenewalsForecast(
      historicalRenewalRatePercent:
          (map['historical_renewal_rate_percent'] as num?)?.toDouble() ?? 70,
      next30Days: RenewalWindowStat.fromMap(
        map['next_30_days'] is Map
            ? Map<String, dynamic>.from(map['next_30_days'] as Map)
            : null,
      ),
      next60Days: RenewalWindowStat.fromMap(
        map['next_60_days'] is Map
            ? Map<String, dynamic>.from(map['next_60_days'] as Map)
            : null,
      ),
      upcoming: _parseList(map['upcoming'], UpcomingRenewal.fromMap),
    );
  }
}

class ChurnForecast {
  const ChurnForecast({
    this.recentChurnRatePercent = 0,
    this.projectedNextMonthPercent = 0,
    this.membersChurnedLast30Days = 0,
    this.atRiskActiveMembers = 0,
    this.expiredNotRenewed90d = 0,
  });

  final double recentChurnRatePercent;
  final double projectedNextMonthPercent;
  final int membersChurnedLast30Days;
  final int atRiskActiveMembers;
  final int expiredNotRenewed90d;

  factory ChurnForecast.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ChurnForecast();
    return ChurnForecast(
      recentChurnRatePercent: (map['recent_churn_rate_percent'] as num?)?.toDouble() ?? 0,
      projectedNextMonthPercent:
          (map['projected_next_month_percent'] as num?)?.toDouble() ?? 0,
      membersChurnedLast30Days: map['members_churned_last_30_days'] as int? ?? 0,
      atRiskActiveMembers: map['at_risk_active_members'] as int? ?? 0,
      expiredNotRenewed90d: map['expired_not_renewed_90d'] as int? ?? 0,
    );
  }
}

class StaffingHints {
  const StaffingHints({
    this.marketingFocus = 'growth',
    this.priority = 'normal',
  });

  final String marketingFocus;
  final String priority;

  String get marketingFocusLabel => switch (marketingFocus) {
        'renewal_campaign' => 'Renewal campaign',
        'retention_outreach' => 'Retention outreach',
        'win_back' => 'Win-back campaign',
        _ => 'Growth',
      };

  factory StaffingHints.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const StaffingHints();
    return StaffingHints(
      marketingFocus: map['marketing_focus'] as String? ?? 'growth',
      priority: map['priority'] as String? ?? 'normal',
    );
  }
}

List<T> _parseList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>?) fromMap,
) {
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((item) => fromMap(Map<String, dynamic>.from(item)))
      .toList();
}
