import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_owner_app/src/core/auth/single_session_guard.dart';
import 'package:gym_owner_app/src/core/router/app_router.dart';
import 'package:gym_owner_app/src/core/theme/app_responsive.dart';
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
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final size = mediaQuery.size;
        final uiScale = AppResponsive.uiScale(size);
        final systemScale = mediaQuery.textScaler.scale(14) / 14;
        final textScale = (systemScale * 1.04 * uiScale).clamp(0.9, 1.5);

        final baseTheme = Theme.of(context);
        final tablet = AppResponsive.isTablet(size);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: Theme(
            data: baseTheme.copyWith(
              visualDensity: AppResponsive.visualDensity(size),
              iconTheme: baseTheme.iconTheme.copyWith(
                size: (baseTheme.iconTheme.size ?? 24) * (tablet ? 1.12 : 1.0),
              ),
              cardTheme: baseTheme.cardTheme.copyWith(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tablet ? 18 : 16),
                  side: (baseTheme.cardTheme.shape is RoundedRectangleBorder)
                      ? (baseTheme.cardTheme.shape! as RoundedRectangleBorder).side
                      : BorderSide.none,
                ),
              ),
              listTileTheme: baseTheme.listTileTheme.copyWith(
                minVerticalPadding: tablet ? 12 : 8,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: tablet ? 18 : 16,
                  vertical: tablet ? 4 : 0,
                ),
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: (baseTheme.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(
                      horizontal: tablet ? 20 : 16,
                      vertical: tablet ? 16 : 12,
                    ),
                  ),
                  textStyle: WidgetStatePropertyAll(
                    TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      fontSize: tablet ? 15 : 13,
                    ),
                  ),
                ),
              ),
              inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
                isDense: !tablet,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: tablet ? 16 : 12,
                  vertical: tablet ? 14 : 10,
                ),
              ),
              navigationBarTheme: baseTheme.navigationBarTheme.copyWith(
                height: tablet ? 72 : 64,
                labelTextStyle: WidgetStatePropertyAll(
                  TextStyle(
                    fontSize: tablet ? 13 : 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            child: SingleSessionGuard(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
