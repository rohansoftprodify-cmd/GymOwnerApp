import 'package:flutter/material.dart';

/// Tablet / large-screen helpers. Phone layouts stay as designed;
/// tablets get a gentle scale so text and cards are readable.
abstract final class AppResponsive {
  static const double tabletBreakpoint = 600;
  static const double largeTabletBreakpoint = 900;

  static bool isTablet(Size size) => size.shortestSide >= tabletBreakpoint;

  static bool isLargeTablet(Size size) => size.shortestSide >= largeTabletBreakpoint;

  /// Multiplier for text / UI comfort on larger screens.
  static double uiScale(Size size) {
    final shortest = size.shortestSide;
    if (shortest >= largeTabletBreakpoint) return 1.28;
    if (shortest >= tabletBreakpoint) return 1.18;
    return 1.0;
  }

  static VisualDensity visualDensity(Size size) {
    if (isTablet(size)) return VisualDensity.comfortable;
    return VisualDensity.compact;
  }

  static EdgeInsetsGeometry pagePadding(Size size, {double phone = 16}) {
    if (isLargeTablet(size)) {
      return EdgeInsets.symmetric(horizontal: phone * 2.2, vertical: phone * 0.5);
    }
    if (isTablet(size)) {
      return EdgeInsets.symmetric(horizontal: phone * 1.6, vertical: phone * 0.35);
    }
    return EdgeInsets.symmetric(horizontal: phone);
  }
}
