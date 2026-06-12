import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/features/attendance/widgets/attendance_history_panel.dart';

class AttendanceHistoryPage extends ConsumerWidget {
  const AttendanceHistoryPage({super.key, required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: AttendanceHistoryPanel(gymId: gymId),
      ),
    );
  }
}
