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
  final Color accentLime;
  final Color accentCoral;
  final Color onAccentLime;
  final Color mutedText;

  static const light = AppSemanticColors(
    cardBackground: Color(0xFFFFFFFF),
    accentLime: Color(0xFFD4FF00),
    accentCoral: Color(0xFFFF6B5B),
    onAccentLime: Color(0xFF000000),
    mutedText: Color(0xFF4A6072),
  );

  static const dark = AppSemanticColors(
    cardBackground: Color(0xFF1E1E1E),
    accentLime: Color(0xFFC6FF00),
    accentCoral: Color(0xFFFF6B5B),
    onAccentLime: Color(0xFF000000),
    mutedText: Color(0xFF9AA8B5),
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
