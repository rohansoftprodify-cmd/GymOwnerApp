import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';

/// Monochrome white/black theme — light mode is white surfaces with black text;
/// dark mode inverts to black surfaces with white text.
class AppTheme {
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF1E40AF);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF0F172A);

  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF131B2E);
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkOnPrimary = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFF8FAFC);

  /// Legacy alias used by a few widgets.
  static const Color wellnessPrimary = lightPrimary;
  static const Color wellnessOnPrimary = lightOnPrimary;
  static const Color wellnessOnSurface = lightOnSurface;
  static const Color wellnessBackground = lightBackground;
  static const Color wellnessSurface = lightSurface;

  static const Color _lightMuted = Color(0xFF64748B);
  static const Color _darkMuted = Color(0xFF94A3B8);

  static ColorScheme get _lightScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: lightPrimary,
        onPrimary: lightOnPrimary,
        primaryContainer: Color(0xFFEEF2FF),
        onPrimaryContainer: Color(0xFF1E40AF),
        secondary: Color(0xFF334155),
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFF1F5F9),
        onSecondaryContainer: Color(0xFF1E293B),
        tertiary: Color(0xFF0D9488),
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFFCCFBF1),
        onTertiaryContainer: Color(0xFF115E59),
        error: Color(0xFFEF4444),
        onError: Color(0xFFFFFFFF),
        surface: lightSurface,
        onSurface: lightOnSurface,
        onSurfaceVariant: _lightMuted,
        outline: Color(0xFFE2E8F0),
        outlineVariant: Color(0xFFF1F5F9),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: lightOnSurface,
        onInverseSurface: lightSurface,
        inversePrimary: darkPrimary,
        surfaceTint: lightPrimary,
        surfaceContainerHighest: Color(0xFFF1F5F9),
      );

  static ColorScheme get _darkScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: darkOnPrimary,
        primaryContainer: Color(0xFF1E3A8A),
        onPrimaryContainer: Color(0xFFDBEAFE),
        secondary: Color(0xFF94A3B8),
        onSecondary: Color(0xFF0B0F19),
        secondaryContainer: Color(0xFF1E293B),
        onSecondaryContainer: Color(0xFFF1F5F9),
        tertiary: Color(0xFF2DD4BF),
        onTertiary: Color(0xFF0B0F19),
        tertiaryContainer: Color(0xFF115E59),
        onTertiaryContainer: Color(0xFFCCFBF1),
        error: Color(0xFFF87171),
        onError: Color(0xFF0B0F19),
        surface: darkSurface,
        onSurface: darkOnSurface,
        onSurfaceVariant: _darkMuted,
        outline: Color(0xFF334155),
        outlineVariant: Color(0xFF1E293B),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: darkOnSurface,
        onInverseSurface: darkBackground,
        inversePrimary: lightPrimary,
        surfaceTint: darkPrimary,
        surfaceContainerHighest: darkSurface,
      );

  static ThemeData get light => _buildTheme(
        _lightScheme,
        scaffoldColor: lightBackground,
        appBarColor: lightSurface,
        cardColor: lightSurface,
        navBarColor: lightSurface,
        semantics: AppSemanticColors.light,
      );

  static ThemeData get dark => _buildTheme(
        _darkScheme,
        scaffoldColor: darkBackground,
        appBarColor: darkBackground,
        cardColor: darkSurface,
        navBarColor: darkSurface,
        semantics: AppSemanticColors.dark,
      );

  static ThemeData _buildTheme(
    ColorScheme scheme, {
    required Color scaffoldColor,
    required Color appBarColor,
    required Color cardColor,
    required Color navBarColor,
    required AppSemanticColors semantics,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [semantics],
    );
    final isDark = scheme.brightness == Brightness.dark;

    return base.copyWith(
      visualDensity: VisualDensity.compact,
      scaffoldBackgroundColor: scaffoldColor,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: appBarColor,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shadowColor: isDark ? Colors.transparent : Colors.black12,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? scheme.outlineVariant.withValues(alpha: 0.5)
                : scheme.outline.withValues(alpha: 0.85),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          side: BorderSide(color: scheme.primary, width: 1.2),
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? semantics.cardBackground
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarColor,
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.1),
        height: 60,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: 22,
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        dividerColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: cardColor,
        showDragHandle: true,
        dragHandleColor: scheme.outline.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkPrimary : lightPrimary,
        contentTextStyle: TextStyle(
          color: isDark ? darkOnPrimary : lightOnPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerHighest.withValues(alpha: 0.8),
        selectedColor: scheme.primary.withValues(alpha: isDark ? 0.2 : 0.12),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
        secondaryLabelStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return isDark ? scheme.outline : scheme.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.45);
          }
          return scheme.outlineVariant.withValues(alpha: 0.6);
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        tileColor: Colors.transparent,
      ),
      textTheme: _textTheme(base.textTheme, scheme),
    );
  }

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(fontSize: 28, color: scheme.onSurface),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
        fontSize: 24,
        color: scheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: scheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: scheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: scheme.onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        height: 1.35,
        fontSize: 14,
        color: scheme.onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 13, color: scheme.onSurface),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 11.5,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(fontSize: 12.5, color: scheme.onSurface),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 11.5,
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 10,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
