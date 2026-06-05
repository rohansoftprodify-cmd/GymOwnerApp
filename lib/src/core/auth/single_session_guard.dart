import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/auth/single_session_provider.dart';
import 'package:gym_owner_app/src/core/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SingleSessionGuard extends ConsumerStatefulWidget {
  const SingleSessionGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SingleSessionGuard> createState() => _SingleSessionGuardState();
}

class _SingleSessionGuardState extends ConsumerState<SingleSessionGuard>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  void _setup() {
    final service = ref.read(singleSessionServiceProvider);
    service.setTakeoverHandler(_showTakeoverDialog);

    if (Supabase.instance.client.auth.currentSession != null) {
      service.startMonitoring();
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session == null) {
        ref.read(singleSessionServiceProvider).stopMonitoring();
      }
      // Sign-in monitoring is started explicitly after claim_active_session.
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        Supabase.instance.client.auth.currentSession != null) {
      ref.read(singleSessionServiceProvider).startMonitoring();
    }
  }

  Future<void> _showTakeoverDialog() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_presentTakeoverDialog(completer));
    });
    return completer.future;
  }

  Future<void> _presentTakeoverDialog(Completer<void> completer) async {
    try {
      final context = rootNavigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.devices_other_rounded),
          title: const Text('Signed out'),
          content: const Text(
            'Your account was signed in on another device. '
            'Only one device can be active at a time.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (context.mounted) {
        context.go('/login');
      }
    } finally {
      if (!completer.isCompleted) completer.complete();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
