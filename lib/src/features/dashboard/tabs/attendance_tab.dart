import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/ai/ai_repository.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';
import 'package:gym_owner_app/src/features/attendance/attendance_utils.dart';
import 'package:gym_owner_app/src/features/attendance/widgets/attendance_history_panel.dart';
import 'package:gym_owner_app/src/features/attendance/widgets/attendance_record_card.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/attendance_analytics_section.dart';
import 'package:intl/intl.dart';

class AttendanceTab extends ConsumerStatefulWidget {
  const AttendanceTab({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends ConsumerState<AttendanceTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _reloadToken = 0;

  static const _fabClearance = 88.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _reloadToken++);

  Future<void> _pullRefresh() async {
    final future = ref.read(gymRepositoryProvider).attendance(widget.gymId);
    setState(() => _reloadToken++);
    await future;
  }

  void _openGymQr() => context.push('/gym-check-in-qr?gymId=${widget.gymId}');

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(gymRepositoryProvider);
    final analyticsAsync = ref.watch(attendanceAnalyticsProvider(widget.gymId));

    return Stack(
      children: [
        Column(
          children: [
            analyticsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
              data: (result) => AttendanceAnalyticsSection(
                gymId: widget.gymId,
                result: result,
              ),
            ),
            TabBar(
              controller: _tabController,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              tabs: const [
                Tab(text: 'Check in'),
                Tab(text: 'Check out'),
                Tab(text: 'History'),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                key: ValueKey(_reloadToken),
                future: repo.attendance(widget.gymId),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final all = snap.data!;
                  final activeCheckIns =
                      all.where((r) => r['check_out_at'] == null).toList()
                        ..sort((a, b) {
                          final aTime =
                              DateTime.tryParse(
                                a['check_in_at'] as String? ?? '',
                              ) ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          final bTime =
                              DateTime.tryParse(
                                b['check_in_at'] as String? ?? '',
                              ) ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          return bTime.compareTo(aTime);
                        });
                  final todayCompleted = all
                      .where(
                        (r) =>
                            r['check_out_at'] != null &&
                            isTodayAttendance(r['check_in_at'] as String?),
                      )
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _CheckInPanel(
                        gymId: widget.gymId,
                        records: activeCheckIns,
                        onRefresh: _refresh,
                        onPullRefresh: _pullRefresh,
                        bottomPadding: _fabClearance,
                      ),
                      _CheckOutPanel(
                        records: todayCompleted,
                        onPullRefresh: _pullRefresh,
                        bottomPadding: _fabClearance,
                      ),
                      AttendanceHistoryPanel(
                        gymId: widget.gymId,
                        bottomPadding: _fabClearance,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 0,
          bottom: 10,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'manual_attendance_btn',
                onPressed: () => _showManualAttendanceDialog(
                  context,
                  ref,
                  widget.gymId,
                  onSuccess: _refresh,
                ),
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Manual Entry'),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                heroTag: 'gym_qr_btn',
                onPressed: _openGymQr,
                child: const Icon(Icons.qr_code_2_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckInPanel extends ConsumerWidget {
  const _CheckInPanel({
    required this.gymId,
    required this.records,
    required this.onRefresh,
    required this.onPullRefresh,
    required this.bottomPadding,
  });

  final String gymId;
  final List<Map<String, dynamic>> records;
  final VoidCallback onRefresh;
  final Future<void> Function() onPullRefresh;
  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: onPullRefresh,
      child: records.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomPadding, top: 4),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      Text('No active check-in\'s. Click here to add.', style: TextStyle(color: Colors.white70),),
                      _AddCheckInButton(
                        onPressed: () => _showCheckInDialog(
                          context,
                          ref,
                          gymId,
                          onSuccess: onRefresh,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 120),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomPadding, top: 4),
              itemCount: records.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _AddCheckInButton(
                    onPressed: () => _showCheckInDialog(
                      context,
                      ref,
                      gymId,
                      onSuccess: onRefresh,
                    ),
                  );
                }

                final record = records[i - 1];
                final memberName = memberNameFromRecord(record);
                final memberId = memberIdFromRecord(record);
                final checkInRaw = record['check_in_at'] as String?;
                final checkInNote = isTodayAttendance(checkInRaw)
                    ? null
                    : 'Since ${AttendanceRecordCard.formatDate(checkInRaw)}';
                return AttendanceRecordCard(
                  memberName: memberName,
                  checkInLabel: AttendanceRecordCard.formatTime(checkInRaw),
                  checkInNote: checkInNote,
                  isActiveCheckIn: true,
                  onCheckOut: () => checkOutMemberHelper(
                    context,
                    ref,
                    gymId: gymId,
                    recordId: record['id'] as String,
                    memberId: memberId,
                    memberName: memberName,
                    onSuccess: onRefresh,
                  ),
                );
              },
            ),
    );
  }
}

class _AddCheckInButton extends StatelessWidget {
  const _AddCheckInButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: FilledButton.icon(
          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.transparent)),
          onPressed: onPressed,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('Add check-in'),
        ),
      ),
    );
  }
}

class _CheckOutPanel extends StatelessWidget {
  const _CheckOutPanel({
    required this.records,
    required this.onPullRefresh,
    required this.bottomPadding,
  });

  final List<Map<String, dynamic>> records;
  final Future<void> Function() onPullRefresh;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onPullRefresh,
      child: records.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 4, bottom: bottomPadding),
              children: const [
                SizedBox(height: 80),
                Center(child: Text('No check-outs recorded today')),
                SizedBox(height: 120),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(top: 4, bottom: bottomPadding),
              itemCount: records.length,
              itemBuilder: (_, i) {
                final record = records[i];
                return AttendanceRecordCard(
                  memberName: memberNameFromRecord(record),
                  checkInLabel: AttendanceRecordCard.formatTime(
                    record['check_in_at'] as String?,
                  ),
                  checkOutLabel: AttendanceRecordCard.formatTime(
                    record['check_out_at'] as String?,
                  ),
                  isActiveCheckIn: false,
                );
              },
            ),
    );
  }
}

Future<void> checkOutMemberHelper(
  BuildContext context,
  WidgetRef ref, {
  required String gymId,
  required String recordId,
  required String memberId,
  required String memberName,
  required VoidCallback onSuccess,
}) async {
  final navigator = Navigator.of(context);
  DateTime selectedDate = DateTime.now();
  TimeOfDay checkOutTime = TimeOfDay.now();
  bool useCustomTime = false;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        Future<void> pickDate() async {
          final picked = await showDatePicker(
            context: ctx,
            initialDate: selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setDialogState(() => selectedDate = picked);
          }
        }

        Future<void> pickCheckOutTime() async {
          final picked = await showTimePicker(
            context: ctx,
            initialTime: checkOutTime,
          );
          if (picked != null) {
            setDialogState(() => checkOutTime = picked);
          }
        }

        return AlertDialog(
          icon: const Icon(Icons.logout_rounded),
          title: Text('Check out $memberName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Would you like to check out this member now, or set a custom checkout date & time?'),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use custom date & time'),
                value: useCustomTime,
                onChanged: (val) => setDialogState(() => useCustomTime = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (useCustomTime) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: const Text('Date'),
                  subtitle: Text(DateFormat.yMMMMd().format(selectedDate)),
                  onTap: pickDate,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_rounded),
                  title: const Text('Checkout Time'),
                  subtitle: Text(checkOutTime.format(ctx)),
                  onTap: pickCheckOutTime,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final ok = await runWithErrorDialog(
                  ctx,
                  errorTitle: 'Check-out failed',
                  action: () async {
                    if (useCustomTime) {
                      final checkOutDt = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        checkOutTime.hour,
                        checkOutTime.minute,
                      );
                      await ref
                          .read(gymRepositoryProvider)
                          .updateCheckOutTime(recordId: recordId, checkOutAt: checkOutDt);
                    } else {
                      await ref
                          .read(gymRepositoryProvider)
                          .markAttendance(gymId: gymId, memberId: memberId, action: 'check_out');
                    }
                  },
                );
                if (!ctx.mounted) return;
                if (ok) {
                  navigator.pop();
                  onSuccess();
                }
              },
              child: const Text('Check out'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _showManualAttendanceDialog(
  BuildContext context,
  WidgetRef ref,
  String gymId, {
  required VoidCallback onSuccess,
}) async {
  final navigator = Navigator.of(context);
  final members = await ref.read(gymRepositoryProvider).members(gymId);
  if (!context.mounted) return;

  if (members.isEmpty) {
    await showAppErrorDialog(
      context,
      title: 'No members',
      error: 'Create members first before logging attendance.',
    );
    return;
  }

  // Dialog State
  String? selectedMemberId;
  DateTime selectedDate = DateTime.now();
  TimeOfDay checkInTime = TimeOfDay.now();
  TimeOfDay checkOutTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );
  bool includeCheckOut = true;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        Future<void> pickDate() async {
          final picked = await showDatePicker(
            context: ctx,
            initialDate: selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setDialogState(() => selectedDate = picked);
          }
        }

        Future<void> pickCheckInTime() async {
          final picked = await showTimePicker(
            context: ctx,
            initialTime: checkInTime,
          );
          if (picked != null) {
            setDialogState(() => checkInTime = picked);
          }
        }

        Future<void> pickCheckOutTime() async {
          final picked = await showTimePicker(
            context: ctx,
            initialTime: checkOutTime,
          );
          if (picked != null) {
            setDialogState(() => checkOutTime = picked);
          }
        }

        return AlertDialog(
          icon: const Icon(Icons.history_edu_rounded),
          title: const Text('Log attendance manually'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select member',
                    prefixIcon: Icon(Icons.person_search, size: 20),
                  ),
                  items: members
                      .map(
                        (m) => DropdownMenuItem(
                          value: m['id'] as String,
                          child: Text(m['full_name'] as String? ?? '-'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => selectedMemberId = v,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: const Text('Date'),
                  subtitle: Text(DateFormat.yMMMMd().format(selectedDate)),
                  onTap: pickDate,
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.login_rounded),
                  title: const Text('Check-in Time'),
                  subtitle: Text(checkInTime.format(ctx)),
                  onTap: pickCheckInTime,
                ),
                const Divider(),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include Check-out'),
                  value: includeCheckOut,
                  onChanged: (val) => setDialogState(() => includeCheckOut = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (includeCheckOut)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout_rounded),
                    title: const Text('Check-out Time'),
                    subtitle: Text(checkOutTime.format(ctx)),
                    onTap: pickCheckOutTime,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (selectedMemberId == null) {
                  await showAppErrorDialog(
                    ctx,
                    title: 'Missing member',
                    error: 'Please select a member.',
                  );
                  return;
                }

                final checkInDt = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  checkInTime.hour,
                  checkInTime.minute,
                );

                DateTime? checkOutDt;
                if (includeCheckOut) {
                  checkOutDt = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    checkOutTime.hour,
                    checkOutTime.minute,
                  );

                  if (checkOutDt.isBefore(checkInDt)) {
                    await showAppErrorDialog(
                      ctx,
                      title: 'Invalid checkout time',
                      error: 'Checkout time must be after checkin time.',
                    );
                    return;
                  }
                }

                final ok = await runWithErrorDialog(
                  ctx,
                  errorTitle: 'Failed to log attendance',
                  action: () => ref
                      .read(gymRepositoryProvider)
                      .logManualAttendance(
                        gymId: gymId,
                        memberId: selectedMemberId!,
                        checkInAt: checkInDt,
                        checkOutAt: checkOutDt,
                      ),
                );
                if (!ctx.mounted) return;
                if (ok) {
                  navigator.pop();
                  onSuccess();
                }
              },
              child: const Text('Save Entry'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _showCheckInDialog(
  BuildContext context,
  WidgetRef ref,
  String gymId, {
  required VoidCallback onSuccess,
}) async {
  final navigator = Navigator.of(context);
  final members = await ref.read(gymRepositoryProvider).members(gymId);
  final attendance = await ref.read(gymRepositoryProvider).attendance(gymId);
  if (!context.mounted) return;

  // Find active check-in records: map member_id to attendance record map
  final activeCheckInMap = <String, Map<String, dynamic>>{};
  for (final record in attendance) {
    if (record['check_out_at'] == null) {
      final mId = memberIdFromRecord(record);
      if (mId.isNotEmpty) {
        activeCheckInMap[mId] = record;
      }
    }
  }

  String searchQuery = '';

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final filteredMembers = members.where((m) {
          final fullName = (m['full_name'] as String? ?? '').toLowerCase();
          final phone = (m['phone'] as String? ?? '').toLowerCase();
          final query = searchQuery.trim().toLowerCase();
          return fullName.contains(query) || phone.contains(query);
        }).toList();

        final theme = Theme.of(ctx);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          icon: const Icon(Icons.people_rounded),
          title: const Text('Quick Attendance Check'),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (val) => setDialogState(() => searchQuery = val),
                  decoration: const InputDecoration(
                    labelText: 'Search member',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: filteredMembers.isEmpty
                      ? const Center(
                          child: Text('No members found'),
                        )
                      : ListView.separated(
                          itemCount: filteredMembers.length,
                          separatorBuilder: (c, idx) => const Divider(height: 1),
                          itemBuilder: (c, idx) {
                            final m = filteredMembers[idx];
                            final memberId = m['id'] as String;
                            final name = m['full_name'] as String? ?? 'Unknown';
                            final phone = m['phone'] as String? ?? '';
                            final activeRecord = activeCheckInMap[memberId];
                            final isCheckedIn = activeRecord != null;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              subtitle: phone.isNotEmpty
                                  ? Text(phone, style: const TextStyle(fontSize: 10))
                                  : null,
                              trailing: isCheckedIn
                                  ? FilledButton(
                                      onPressed: () async {
                                        // Close current quick check dialog first
                                        navigator.pop();
                                        // Open standard checkout confirmation dialog
                                        await checkOutMemberHelper(
                                          context,
                                          ref,
                                          gymId: gymId,
                                          recordId: activeRecord['id'] as String,
                                          memberId: memberId,
                                          memberName: name,
                                          onSuccess: onSuccess,
                                        );
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFFDC2626),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Check out', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  : FilledButton(
                                      onPressed: () async {
                                        final ok = await runWithErrorDialog(
                                          ctx,
                                          errorTitle: 'Check-in failed',
                                          action: () => ref
                                              .read(gymRepositoryProvider)
                                              .markAttendance(
                                                gymId: gymId,
                                                memberId: memberId,
                                                action: 'check_in',
                                              ),
                                        );
                                        if (ok) {
                                          navigator.pop();
                                          onSuccess();
                                        }
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF16A34A),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Check in', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    ),
  );
}
