import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Kazzi Bytes design tokens.
///
/// Every spacing, radius, elevation, type size and motion value in the app
/// comes from here, so the whole UI stays on one 4/8pt rhythm.
abstract final class Kz {
  // -------------------------------------------------------------------------
  // Spacing (4pt base grid)
  // -------------------------------------------------------------------------
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 28;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;

  /// Horizontal page gutter.
  static const double gutter = s5;

  // -------------------------------------------------------------------------
  // Radius
  // -------------------------------------------------------------------------
  static const double rXs = 8;
  static const double rSm = 12;
  static const double rMd = 16;
  static const double rLg = 22;
  static const double rXl = 28;
  static const double rPill = 999;

  // -------------------------------------------------------------------------
  // Layout
  // -------------------------------------------------------------------------
  static const double minTap = 48;
  static const double maxContentWidth = 1080;
  static const double maxReadingWidth = 640;
  static const double maxFormWidth = 460;
  static const double gridBreakpoint = 720;

  // -------------------------------------------------------------------------
  // Type scale (logical pixels, before text scaling)
  // -------------------------------------------------------------------------
  static const double tDisplay = 38;
  static const double tHeadline = 28;
  static const double tHeadlineSm = 24;
  static const double tTitle = 20;
  static const double tTitleMd = 16;
  static const double tTitleSm = 14;
  static const double tBody = 15.5;
  static const double tBodyMd = 14;
  static const double tBodySm = 12.5;
  static const double tLabel = 14;
  static const double tLabelMd = 12;
  static const double tLabelSm = 11;

  // -------------------------------------------------------------------------
  // Motion
  // -------------------------------------------------------------------------
  static const Duration dFast = Duration(milliseconds: 150);
  static const Duration dMedium = Duration(milliseconds: 250);
  static const Duration dSlow = Duration(milliseconds: 400);
  static const Duration dSlower = Duration(milliseconds: 600);
  static const Duration stagger = Duration(milliseconds: 40);

  /// Material 3 "emphasized decelerate": fast start, long soft landing.
  static const Curve emphasized = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;

  // -------------------------------------------------------------------------
  // Elevation (soft, diffused shadows; callers skip them in dark mode)
  // -------------------------------------------------------------------------
  static List<BoxShadow> e1(Color shadow) => <BoxShadow>[
    BoxShadow(
      color: shadow.withValues(alpha: 0.05),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> e2(Color shadow) => <BoxShadow>[
    BoxShadow(
      color: shadow.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: shadow.withValues(alpha: 0.10),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> e3(Color shadow) => <BoxShadow>[
    BoxShadow(
      color: shadow.withValues(alpha: 0.18),
      blurRadius: 48,
      offset: const Offset(0, 20),
    ),
  ];

  /// Colored glow used behind brand elements.
  static List<BoxShadow> glow(Color color, {double strength = 1}) =>
      <BoxShadow>[
        BoxShadow(
          color: color.withValues(alpha: 0.32 * strength),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];
}
