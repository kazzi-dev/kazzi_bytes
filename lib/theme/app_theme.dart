import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';
import 'tokens.dart';

/// Builds the light and dark themes from one shared definition so UI code
/// never needs separate branches per theme.
abstract final class AppTheme {
  static final ThemeData _light = _build(Brightness.light);
  static final ThemeData _dark = _build(Brightness.dark);

  static ThemeData light() => _light;
  static ThemeData dark() => _dark;

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final KzPalette palette = isDark ? KzPalette.dark : KzPalette.light;

    final Color accent = isDark ? KazziColors.brandOnDark : KazziColors.brand;
    final Color background = isDark
        ? KazziColors.darkBackground
        : KazziColors.lightBackground;
    final Color surface = isDark
        ? KazziColors.darkSurface
        : KazziColors.lightSurface;
    final Color border = isDark
        ? KazziColors.darkBorder
        : KazziColors.lightBorder;
    final Color onSurface = isDark ? KazziColors.darkText : KazziColors.navy;
    final Color muted = isDark ? KazziColors.darkMuted : KazziColors.lightMuted;
    final Color error = isDark
        ? const Color(0xFFFF8A80)
        : const Color(0xFFD92D20);

    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: KazziColors.brand,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: isDark ? const Color(0xFF071634) : Colors.white,
          primaryContainer: Color.alphaBlend(
            accent.withValues(alpha: isDark ? 0.20 : 0.12),
            surface,
          ),
          onPrimaryContainer: isDark
              ? const Color(0xFFD6E3FF)
              : const Color(0xFF0B2E8A),
          secondary: palette.warm,
          surface: surface,
          onSurface: onSurface,
          onSurfaceVariant: muted,
          surfaceContainerLowest: background,
          surfaceContainerLow: surface,
          surfaceContainer: surface,
          surfaceContainerHigh: palette.surfaceAlt,
          surfaceContainerHighest: palette.surfaceAlt,
          outline: border,
          outlineVariant: border,
          error: error,
          onError: isDark ? const Color(0xFF3A0A06) : Colors.white,
          inverseSurface: isDark
              ? const Color(0xFFE7EBF2)
              : const Color(0xFF151A23),
          onInverseSurface: isDark
              ? const Color(0xFF151920)
              : const Color(0xFFF1F4F9),
          inversePrimary: isDark ? KazziColors.brand : KazziColors.brandOnDark,
          shadow: palette.shadow,
          surfaceTint: Colors.transparent,
        );

    final TextTheme text = _withFont(
      _textTheme(
        ThemeData(brightness: brightness, useMaterial3: true).textTheme,
        onSurface,
      ),
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(Kz.rMd),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: text,
      splashFactory: InkRipple.splashFactory,
      extensions: <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: onSurface,
        titleTextStyle: text.titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: Kz.s6),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: Kz.s6),
          shape: const StadiumBorder(),
          foregroundColor: onSurface,
          side: BorderSide(color: border),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(Kz.minTap, Kz.minTap),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? palette.surfaceAlt : surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Kz.s4,
          vertical: Kz.s4,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: muted),
        labelStyle: text.bodyLarge?.copyWith(color: muted),
        floatingLabelStyle: text.bodyMedium?.copyWith(color: accent),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(accent, 1.6),
        errorBorder: inputBorder(error),
        focusedErrorBorder: inputBorder(error, 1.6),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: scheme.inversePrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Kz.rMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Kz.rXl),
        ),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: muted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Kz.rXl)),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: palette.surfaceAlt,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(Kz.rXs),
        ),
        textStyle: text.labelMedium?.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }

  /// Applies Plus Jakarta Sans to every style. Mapped style by style (rather
  /// than GoogleFonts.plusJakartaSansTextTheme) so each weight is loaded.
  static TextTheme _withFont(TextTheme t) {
    TextStyle? font(TextStyle? style) =>
        style == null ? null : GoogleFonts.plusJakartaSans(textStyle: style);
    return t.copyWith(
      displayLarge: font(t.displayLarge),
      displayMedium: font(t.displayMedium),
      displaySmall: font(t.displaySmall),
      headlineLarge: font(t.headlineLarge),
      headlineMedium: font(t.headlineMedium),
      headlineSmall: font(t.headlineSmall),
      titleLarge: font(t.titleLarge),
      titleMedium: font(t.titleMedium),
      titleSmall: font(t.titleSmall),
      bodyLarge: font(t.bodyLarge),
      bodyMedium: font(t.bodyMedium),
      bodySmall: font(t.bodySmall),
      labelLarge: font(t.labelLarge),
      labelMedium: font(t.labelMedium),
      labelSmall: font(t.labelSmall),
    );
  }

  /// A tight, modern type scale.
  static TextTheme _textTheme(TextTheme t, Color color) {
    return t
        .copyWith(
          displaySmall: t.displaySmall?.copyWith(
            fontSize: Kz.tDisplay,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            height: 1.08,
          ),
          headlineMedium: t.headlineMedium?.copyWith(
            fontSize: Kz.tHeadline,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.15,
          ),
          headlineSmall: t.headlineSmall?.copyWith(
            fontSize: Kz.tHeadlineSm,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.2,
          ),
          titleLarge: t.titleLarge?.copyWith(
            fontSize: Kz.tTitle,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            height: 1.25,
          ),
          titleMedium: t.titleMedium?.copyWith(
            fontSize: Kz.tTitleMd,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            height: 1.3,
          ),
          titleSmall: t.titleSmall?.copyWith(
            fontSize: Kz.tTitleSm,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            height: 1.3,
          ),
          bodyLarge: t.bodyLarge?.copyWith(
            fontSize: Kz.tBody,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          bodyMedium: t.bodyMedium?.copyWith(
            fontSize: Kz.tBodyMd,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
          bodySmall: t.bodySmall?.copyWith(
            fontSize: Kz.tBodySm,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          labelLarge: t.labelLarge?.copyWith(
            fontSize: Kz.tLabel,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          labelMedium: t.labelMedium?.copyWith(
            fontSize: Kz.tLabelMd,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          labelSmall: t.labelSmall?.copyWith(
            fontSize: Kz.tLabelSm,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        )
        .apply(bodyColor: color, displayColor: color);
  }
}
