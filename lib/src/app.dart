import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/auth/single_session_guard.dart';
import 'package:gym_owner_app/src/core/router/app_router.dart';
import 'package:gym_owner_app/src/core/theme/app_theme.dart';
import 'package:gym_owner_app/src/core/theme/theme_mode_provider.dart';

class GymOwnerApp extends ConsumerWidget {
  const GymOwnerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Gym Owner',
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final currentScale = mediaQuery.textScaler.scale(1.0);
        final compactScale = currentScale < 0.9
            ? 0.9
            : (currentScale > 0.95 ? 0.95 : currentScale);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(compactScale),
          ),
          child: SingleSessionGuard(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
