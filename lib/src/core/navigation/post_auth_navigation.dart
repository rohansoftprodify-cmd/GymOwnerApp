import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_owner_app/src/core/tenant/gym_setup_provider.dart';

Future<void> navigateAfterSignIn(BuildContext context, WidgetRef ref) async {
  final setupRequired = await ref.read(gymOwnerSetupRequiredProvider.future);
  if (!context.mounted) return;
  context.go(setupRequired ? '/owner-setup' : '/');
}
