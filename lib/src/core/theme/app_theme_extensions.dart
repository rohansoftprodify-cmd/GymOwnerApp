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
    accentLime: Color(0xFF0D9488),
    accentCoral: Color(0xFFEF4444),
    onAccentLime: Color(0xFFFFFFFF),
    mutedText: Color(0xFF64748B),
  );

  static const dark = AppSemanticColors(
    cardBackground: Color(0xFF131B2E),
    accentLime: Color(0xFF2DD4BF),
    accentCoral: Color(0xFFF87171),
    onAccentLime: Color(0xFF0B0F19),
    mutedText: Color(0xFF94A3B8),
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
