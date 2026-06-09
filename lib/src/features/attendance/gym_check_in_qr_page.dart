import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/domain/attendance_qr.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class GymCheckInQrPage extends ConsumerStatefulWidget {
  const GymCheckInQrPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymCheckInQrPage> createState() => _GymCheckInQrPageState();
}

class _GymCheckInQrPageState extends ConsumerState<GymCheckInQrPage> {
  final GlobalKey _qrKey = GlobalKey();
  int _reloadToken = 0;

  Future<Uint8List?> _captureQrPng() async {
    final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  Future<void> _shareQr(String gymName, String payload) async {
    final png = await _captureQrPng();
    if (png == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not capture QR image.')),
      );
      return;
    }

    final file = XFile.fromData(
      png,
      mimeType: 'image/png',
      name: 'gym-check-in-qr.png',
    );

    await Share.shareXFiles(
      [file],
      text: 'Scan to check in at $gymName\n$payload',
      subject: '$gymName — check-in QR',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;
    final repo = ref.watch(gymRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in QR'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        key: ValueKey(_reloadToken),
        future: Future.wait([
          repo.getGymCheckInQr(widget.gymId),
          repo.gymById(widget.gymId),
        ]),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }

          final data = snap.data![0] as Map<String, dynamic>;
          final gym = snap.data![1] as Map<String, dynamic>?;
          final gymName = data['gym_name'] as String? ?? 'Gym';
          final payload = data['qr_payload'] as String? ?? attendanceQrPayload(widget.gymId);
          final deepLink = data['deep_link'] as String? ?? attendanceCheckInDeepLink(widget.gymId);
          final hasCoords = gym?['latitude'] != null && gym?['longitude'] != null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              if (!hasCoords)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set gym coordinates first',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Members can only check in via QR when they are physically at the gym. '
                        'Configure check-in location in gym profile.',
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => context.push(
                          '/gym-check-in-location?gymId=${widget.gymId}',
                        ),
                        child: const Text('Set check-in location'),
                      ),
                    ],
                  ),
                ),
              Text(
                gymName,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Print this QR and place it at your gym entrance. Members scan it in the member app to mark attendance.',
                style: theme.textTheme.bodyMedium?.copyWith(color: semantics.mutedText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: RepaintBoundary(
                  key: _qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 240,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'One QR per gym — works for all members',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _InfoTile(
                icon: Icons.qr_code_2_rounded,
                title: 'QR payload',
                value: payload,
              ),
              const SizedBox(height: 10),
              _InfoTile(
                icon: Icons.link_rounded,
                title: 'Member app deep link',
                value: deepLink,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _shareQr(gymName, payload),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share QR image'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => setState(() => _reloadToken++),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      const _StepRow(number: '1', text: 'Member opens the Gym Member app and signs in.'),
                      const _StepRow(number: '2', text: 'They go to Attendance → Scan QR code.'),
                      const _StepRow(number: '3', text: 'The app verifies they are at the gym (GPS) and marks check-in or check-out.'),
                      const _StepRow(number: '4', text: 'Attendance appears in your Attendance tab and history.'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
