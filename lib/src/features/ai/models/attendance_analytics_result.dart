class AttendanceAnalyticsResult {
  const AttendanceAnalyticsResult({
    this.generatedAt,
    this.periodDays = 30,
    this.timezone = 'UTC',
    required this.summary,
    required this.overview,
    required this.peakHours,
    required this.quietHours,
    required this.equipmentPressure,
    required this.dayOfWeek,
    this.busiestDay,
    required this.weekendVsWeekday,
    required this.checkInMethods,
    required this.insights,
  });

  final DateTime? generatedAt;
  final int periodDays;
  final String timezone;
  final String summary;
  final AttendanceOverview overview;
  final List<HourlyCheckInStat> peakHours;
  final List<HourlyCheckInStat> quietHours;
  final EquipmentPressureAnalysis equipmentPressure;
  final List<DayOfWeekStat> dayOfWeek;
  final DayOfWeekStat? busiestDay;
  final WeekendWeekdaySplit weekendVsWeekday;
  final List<CheckInMethodStat> checkInMethods;
  final List<String> insights;

  factory AttendanceAnalyticsResult.fromMap(Map<String, dynamic> map) {
    final rawInsights = map['insights'] as List<dynamic>? ?? [];
    return AttendanceAnalyticsResult(
      generatedAt: DateTime.tryParse(map['generated_at'] as String? ?? ''),
      periodDays: map['period_days'] as int? ?? 30,
      timezone: map['timezone'] as String? ?? 'UTC',
      summary: map['summary'] as String? ?? '',
      overview: AttendanceOverview.fromMap(
        map['overview'] is Map ? Map<String, dynamic>.from(map['overview'] as Map) : null,
      ),
      peakHours: _parseList(map['peak_hours'], HourlyCheckInStat.fromMap),
      quietHours: _parseList(map['quiet_hours'], HourlyCheckInStat.fromMap),
      equipmentPressure: EquipmentPressureAnalysis.fromMap(
        map['equipment_pressure'] is Map
            ? Map<String, dynamic>.from(map['equipment_pressure'] as Map)
            : null,
      ),
      dayOfWeek: _parseList(map['day_of_week'], DayOfWeekStat.fromMap),
      busiestDay: DayOfWeekStat.fromMap(map['busiest_day']),
      weekendVsWeekday: WeekendWeekdaySplit.fromMap(
        map['weekend_vs_weekday'] is Map
            ? Map<String, dynamic>.from(map['weekend_vs_weekday'] as Map)
            : null,
      ),
      checkInMethods: _parseList(map['check_in_methods'], CheckInMethodStat.fromMap),
      insights: rawInsights.map((e) => e.toString()).where((s) => s.isNotEmpty).toList(),
    );
  }
}

class AttendanceOverview {
  const AttendanceOverview({
    this.totalCheckIns = 0,
    this.completedSessions = 0,
    this.openSessions = 0,
    this.uniqueMembers = 0,
    this.avgDailyCheckIns = 0,
    this.checkoutRatePercent = 0,
    this.avgSessionMinutes = 0,
    this.medianSessionMinutes = 75,
  });

  final int totalCheckIns;
  final int completedSessions;
  final int openSessions;
  final int uniqueMembers;
  final double avgDailyCheckIns;
  final double checkoutRatePercent;
  final int avgSessionMinutes;
  final int medianSessionMinutes;

  factory AttendanceOverview.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AttendanceOverview();
    return AttendanceOverview(
      totalCheckIns: map['total_check_ins'] as int? ?? 0,
      completedSessions: map['completed_sessions'] as int? ?? 0,
      openSessions: map['open_sessions'] as int? ?? 0,
      uniqueMembers: map['unique_members'] as int? ?? 0,
      avgDailyCheckIns: (map['avg_daily_check_ins'] as num?)?.toDouble() ?? 0,
      checkoutRatePercent: (map['checkout_rate_percent'] as num?)?.toDouble() ?? 0,
      avgSessionMinutes: (map['avg_session_minutes'] as num?)?.round() ?? 0,
      medianSessionMinutes: (map['median_session_minutes'] as num?)?.round() ?? 75,
    );
  }
}

class HourlyCheckInStat {
  const HourlyCheckInStat({
    required this.hour,
    required this.hourLabel,
    required this.checkIns,
    this.percentOfPeak = 0,
  });

  final int hour;
  final String hourLabel;
  final int checkIns;
  final int percentOfPeak;

  factory HourlyCheckInStat.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const HourlyCheckInStat(hour: 0, hourLabel: '—', checkIns: 0);
    }
    return HourlyCheckInStat(
      hour: map['hour'] as int? ?? 0,
      hourLabel: map['hour_label'] as String? ?? '—',
      checkIns: map['check_ins'] as int? ?? 0,
      percentOfPeak: (map['percent_of_peak'] as num?)?.round() ?? 0,
    );
  }
}

class HourlyOccupancyStat {
  const HourlyOccupancyStat({
    required this.hour,
    required this.hourLabel,
    required this.avgOnFloor,
    this.pressurePercent = 0,
  });

  final int hour;
  final String hourLabel;
  final double avgOnFloor;
  final int pressurePercent;

  factory HourlyOccupancyStat.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const HourlyOccupancyStat(hour: 0, hourLabel: '—', avgOnFloor: 0);
    }
    return HourlyOccupancyStat(
      hour: map['hour'] as int? ?? 0,
      hourLabel: map['hour_label'] as String? ?? '—',
      avgOnFloor: (map['avg_on_floor'] as num?)?.toDouble() ?? 0,
      pressurePercent: (map['pressure_percent'] as num?)?.round() ?? 0,
    );
  }
}

class SessionDurationBand {
  const SessionDurationBand({
    required this.band,
    required this.label,
    required this.count,
  });

  final String band;
  final String label;
  final int count;

  factory SessionDurationBand.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const SessionDurationBand(band: '', label: '', count: 0);
    }
    return SessionDurationBand(
      band: map['band'] as String? ?? '',
      label: map['label'] as String? ?? '',
      count: map['count'] as int? ?? 0,
    );
  }
}

class EquipmentPressureAnalysis {
  const EquipmentPressureAnalysis({
    this.note = '',
    this.peakOccupancyHour,
    this.byHour = const [],
    this.sessionDurationBands = const [],
  });

  final String note;
  final HourlyOccupancyStat? peakOccupancyHour;
  final List<HourlyOccupancyStat> byHour;
  final List<SessionDurationBand> sessionDurationBands;

  factory EquipmentPressureAnalysis.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const EquipmentPressureAnalysis();
    return EquipmentPressureAnalysis(
      note: map['note'] as String? ?? '',
      peakOccupancyHour: HourlyOccupancyStat.fromMap(
        map['peak_occupancy_hour'] is Map
            ? Map<String, dynamic>.from(map['peak_occupancy_hour'] as Map)
            : null,
      ),
      byHour: _parseList(map['by_hour'], HourlyOccupancyStat.fromMap),
      sessionDurationBands: _parseList(
        map['session_duration_bands'],
        SessionDurationBand.fromMap,
      ),
    );
  }
}

class DayOfWeekStat {
  const DayOfWeekStat({
    required this.dow,
    required this.dayLabel,
    required this.checkIns,
    this.percentOfPeak = 0,
  });

  final int dow;
  final String dayLabel;
  final int checkIns;
  final int percentOfPeak;

  factory DayOfWeekStat.fromMap(dynamic raw) {
    if (raw is! Map) return const DayOfWeekStat(dow: 0, dayLabel: '—', checkIns: 0);
    final map = Map<String, dynamic>.from(raw);
    return DayOfWeekStat(
      dow: map['dow'] as int? ?? 0,
      dayLabel: map['day_label'] as String? ?? '—',
      checkIns: map['check_ins'] as int? ?? 0,
      percentOfPeak: (map['percent_of_peak'] as num?)?.round() ?? 0,
    );
  }
}

class WeekendWeekdaySplit {
  const WeekendWeekdaySplit({
    this.weekdayCheckIns = 0,
    this.weekendCheckIns = 0,
  });

  final int weekdayCheckIns;
  final int weekendCheckIns;

  factory WeekendWeekdaySplit.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const WeekendWeekdaySplit();
    return WeekendWeekdaySplit(
      weekdayCheckIns: map['weekday_check_ins'] as int? ?? 0,
      weekendCheckIns: map['weekend_check_ins'] as int? ?? 0,
    );
  }
}

class CheckInMethodStat {
  const CheckInMethodStat({
    required this.method,
    required this.label,
    required this.count,
    this.percent = 0,
  });

  final String method;
  final String label;
  final int count;
  final double percent;

  factory CheckInMethodStat.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const CheckInMethodStat(method: '', label: '', count: 0);
    }
    return CheckInMethodStat(
      method: map['method'] as String? ?? '',
      label: map['label'] as String? ?? '',
      count: map['count'] as int? ?? 0,
      percent: (map['percent'] as num?)?.toDouble() ?? 0,
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
