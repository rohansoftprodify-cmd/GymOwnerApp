import 'package:flutter/material.dart';

class GymDayHours {
  GymDayHours({
    required this.dayOfWeek,
    this.isClosed = false,
    this.openTime,
    this.closeTime,
    this.id,
  }) : assert(dayOfWeek >= 1 && dayOfWeek <= 7);

  final int dayOfWeek;
  final bool isClosed;
  final TimeOfDay? openTime;
  final TimeOfDay? closeTime;
  final String? id;

  static const dayNames = <int, String>{
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  String get dayLabel => dayNames[dayOfWeek] ?? 'Day $dayOfWeek';

  GymDayHours copyWith({
    bool? isClosed,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
    bool clearOpen = false,
    bool clearClose = false,
  }) {
    return GymDayHours(
      dayOfWeek: dayOfWeek,
      isClosed: isClosed ?? this.isClosed,
      openTime: clearOpen ? null : (openTime ?? this.openTime),
      closeTime: clearClose ? null : (closeTime ?? this.closeTime),
      id: id,
    );
  }

  static GymDayHours defaultsForDay(int dayOfWeek) {
    final isSunday = dayOfWeek == 7;
    return GymDayHours(
      dayOfWeek: dayOfWeek,
      isClosed: false,
      openTime: TimeOfDay(hour: isSunday ? 8 : 6, minute: 0),
      closeTime: TimeOfDay(hour: isSunday ? 20 : 22, minute: 0),
    );
  }

  static List<GymDayHours> defaultWeek() =>
      List.generate(7, (i) => defaultsForDay(i + 1));

  static GymDayHours fromMap(Map<String, dynamic> row) {
    return GymDayHours(
      id: row['id'] as String?,
      dayOfWeek: row['day_of_week'] as int,
      isClosed: row['is_closed'] as bool? ?? false,
      openTime: _parseDbTime(row['open_time'] as String?),
      closeTime: _parseDbTime(row['close_time'] as String?),
    );
  }

  Map<String, dynamic> toUpsertRow(String gymId) {
    return {
      if (id != null) 'id': id,
      'gym_id': gymId,
      'day_of_week': dayOfWeek,
      'is_closed': isClosed,
      'open_time': isClosed ? null : _formatDbTime(openTime!),
      'close_time': isClosed ? null : _formatDbTime(closeTime!),
    };
  }

  static TimeOfDay? _parseDbTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatDbTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  String hoursLabel() {
    if (isClosed) return 'Closed';
    if (openTime == null || closeTime == null) return 'Not set';
    return '${_formatDisplay(openTime!)} – ${_formatDisplay(closeTime!)}';
  }

  static String formatTime(TimeOfDay time) => _formatDisplay(time);

  static String _formatDisplay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}
