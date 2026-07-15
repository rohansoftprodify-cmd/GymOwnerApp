import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/supabase/supabase_client_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountDeletionService {
  AccountDeletionService(this._client);

  final SupabaseClient _client;

  Future<void> deleteMyAccount({required String app}) async {
    final response = await _client.functions.invoke(
      'delete-my-account',
      body: {'app': app},
    );

    if (response.status >= 400) {
      final data = response.data;
      if (data is Map && data['error'] is String) {
        throw AuthException(data['error'] as String);
      }
      throw AuthException('Failed to delete account (${response.status}).');
    }

    final data = response.data;
    if (data is Map && data['success'] != true) {
      final message = data['error'];
      if (message is String && message.isNotEmpty) {
        throw AuthException(message);
      }
      throw const AuthException('Failed to delete account.');
    }
  }
}

final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return AccountDeletionService(ref.watch(supabaseClientProvider));
});
