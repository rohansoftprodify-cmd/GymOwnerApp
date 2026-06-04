import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> initialize() async {
    if (_url.isEmpty || _anonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. Pass with --dart-define.',
      );
    }
    await Supabase.initialize(url: _normalizeSupabaseUrl(_url), anonKey: _anonKey);
  }

  static String _normalizeSupabaseUrl(String rawUrl) {
    final parsed = Uri.tryParse(rawUrl.trim());
    if (parsed == null || parsed.scheme.isEmpty || parsed.host.isEmpty) {
      throw StateError(
        'Invalid SUPABASE_URL. Use your project URL like https://<project-ref>.supabase.co',
      );
    }

    // Supabase client expects project base URL, not REST path (/rest/v1).
    return Uri(
      scheme: parsed.scheme,
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : null,
    ).toString();
  }
}
