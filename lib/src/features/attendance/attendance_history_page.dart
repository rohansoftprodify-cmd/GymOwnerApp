import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/features/attendance/attendance_utils.dart';
import 'package:gym_owner_app/src/features/attendance/widgets/attendance_record_card.dart';
enum _HistoryRange { today, yesterday, last7, last30, all }

class AttendanceHistoryPage extends ConsumerStatefulWidget {
  const AttendanceHistoryPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<AttendanceHistoryPage> createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends ConsumerState<AttendanceHistoryPage> {
  _HistoryRange _range = _HistoryRange.last7;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _inRange(DateTime checkIn) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(checkIn.year, checkIn.month, checkIn.day);
    switch (_range) {
      case _HistoryRange.today:
        return day == today;
      case _HistoryRange.yesterday:
        return day == today.subtract(const Duration(days: 1));
      case _HistoryRange.last7:
        return !day.isBefore(today.subtract(const Duration(days: 6)));
      case _HistoryRange.last30:
        return !day.isBefore(today.subtract(const Duration(days: 29)));
      case _HistoryRange.all:
        return true;
    }
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> rows) {
    final query = _searchController.text.trim().toLowerCase();
    return rows.where((record) {
      final checkIn = parseAttendanceTime(record['check_in_at'] as String?);
      if (checkIn == null || !_inRange(checkIn)) return false;

      if (query.isEmpty) return true;
      final name = memberNameFromRecord(record).toLowerCase();
      final phone =
          ((record['members'] as Map<String, dynamic>?)?['phone'] as String? ?? '').toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = ref.watch(gymRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repo.attendance(widget.gymId, limit: 500),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _applyFilters(snap.data!);
          final grouped = groupRecordsByDay(filtered);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search member',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<_HistoryRange>(
                  value: _range,
                  decoration: const InputDecoration(labelText: 'Date', isDense: true),
                  items: const [
                    DropdownMenuItem(value: _HistoryRange.today, child: Text('Today')),
                    DropdownMenuItem(value: _HistoryRange.yesterday, child: Text('Yesterday')),
                    DropdownMenuItem(value: _HistoryRange.last7, child: Text('Last 7 days')),
                    DropdownMenuItem(value: _HistoryRange.last30, child: Text('Last 30 days')),
                    DropdownMenuItem(value: _HistoryRange.all, child: Text('All')),
                  ],
                  onChanged: (v) => setState(() => _range = v ?? _range),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: grouped.isEmpty
                    ? Center(
                        child: Text('No records for selected filters', style: theme.textTheme.bodyMedium),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        itemCount: grouped.length,
                        itemBuilder: (_, i) {
                          final day = grouped.keys.elementAt(i);
                          final dayRecords = grouped[day]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 6),
                                child: Row(
                                  children: [
                                    Text(
                                      formatDayHeader(day),
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${dayRecords.length} visits',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                              for (final record in dayRecords)
                                AttendanceRecordCard(
                                  memberName: memberNameFromRecord(record),
                                  checkInLabel: AttendanceRecordCard.formatTime(record['check_in_at'] as String?),
                                  checkOutLabel: record['check_out_at'] == null
                                      ? null
                                      : AttendanceRecordCard.formatTime(record['check_out_at'] as String?),
                                  isActiveCheckIn: record['check_out_at'] == null,
                                  compact: true,
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
