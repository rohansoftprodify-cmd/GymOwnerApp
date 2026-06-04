double pendingAmount({
  required double planPrice,
  required double amountPaid,
}) {
  final pending = planPrice - amountPaid;
  return pending < 0 ? 0 : pending;
}

int? renewalDaysLeft(String? endDateRaw, {DateTime? now}) {
  if (endDateRaw == null) return null;
  final endDate = DateTime.tryParse(endDateRaw);
  if (endDate == null) return null;
  final reference = now ?? DateTime.now();
  return endDate.difference(reference).inDays.clamp(0, 999);
}

String renewalDaysLabel(int? daysLeft) {
  if (daysLeft == null) return '—';
  return 'In $daysLeft ${daysLeft == 1 ? 'Day' : 'Days'}';
}

int attendanceCompletionRate({
  required int totalCheckins,
  required int totalCheckouts,
}) {
  if (totalCheckins <= 0) {
    return 0;
  }
  return ((totalCheckouts / totalCheckins) * 100).round();
}
