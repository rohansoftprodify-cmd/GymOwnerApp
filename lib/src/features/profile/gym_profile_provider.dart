import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/supabase/supabase_client_provider.dart';

class GymProfileInfo {
  const GymProfileInfo({
    required this.gymId,
    required this.gymName,
    required this.role,
    this.ownerName,
    this.ownerPhone,
    this.gymEmail,
    this.gymPhone,
    this.address,
    this.timezone,
    this.currencyCode,
  });

  final String gymId;
  final String gymName;
  final String role;
  final String? ownerName;
  final String? ownerPhone;
  final String? gymEmail;
  final String? gymPhone;
  final String? address;
  final String? timezone;
  final String? currencyCode;
}

final gymProfileProvider = FutureProvider.family<GymProfileInfo?, String>((ref, gymId) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) return null;

  final repo = ref.watch(gymRepositoryProvider);

  final roleRows = await client
      .from('gym_roles')
      .select('role')
      .eq('gym_id', gymId)
      .eq('user_id', user.id)
      .limit(1);
  if (roleRows.isEmpty) return null;

  final gym = await repo.gymById(gymId);
  final profile = await repo.currentUserProfile();
  if (gym == null) return null;

  return GymProfileInfo(
    gymId: gymId,
    gymName: gym['name'] as String? ?? 'Gym',
    role: roleRows.first['role'] as String? ?? 'owner',
    ownerName: profile?['full_name'] as String?,
    ownerPhone: profile?['phone'] as String?,
    gymEmail: gym['email'] as String?,
    gymPhone: gym['phone'] as String?,
    address: gym['address'] as String?,
    timezone: gym['timezone'] as String?,
    currencyCode: gym['currency_code'] as String?,
  );
});
