import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/tenant/tenant_providers.dart';

/// True when the signed-in gym owner must complete the setup wizard.
final gymOwnerSetupRequiredProvider = FutureProvider<bool>((ref) async {
  final tenant = await ref.watch(tenantContextProvider.future);
  if (tenant == null || tenant.role != 'owner') {
    return false;
  }

  final gym = await ref.read(gymRepositoryProvider).gymById(tenant.gymId);
  if (gym == null) return false;
  return gym['setup_completed_at'] == null;
});
