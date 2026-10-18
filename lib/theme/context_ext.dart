import 'package:flutter/material.dart';

import 'palette.dart';

/// Short-hands for the theme lookups every widget needs.
extension KzContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  KzPalette get palette =>
      Theme.of(this).extension<KzPalette>() ?? KzPalette.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Current text scale factor (1.0 = default). Used to size fixed-height
  /// regions such as pinned headers so large text never overflows.
  double get textScale => MediaQuery.textScalerOf(this).scale(16) / 16;
}
