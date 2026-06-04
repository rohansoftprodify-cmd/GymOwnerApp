import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';

/// Wellness Hex brand + dashboard semantic accents.
class AppTheme {
  static const Color wellnessBackground = Color(0xFFF8F9FA);
  static const Color wellnessSurface = Color(0xFFFFFFFF);
  static const Color wellnessPrimary = Color(0xFF20B2AA);
  static const Color wellnessOnPrimary = Color(0xFFFFFFFF);
  static const Color wellnessOnSurface = Color(0xFF0A2540);

  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFFFFFFF);

  static const Color _wellnessPrimaryDark = Color(0xFF178F89);
  static const Color _wellnessOnSurfaceMuted = Color(0xFF4A6072);
  static const Color _darkOnSurfaceMuted = Color(0xFF9AA8B5);

  static ColorScheme get _wellnessLightScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: wellnessPrimary,
        onPrimary: wellnessOnPrimary,
        primaryContainer: Color(0xFFB2EBE8),
        onPrimaryContainer: wellnessOnSurface,
        secondary: _wellnessPrimaryDark,
        onSecondary: wellnessOnPrimary,
        secondaryContainer: Color(0xFFE0F5F4),
        onSecondaryContainer: wellnessOnSurface,
        tertiary: wellnessOnSurface,
        onTertiary: wellnessOnPrimary,
        tertiaryContainer: Color(0xFFE8EEF3),
        onTertiaryContainer: wellnessOnSurface,
        error: Color(0xFFC62828),
        onError: wellnessOnPrimary,
        surface: wellnessBackground,
        onSurface: wellnessOnSurface,
        onSurfaceVariant: _wellnessOnSurfaceMuted,
        outline: Color(0xFFB0BEC5),
        outlineVariant: Color(0xFFDDE3E8),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: wellnessOnSurface,
        onInverseSurface: wellnessSurface,
        inversePrimary: Color(0xFF7AD9D2),
        surfaceTint: wellnessPrimary,
        surfaceContainerHighest: Color(0xFFEEF1F3),
      );

  static ColorScheme get _wellnessDarkScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: wellnessPrimary,
        onPrimary: wellnessOnPrimary,
        primaryContainer: Color(0xFF0D4A47),
        onPrimaryContainer: Color(0xFFB2EBE8),
        secondary: Color(0xFF7AD9D2),
        onSecondary: Color(0xFF000000),
        secondaryContainer: Color(0xFF252525),
        onSecondaryContainer: darkOnSurface,
        tertiary: Color(0xFF7AD9D2),
        onTertiary: Color(0xFF000000),
        tertiaryContainer: Color(0xFF2A2A2A),
        onTertiaryContainer: darkOnSurface,
        error: Color(0xFFFF6B5B),
        onError: Color(0xFF000000),
        surface: darkBackground,
        onSurface: darkOnSurface,
        onSurfaceVariant: _darkOnSurfaceMuted,
        outline: Color(0xFF3A3A3A),
        outlineVariant: Color(0xFF2E2E2E),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: darkOnSurface,
        onInverseSurface: darkBackground,
        inversePrimary: wellnessPrimary,
        surfaceTint: wellnessPrimary,
        surfaceContainerHighest: darkSurface,
      );

  static ThemeData get light => _buildTheme(
        _wellnessLightScheme,
        scaffoldColor: wellnessBackground,
        appBarColor: wellnessSurface,
        cardColor: wellnessSurface,
        navBarColor: wellnessSurface,
        semantics: AppSemanticColors.light,
      );

  static ThemeData get dark => _buildTheme(
        _wellnessDarkScheme,
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
                ? scheme.outlineVariant.withValues(alpha: 0.35)
                : scheme.outlineVariant.withValues(alpha: 0.6),
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
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
        indicatorColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
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
        backgroundColor: isDark ? semantics.cardBackground : wellnessOnSurface,
        contentTextStyle: TextStyle(
          color: isDark ? scheme.onSurface : wellnessOnPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      chipTheme: ChipThemeData(
        backgroundColor: isDark
            ? scheme.surfaceContainerHighest
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        selectedColor: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.14),
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
