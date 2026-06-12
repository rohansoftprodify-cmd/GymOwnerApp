import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/features/attendance/attendance_utils.dart';
import 'package:gym_owner_app/src/features/attendance/widgets/attendance_record_card.dart';

enum AttendanceHistoryRange { today, yesterday, last7, last30, all }

class AttendanceHistoryPanel extends ConsumerStatefulWidget {
  const AttendanceHistoryPanel({
    super.key,
    required this.gymId,
    this.bottomPadding = 16,
  });

  final String gymId;
  final double bottomPadding;

  @override
  ConsumerState<AttendanceHistoryPanel> createState() => _AttendanceHistoryPanelState();
}

class _AttendanceHistoryPanelState extends ConsumerState<AttendanceHistoryPanel> {
  AttendanceHistoryRange _range = AttendanceHistoryRange.last7;
  final _searchController = TextEditingController();
  int _reloadToken = 0;

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
      case AttendanceHistoryRange.today:
        return day == today;
      case AttendanceHistoryRange.yesterday:
        return day == today.subtract(const Duration(days: 1));
      case AttendanceHistoryRange.last7:
        return !day.isBefore(today.subtract(const Duration(days: 6)));
      case AttendanceHistoryRange.last30:
        return !day.isBefore(today.subtract(const Duration(days: 29)));
      case AttendanceHistoryRange.all:
        return true;
    }
  }

  Future<void> _pullRefresh() async {
    final future = ref.read(gymRepositoryProvider).attendance(widget.gymId, limit: 500);
    setState(() => _reloadToken++);
    await future;
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

    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_reloadToken),
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
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
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
            SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DropdownButtonFormField<AttendanceHistoryRange>(
                value: _range,
                decoration: const InputDecoration(labelText: 'Date', isDense: true),
                items: const [
                  DropdownMenuItem(value: AttendanceHistoryRange.today, child: Text('Today')),
                  DropdownMenuItem(value: AttendanceHistoryRange.yesterday, child: Text('Yesterday')),
                  DropdownMenuItem(value: AttendanceHistoryRange.last7, child: Text('Last 7 days')),
                  DropdownMenuItem(value: AttendanceHistoryRange.last30, child: Text('Last 30 days')),
                  DropdownMenuItem(value: AttendanceHistoryRange.all, child: Text('All')),
                ],
                onChanged: (v) => setState(() => _range = v ?? _range),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _pullRefresh,
                child: grouped.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: widget.bottomPadding),
                        children: [
                          const SizedBox(height: 48),
                          Center(
                            child: Text(
                              'No records for selected filters',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: widget.bottomPadding),
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
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
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
                                  checkInLabel: AttendanceRecordCard.formatTime(
                                    record['check_in_at'] as String?,
                                  ),
                                  checkOutLabel: record['check_out_at'] == null
                                      ? null
                                      : AttendanceRecordCard.formatTime(
                                          record['check_out_at'] as String?,
                                        ),
                                  isActiveCheckIn: record['check_out_at'] == null,
                                  compact: true,
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
