import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/data/gym_repository.dart';
import 'package:gym_owner_app/src/core/supabase/supabase_client_provider.dart';

final gymRepositoryProvider = Provider<GymRepository>((ref) {
  return GymRepository(ref.watch(supabaseClientProvider));
});
