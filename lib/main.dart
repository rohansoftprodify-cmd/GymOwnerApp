import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/app.dart';
import 'package:gym_owner_app/src/core/storage/shared_preferences_provider.dart';
import 'package:gym_owner_app/src/core/supabase/supabase_bootstrap.dart';
import 'package:gym_owner_app/src/core/theme/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        themeModeProvider.overrideWith((ref) => ThemeModeNotifier(prefs)),
      ],
      child: const GymOwnerApp(),
    ),
  );
}
