// Spacing, radius and sizing tokens shared by all layouts.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 20;

  // Minimum touch target for elderly users (AGENTS.md §1).
  static const double minTouchTarget = 48;
  static const double buttonHeight = 56;
  static const double listItemMinHeight = 72;

  static const double tabletBreakpoint = 600;
  static const double maxContentWidth = 1100;
}
