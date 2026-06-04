import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/supabase/supabase_client_provider.dart';

class TenantContext {
  const TenantContext({
    required this.gymId,
    required this.role,
    required this.gymName,
  });

  final String gymId;
  final String role;
  final String gymName;
}

final authStateProvider = StreamProvider((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final tenantContextProvider = FutureProvider<TenantContext?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) {
    return null;
  }

  final roleRows = await client
      .from('gym_roles')
      .select('gym_id, role, gyms(name)')
      .eq('user_id', user.id)
      .inFilter('role', ['owner', 'staff'])
      .limit(1);
  if (roleRows.isEmpty) {
    return null;
  }

  final row = roleRows.first;
  final gymMap = row['gyms'] as Map<String, dynamic>? ?? const {};

  return TenantContext(
    gymId: row['gym_id'] as String,
    role: row['role'] as String,
    gymName: gymMap['name'] as String? ?? 'Gym',
  );
});
