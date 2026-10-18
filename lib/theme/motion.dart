import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Reduced-motion aware timing helpers.
///
/// Every animation in the app asks [Motion] for its duration, so turning on
/// "Remove animations" (Android) or "Reduce motion" (iOS) makes the UI snap
/// straight to its end state.
abstract final class Motion {
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration base) =>
      reduced(context) ? Duration.zero : base;

  /// Delay for the [index]th item of a staggered list.
  static Duration stagger(
    BuildContext context,
    int index, {
    Duration step = Kz.stagger,
    int maxSteps = 10,
  }) {
    if (reduced(context) || index > maxSteps) return Duration.zero;
    return step * index;
  }
}
