import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceRecordCard extends StatelessWidget {
  const AttendanceRecordCard({
    super.key,
    required this.memberName,
    required this.checkInLabel,
    this.checkInNote,
    this.checkOutLabel,
    required this.isActiveCheckIn,
    this.onCheckOut,
    this.compact = false,
  });

  final String memberName;
  final String checkInLabel;
  final String? checkInNote;
  final String? checkOutLabel;
  final bool isActiveCheckIn;
  final VoidCallback? onCheckOut;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = isActiveCheckIn ? const Color(0xFF16A34A) : colorScheme.primary;
    final cardFill = isActiveCheckIn
        ? const Color(0xFF16A34A).withValues(alpha: 0.08)
        : colorScheme.primaryContainer.withValues(alpha: 0.35);

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 6 : 8),
      elevation: 0,
      color: cardFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withValues(alpha: 0.35), width: 1.1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: accent.withValues(alpha: 0.14),
              child: Icon(
                isActiveCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                size: 16,
                color: accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memberName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    checkOutLabel == null ? 'In: $checkInLabel' : 'In: $checkInLabel • Out: $checkOutLabel',
                    style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
                  ),
                  if (checkInNote != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      checkInNote!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isActiveCheckIn && onCheckOut != null)
              FilledButton(
                onPressed: onCheckOut,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Check out', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Checked out',
                  style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String formatTime(String? iso) {
    final time = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    return time == null ? '-' : DateFormat.jm().format(time);
  }

  static String formatDate(String? iso) {
    final time = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    return time == null ? '-' : DateFormat.MMMd().format(time);
  }
}
