import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef SessionTakeoverHandler = Future<void> Function();

class SingleSessionService {
  SingleSessionService(this._client, this._prefs);

  static const _prefsKey = 'owner_active_session_id';

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  RealtimeChannel? _channel;
  Timer? _pollTimer;
  bool _monitoring = false;
  bool _handlingTakeover = false;
  bool _claimingSession = false;
  SessionTakeoverHandler? _onTakeover;

  String? get localSessionId => _prefs.getString(_prefsKey);

  void setTakeoverHandler(SessionTakeoverHandler handler) {
    _onTakeover = handler;
  }

  /// Whether this email already has an active single-device app session (pre-login).
  Future<bool> emailHasActiveSession(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;

    try {
      final result = await _client.rpc(
        'member_email_has_active_session',
        params: {'p_email': trimmed},
      );
      return result == true;
    } catch (error) {
      debugPrint('Active session pre-check failed: $error');
      return false;
    }
  }

  /// Claims this device as the active session and signs out other devices.
  /// Returns whether another session existed before this login.
  Future<bool> completeSignInAfterPassword() async {
    _claimingSession = true;
    try {
      await stopMonitoring();

      final result = await _client.rpc('claim_active_session');
      if (result is! Map<String, dynamic>) {
        throw const AuthException('Failed to register this device session.');
      }

      final sessionId = result['session_id'] as String?;
      if (sessionId == null || sessionId.isEmpty) {
        throw const AuthException('Failed to register this device session.');
      }

      final hadPrevious = result['had_previous_session'] as bool? ?? false;

      // Persist before sign-out/realtime so this device is not treated as taken over.
      await _prefs.setString(_prefsKey, sessionId);
      await _client.auth.signOut(scope: SignOutScope.others);
      await startMonitoring();
      return hadPrevious;
    } finally {
      _claimingSession = false;
    }
  }

  Future<void> signOutLocally() async {
    await stopMonitoring();
    final sessionId = localSessionId;
    if (sessionId != null) {
      try {
        await _client.rpc('release_active_session', params: {'p_session_id': sessionId});
      } catch (_) {
        // Best effort; still sign out locally.
      }
    }
    await _prefs.remove(_prefsKey);
    await _client.auth.signOut(scope: SignOutScope.local);
  }

  Future<void> startMonitoring() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _ensureLocalSessionRegistered();
    if (localSessionId == null) return;
    if (_monitoring) return;

    _monitoring = true;
    await _validateOrTakeover();

    _channel?.unsubscribe();
    _channel = _client
        .channel('owner-session-${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_active_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (_) => _validateOrTakeover(),
        )
        .subscribe();

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _validateOrTakeover());
  }

  Future<void> stopMonitoring() async {
    _monitoring = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    await _channel?.unsubscribe();
    _channel = null;
  }

  Future<void> _ensureLocalSessionRegistered() async {
    if (localSessionId != null || _client.auth.currentUser == null) return;

    final result = await _client.rpc('claim_active_session');
    if (result is! Map<String, dynamic>) return;

    final sessionId = result['session_id'] as String?;
    if (sessionId == null || sessionId.isEmpty) return;

    await _prefs.setString(_prefsKey, sessionId);
  }

  Future<void> _validateOrTakeover() async {
    if (_handlingTakeover || _claimingSession) return;

    final user = _client.auth.currentUser;
    final storedSessionId = localSessionId;
    if (user == null || storedSessionId == null) return;

    try {
      final row = await _client
          .from('user_active_sessions')
          .select('session_id')
          .eq('user_id', user.id)
          .maybeSingle();

      final activeSessionId = row?['session_id'] as String?;
      if (activeSessionId == null || activeSessionId == storedSessionId) return;

      await _handleTakeover();
    } catch (error) {
      debugPrint('Single session validation failed: $error');
    }
  }

  Future<void> _handleTakeover() async {
    if (_handlingTakeover) return;
    _handlingTakeover = true;

    try {
      await stopMonitoring();
      await _prefs.remove(_prefsKey);
      await _client.auth.signOut(scope: SignOutScope.local);
      await _onTakeover?.call();
    } finally {
      _handlingTakeover = false;
    }
  }
}
