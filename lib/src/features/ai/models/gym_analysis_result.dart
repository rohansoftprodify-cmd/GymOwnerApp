class GymAnalysisResult {
  const GymAnalysisResult({
    this.generatedAt,
    required this.periodMonths,
    required this.summary,
    required this.membership,
    required this.sales,
    required this.attendance,
    required this.members,
    required this.insights,
  });

  final DateTime? generatedAt;
  final int periodMonths;
  final String summary;
  final GymMembershipAnalysis membership;
  final GymSalesAnalysis sales;
  final GymAttendanceAnalysis attendance;
  final GymMembersAnalysis members;
  final List<String> insights;

  factory GymAnalysisResult.fromMap(Map<String, dynamic> map) {
    final rawInsights = map['insights'] as List<dynamic>? ?? [];
    return GymAnalysisResult(
      generatedAt: DateTime.tryParse(map['generated_at'] as String? ?? ''),
      periodMonths: map['period_months'] as int? ?? 12,
      summary: map['summary'] as String? ?? '',
      membership: GymMembershipAnalysis.fromMap(
        map['membership'] is Map ? Map<String, dynamic>.from(map['membership'] as Map) : null,
      ),
      sales: GymSalesAnalysis.fromMap(
        map['sales'] is Map ? Map<String, dynamic>.from(map['sales'] as Map) : null,
      ),
      attendance: GymAttendanceAnalysis.fromMap(
        map['attendance'] is Map ? Map<String, dynamic>.from(map['attendance'] as Map) : null,
      ),
      members: GymMembersAnalysis.fromMap(
        map['members'] is Map ? Map<String, dynamic>.from(map['members'] as Map) : null,
      ),
      insights: rawInsights.map((e) => e.toString()).toList(),
    );
  }
}

class GymMembershipAnalysis {
  const GymMembershipAnalysis({
    this.joinedInPeriod = 0,
    this.leftInPeriod = 0,
    this.netChange = 0,
    this.activeNow = 0,
    this.inactiveTotal = 0,
    this.peakJoinMonth,
    this.monthlyJoins = const [],
  });

  final int joinedInPeriod;
  final int leftInPeriod;
  final int netChange;
  final int activeNow;
  final int inactiveTotal;
  final GymMonthStat? peakJoinMonth;
  final List<GymMonthJoinStat> monthlyJoins;

  factory GymMembershipAnalysis.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GymMembershipAnalysis();
    return GymMembershipAnalysis(
      joinedInPeriod: map['joined_in_period'] as int? ?? 0,
      leftInPeriod: map['left_in_period'] as int? ?? 0,
      netChange: map['net_change'] as int? ?? 0,
      activeNow: map['active_now'] as int? ?? 0,
      inactiveTotal: map['inactive_total'] as int? ?? 0,
      peakJoinMonth: GymMonthStat.fromMap(map['peak_join_month']),
      monthlyJoins: _parseList(map['monthly_joins'], GymMonthJoinStat.fromMap),
    );
  }
}

class GymSalesAnalysis {
  const GymSalesAnalysis({
    this.totalRevenue = 0,
    this.totalOrders = 0,
    this.peakSalesMonth,
    this.topProducts = const [],
    this.monthlySales = const [],
  });

  final double totalRevenue;
  final int totalOrders;
  final GymSalesMonthStat? peakSalesMonth;
  final List<GymTopProduct> topProducts;
  final List<GymSalesMonthStat> monthlySales;

  factory GymSalesAnalysis.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GymSalesAnalysis();
    return GymSalesAnalysis(
      totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0,
      totalOrders: map['total_orders'] as int? ?? 0,
      peakSalesMonth: GymSalesMonthStat.fromMap(map['peak_sales_month']),
      topProducts: _parseList(map['top_products'], GymTopProduct.fromMap),
      monthlySales: _parseList(
        map['monthly_sales'],
        (m) => GymSalesMonthStat.fromMap(m) ?? const GymSalesMonthStat(),
      ),
    );
  }
}

class GymAttendanceAnalysis {
  const GymAttendanceAnalysis({
    this.totalCheckIns = 0,
    this.preferredMethod,
    this.methods = const [],
    this.peakMonth,
  });

  final int totalCheckIns;
  final GymAttendanceMethod? preferredMethod;
  final List<GymAttendanceMethod> methods;
  final GymAttendanceMonthStat? peakMonth;

  factory GymAttendanceAnalysis.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GymAttendanceAnalysis();
    return GymAttendanceAnalysis(
      totalCheckIns: map['total_check_ins'] as int? ?? 0,
      preferredMethod: GymAttendanceMethod.fromMap(map['preferred_method']),
      methods: _parseList(
        map['methods'],
        (m) => GymAttendanceMethod.fromMap(m) ??
            const GymAttendanceMethod(method: 'legacy', label: 'Unknown'),
      ),
      peakMonth: GymAttendanceMonthStat.fromMap(map['peak_month']),
    );
  }
}

class GymMembersAnalysis {
  const GymMembersAnalysis({
    this.mostConsistent = const [],
    this.oldestMember,
    this.longestTenure = const [],
  });

  final List<GymConsistentMember> mostConsistent;
  final GymTenureMember? oldestMember;
  final List<GymTenureMember> longestTenure;

  factory GymMembersAnalysis.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GymMembersAnalysis();
    return GymMembersAnalysis(
      mostConsistent: _parseList(map['most_consistent'], GymConsistentMember.fromMap),
      oldestMember: GymTenureMember.fromMap(map['oldest_member']),
      longestTenure: _parseList(
        map['longest_tenure'],
        (m) => GymTenureMember.fromMap(m) ??
            const GymTenureMember(memberId: '', fullName: 'Member'),
      ),
    );
  }
}

class GymMonthStat {
  const GymMonthStat({this.monthKey, this.monthLabel, this.joinedCount});

  final String? monthKey;
  final String? monthLabel;
  final int? joinedCount;

  static GymMonthStat? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return GymMonthStat(
      monthKey: map['month_key'] as String?,
      monthLabel: map['month_label'] as String?,
      joinedCount: map['joined_count'] as int?,
    );
  }
}

class GymMonthJoinStat {
  const GymMonthJoinStat({this.monthKey, this.monthLabel, this.joinedCount = 0});

  final String? monthKey;
  final String? monthLabel;
  final int joinedCount;

  static GymMonthJoinStat fromMap(Map<String, dynamic> map) {
    return GymMonthJoinStat(
      monthKey: map['month_key'] as String?,
      monthLabel: map['month_label'] as String?,
      joinedCount: map['joined_count'] as int? ?? 0,
    );
  }
}

class GymSalesMonthStat {
  const GymSalesMonthStat({
    this.monthKey,
    this.monthLabel,
    this.salesTotal = 0,
    this.orderCount = 0,
  });

  final String? monthKey;
  final String? monthLabel;
  final double salesTotal;
  final int orderCount;

  static GymSalesMonthStat? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return GymSalesMonthStat(
      monthKey: map['month_key'] as String?,
      monthLabel: map['month_label'] as String?,
      salesTotal: (map['sales_total'] as num?)?.toDouble() ?? 0,
      orderCount: map['order_count'] as int? ?? 0,
    );
  }

}

class GymTopProduct {
  const GymTopProduct({
    required this.productId,
    required this.name,
    this.qtySold = 0,
    this.revenue = 0,
  });

  final String? productId;
  final String name;
  final int qtySold;
  final double revenue;

  static GymTopProduct fromMap(Map<String, dynamic> map) {
    return GymTopProduct(
      productId: map['product_id'] as String?,
      name: map['name'] as String? ?? 'Product',
      qtySold: map['qty_sold'] as int? ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GymAttendanceMethod {
  const GymAttendanceMethod({
    required this.method,
    required this.label,
    this.count = 0,
    this.percent = 0,
  });

  final String method;
  final String label;
  final int count;
  final double percent;

  static GymAttendanceMethod? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return GymAttendanceMethod(
      method: map['method'] as String? ?? 'legacy',
      label: map['label'] as String? ?? 'Unknown',
      count: map['count'] as int? ?? 0,
      percent: (map['percent'] as num?)?.toDouble() ?? 0,
    );
  }

}

class GymAttendanceMonthStat {
  const GymAttendanceMonthStat({this.monthKey, this.monthLabel, this.checkIns = 0});

  final String? monthKey;
  final String? monthLabel;
  final int checkIns;

  static GymAttendanceMonthStat? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return GymAttendanceMonthStat(
      monthKey: map['month_key'] as String?,
      monthLabel: map['month_label'] as String?,
      checkIns: map['check_ins'] as int? ?? 0,
    );
  }
}

class GymConsistentMember {
  const GymConsistentMember({
    required this.memberId,
    required this.fullName,
    this.checkInCount = 0,
    this.note,
  });

  final String memberId;
  final String fullName;
  final int checkInCount;
  final String? note;

  static GymConsistentMember fromMap(Map<String, dynamic> map) {
    return GymConsistentMember(
      memberId: map['member_id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? 'Member',
      checkInCount: map['check_in_count'] as int? ?? 0,
      note: map['note'] as String?,
    );
  }
}

class GymTenureMember {
  const GymTenureMember({
    required this.memberId,
    required this.fullName,
    this.joinedOn,
    this.daysAsMember = 0,
  });

  final String memberId;
  final String fullName;
  final DateTime? joinedOn;
  final int daysAsMember;

  static GymTenureMember? fromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return GymTenureMember(
      memberId: map['member_id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? 'Member',
      joinedOn: DateTime.tryParse(map['joined_on'] as String? ?? ''),
      daysAsMember: map['days_as_member'] as int? ?? 0,
    );
  }
}

List<T> _parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fromMap) {
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((e) => fromMap(Map<String, dynamic>.from(e)))
      .toList();
}
