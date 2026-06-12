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
          child: FloatingActionButton.extended(
            onPressed: _openGymQr,
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('Gym QR'),
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
                  onCheckOut: () => _checkOutMember(
                    context,
                    ref,
                    gymId: gymId,
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

Future<void> _checkOutMember(
  BuildContext context,
  WidgetRef ref, {
  required String gymId,
  required String memberId,
  required String memberName,
  required VoidCallback onSuccess,
}) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Confirm check-out',
    message: 'Check out $memberName now?',
    confirmLabel: 'Check out',
    icon: Icons.logout_rounded,
  );
  if (!confirmed || !context.mounted) return;

  final ok = await runWithErrorDialog(
    context,
    errorTitle: 'Check-out failed',
    action: () => ref
        .read(gymRepositoryProvider)
        .markAttendance(gymId: gymId, memberId: memberId, action: 'check_out'),
  );
  if (ok) onSuccess();
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

  final activeTodayIds = attendance
      .where((r) => r['check_out_at'] == null)
      .map(memberIdFromRecord)
      .toSet();

  final available = members
      .where((m) => !activeTodayIds.contains(m['id'] as String))
      .toList();
  if (available.isEmpty) {
    await showAppErrorDialog(
      context,
      title: 'Cannot check in',
      error: 'All members are already checked in today.',
    );
    return;
  }

  String? memberId;
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.login_rounded),
      title: const Text('Add check-in'),
      content: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Select member',
          prefixIcon: Icon(Icons.person_search, size: 20),
        ),
        items: available
            .map(
              (m) => DropdownMenuItem(
                value: m['id'] as String,
                child: Text(m['full_name'] as String? ?? '-'),
              ),
            )
            .toList(),
        onChanged: (v) => memberId = v,
      ),
      actions: [
        TextButton(
          onPressed: () => navigator.pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (memberId == null) {
              await showAppErrorDialog(
                dialogContext,
                title: 'Missing member',
                error: 'Please select a member.',
              );
              return;
            }
            final ok = await runWithErrorDialog(
              dialogContext,
              errorTitle: 'Check-in failed',
              action: () => ref
                  .read(gymRepositoryProvider)
                  .markAttendance(
                    gymId: gymId,
                    memberId: memberId!,
                    action: 'check_in',
                  ),
            );
            if (!dialogContext.mounted) return;
            if (ok) {
              navigator.pop();
              onSuccess();
            }
          },
          child: const Text('Check in'),
        ),
      ],
    ),
  );
}
