import 'package:intl/intl.dart';

bool isSameLocalDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime? parseAttendanceTime(String? raw) {
  if (raw == null) return null;
  return DateTime.parse(raw).toLocal();
}

bool isTodayAttendance(String? checkInAt) {
  final time = parseAttendanceTime(checkInAt);
  if (time == null) return false;
  return isSameLocalDay(time, DateTime.now());
}

String memberNameFromRecord(Map<String, dynamic> record) {
  return (record['members'] as Map<String, dynamic>? ?? const {})['full_name'] as String? ??
      'Unknown';
}

String memberIdFromRecord(Map<String, dynamic> record) {
  return record['member_id'] as String? ??
      (record['members'] as Map<String, dynamic>?)?['id'] as String? ??
      '';
}

Map<DateTime, List<Map<String, dynamic>>> groupRecordsByDay(
  List<Map<String, dynamic>> records,
) {
  final grouped = <DateTime, List<Map<String, dynamic>>>{};
  for (final record in records) {
    final checkIn = parseAttendanceTime(record['check_in_at'] as String?);
    if (checkIn == null) continue;
    final day = DateTime(checkIn.year, checkIn.month, checkIn.day);
    grouped.putIfAbsent(day, () => []).add(record);
  }
  final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  return {for (final day in sortedDays) day: grouped[day]!};
}

String formatDayHeader(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final d = DateTime(day.year, day.month, day.day);
  if (d == today) return 'Today';
  if (d == yesterday) return 'Yesterday';
  return DateFormat.yMMMd().format(d);
}
