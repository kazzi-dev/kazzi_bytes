import 'package:flutter/material.dart';

/// Logo colors: the "kazzi." dot wordmark.
abstract final class KazziBrand {
  /// Near-black ink of the wordmark and icon tile.
  static const Color ink = Color(0xFF1B1B1F);

  /// The orange "bite" dot.
  static const Color dot = Color(0xFFFF5A1F);
}

/// Raw brand colors. UI code reads colors from [ColorScheme] or [KzPalette]
/// so both themes stay in sync.
abstract final class KazziColors {
  // Electric blue accent, plus a softened variant for dark mode.
  static const Color brand = Color(0xFF1A5FFF);
  static const Color brandOnDark = Color(0xFF79A6FF);

  // Light mode neutrals.
  static const Color lightBackground = Color(0xFFF5F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEEF2F8);
  static const Color lightBorder = Color(0xFFE2E7F0);
  static const Color navy = Color(0xFF0B1B3A);
  static const Color lightMuted = Color(0xFF56627A);

  // Dark mode: deep blue-tinted neutrals, never pure black or pure white.
  static const Color darkBackground = Color(0xFF0D1015);
  static const Color darkSurface = Color(0xFF151920);
  static const Color darkSurfaceAlt = Color(0xFF1D222B);
  static const Color darkBorder = Color(0xFF282F3A);
  static const Color darkText = Color(0xFFE7EBF2);
  static const Color darkMuted = Color(0xFF9BA5B6);
}

/// Extra semantic colors that [ColorScheme] has no slot for.
///
/// Registered as a [ThemeExtension] so it interpolates smoothly when the
/// theme animates between light and dark.
@immutable
class KzPalette extends ThemeExtension<KzPalette> {
  const KzPalette({
    required this.surfaceAlt,
    required this.warm,
    required this.warmContainer,
    required this.onWarmContainer,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.heart,
    required this.star,
    required this.shadow,
    required this.glass,
    required this.hairline,
    required this.meshA,
    required this.meshB,
    required this.meshC,
  });

  static const KzPalette light = KzPalette(
    surfaceAlt: KazziColors.lightSurfaceAlt,
    warm: Color(0xFFFF7A3D),
    warmContainer: Color(0xFFFFEDE3),
    onWarmContainer: Color(0xFFA63A0C),
    success: Color(0xFF15803D),
    successContainer: Color(0xFFDCFCE7),
    onSuccessContainer: Color(0xFF14532D),
    heart: Color(0xFFE5484D),
    star: Color(0xFFF5A524),
    shadow: KazziColors.navy,
    glass: Color(0xC7FFFFFF),
    hairline: Color(0x1A0B1B3A),
    meshA: Color(0xFF1A5FFF),
    meshB: Color(0xFFFF7A3D),
    meshC: Color(0xFF8B5CF6),
  );

  static const KzPalette dark = KzPalette(
    surfaceAlt: KazziColors.darkSurfaceAlt,
    warm: Color(0xFFFF9B6A),
    warmContainer: Color(0xFF3A2219),
    onWarmContainer: Color(0xFFFFC4A6),
    success: Color(0xFF4ADE80),
    successContainer: Color(0xFF14301F),
    onSuccessContainer: Color(0xFFBBF7D0),
    heart: Color(0xFFFF6B6F),
    star: Color(0xFFFFC14D),
    shadow: Color(0xFF000000),
    glass: Color(0xBF151920),
    hairline: Color(0x1FFFFFFF),
    meshA: Color(0xFF2F6BFF),
    meshB: Color(0xFFE5622B),
    meshC: Color(0xFF7C4DFF),
  );

  final Color surfaceAlt;
  final Color warm;
  final Color warmContainer;
  final Color onWarmContainer;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color heart;
  final Color star;
  final Color shadow;

  /// Translucent surface for frosted-glass bars.
  final Color glass;

  /// 1px separators on glass and cards.
  final Color hairline;

  // Mesh gradient blobs.
  final Color meshA;
  final Color meshB;
  final Color meshC;

  @override
  KzPalette copyWith({
    Color? surfaceAlt,
    Color? warm,
    Color? warmContainer,
    Color? onWarmContainer,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? heart,
    Color? star,
    Color? shadow,
    Color? glass,
    Color? hairline,
    Color? meshA,
    Color? meshB,
    Color? meshC,
  }) {
    return KzPalette(
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      warm: warm ?? this.warm,
      warmContainer: warmContainer ?? this.warmContainer,
      onWarmContainer: onWarmContainer ?? this.onWarmContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      heart: heart ?? this.heart,
      star: star ?? this.star,
      shadow: shadow ?? this.shadow,
      glass: glass ?? this.glass,
      hairline: hairline ?? this.hairline,
      meshA: meshA ?? this.meshA,
      meshB: meshB ?? this.meshB,
      meshC: meshC ?? this.meshC,
    );
  }

  @override
  KzPalette lerp(ThemeExtension<KzPalette>? other, double t) {
    if (other is! KzPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return KzPalette(
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      warm: mix(warm, other.warm),
      warmContainer: mix(warmContainer, other.warmContainer),
      onWarmContainer: mix(onWarmContainer, other.onWarmContainer),
      success: mix(success, other.success),
      successContainer: mix(successContainer, other.successContainer),
      onSuccessContainer: mix(onSuccessContainer, other.onSuccessContainer),
      heart: mix(heart, other.heart),
      star: mix(star, other.star),
      shadow: mix(shadow, other.shadow),
      glass: mix(glass, other.glass),
      hairline: mix(hairline, other.hairline),
      meshA: mix(meshA, other.meshA),
      meshB: mix(meshB, other.meshB),
      meshC: mix(meshC, other.meshC),
    );
  }
}
