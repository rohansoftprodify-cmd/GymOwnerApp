import 'package:flutter/material.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.cardBackground,
    required this.accentLime,
    required this.accentCoral,
    required this.onAccentLime,
    required this.mutedText,
  });

  final Color cardBackground;
  /// Primary highlight — black in light mode, white in dark mode.
  final Color accentLime;
  /// Destructive / error emphasis.
  final Color accentCoral;
  final Color onAccentLime;
  final Color mutedText;

  static const light = AppSemanticColors(
    cardBackground: Color(0xFFFFFFFF),
    accentLime: Color(0xFF000000),
    accentCoral: Color(0xFFB00020),
    onAccentLime: Color(0xFFFFFFFF),
    mutedText: Color(0xFF666666),
  );

  static const dark = AppSemanticColors(
    cardBackground: Color(0xFF111111),
    accentLime: Color(0xFFFFFFFF),
    accentCoral: Color(0xFFFF6B6B),
    onAccentLime: Color(0xFF000000),
    mutedText: Color(0xFFA3A3A3),
  );

  @override
  AppSemanticColors copyWith({
    Color? cardBackground,
    Color? accentLime,
    Color? accentCoral,
    Color? onAccentLime,
    Color? mutedText,
  }) {
    return AppSemanticColors(
      cardBackground: cardBackground ?? this.cardBackground,
      accentLime: accentLime ?? this.accentLime,
      accentCoral: accentCoral ?? this.accentCoral,
      onAccentLime: onAccentLime ?? this.onAccentLime,
      mutedText: mutedText ?? this.mutedText,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      accentLime: Color.lerp(accentLime, other.accentLime, t)!,
      accentCoral: Color.lerp(accentCoral, other.accentCoral, t)!,
      onAccentLime: Color.lerp(onAccentLime, other.onAccentLime, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppSemanticColors get appColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;

  Color get loadingScrimColor =>
      Theme.of(this).colorScheme.scrim.withValues(alpha: 0.45);
}
