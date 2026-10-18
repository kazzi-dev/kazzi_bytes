import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'motion_widgets.dart';

// ---------------------------------------------------------------------------
// LoadingButton: pill button that morphs into a spinner
// ---------------------------------------------------------------------------

class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.leading,
    this.trailing,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? leading;
  final Widget? trailing;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final bool enabled = onPressed != null && !loading;
    final Duration duration = Motion.of(context, Kz.dSlow);
    final Color background = onPressed == null
        ? colors.onSurface.withValues(alpha: 0.12)
        : colors.primary;
    final Color foreground = onPressed == null
        ? colors.onSurface.withValues(alpha: 0.45)
        : colors.onPrimary;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double fullWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 320;
        return Semantics(
          button: true,
          enabled: enabled,
          label: loading ? '$label, in progress' : label,
          excludeSemantics: true,
          child: Center(
            heightFactor: 1,
            child: AnimatedContainer(
              duration: duration,
              curve: Kz.emphasized,
              width: loading ? height : fullWidth,
              height: height,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: onPressed == null || context.isDark
                    ? null
                    : Kz.glow(colors.primary, strength: 0.8),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: enabled
                      ? () {
                          HapticFeedback.lightImpact();
                          onPressed!();
                        }
                      : null,
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Kz.dMedium),
                    child: loading
                        ? SizedBox.square(
                            key: const ValueKey<String>('spinner'),
                            dimension: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              strokeCap: StrokeCap.round,
                              color: foreground,
                            ),
                          )
                        : ClipRect(
                            key: const ValueKey<String>('label'),
                            // Lays the label out at full width so it never
                            // overflows while the button shrinks.
                            child: OverflowBox(
                              minWidth: fullWidth,
                              maxWidth: fullWidth,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Kz.s6,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: DefaultTextStyle.merge(
                                    style: context.text.labelLarge?.copyWith(
                                      fontSize: 16,
                                      color: foreground,
                                    ),
                                    child: IconTheme.merge(
                                      data: IconThemeData(
                                        color: foreground,
                                        size: 20,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          if (leading != null) ...<Widget>[
                                            leading!,
                                            const SizedBox(width: Kz.s2),
                                          ],
                                          Text(label),
                                          if (trailing != null) ...<Widget>[
                                            const SizedBox(width: Kz.s2),
                                            trailing!,
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// SlidingSegmented: segmented control with a sliding thumb
// ---------------------------------------------------------------------------

class Segment<T> {
  const Segment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

class SlidingSegmented<T> extends StatelessWidget {
  const SlidingSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final List<Segment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final int selected = segments.indexWhere(
      (Segment<T> s) => s.value == value,
    );
    final Duration duration = Motion.of(context, Kz.dSlow);

    return Container(
      padding: const EdgeInsets.all(Kz.s1),
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(Kz.rPill),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double segmentWidth = constraints.maxWidth / segments.length;
          return Stack(
            children: <Widget>[
              AnimatedPositioned(
                duration: duration,
                curve: Kz.emphasized,
                left: segmentWidth * selected.clamp(0, segments.length - 1),
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(Kz.rPill),
                    boxShadow: Kz.e1(context.palette.shadow),
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (int i = 0; i < segments.length; i++)
                    Expanded(
                      child: _SegmentButton(
                        segment: segments[i],
                        selected: i == selected,
                        duration: duration,
                        onTap: () {
                          if (i == selected) return;
                          HapticFeedback.selectionClick();
                          onChanged(segments[i].value);
                        },
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.segment,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final Segment<dynamic> segment;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected
        ? context.colors.onSurface
        : context.colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Kz.minTap),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Kz.s2,
                vertical: Kz.s2,
              ),
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: duration,
                builder: (BuildContext context, Color? c, Widget? _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (segment.icon != null) ...<Widget>[
                        Icon(segment.icon, size: 18, color: c),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          segment.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelLarge?.copyWith(color: c),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// QtyStepper
// ---------------------------------------------------------------------------

class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
    this.itemName = 'item',
    this.removeDeletes = false,
  });

  final int quantity;
  final VoidCallback onAdd;

  /// Null disables the minus button (e.g. a minimum of one).
  final VoidCallback? onRemove;
  final String itemName;

  /// Shows a trash icon when the next tap removes the item.
  final bool removeDeletes;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;

    Widget button(IconData icon, String tooltip, VoidCallback? onPressed) {
      return IconButton(
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed();
              },
        tooltip: tooltip,
        icon: AnimatedSwitcher(
          duration: Motion.of(context, Kz.dFast),
          child: Icon(icon, key: ValueKey<IconData>(icon), size: 20),
        ),
        style: IconButton.styleFrom(
          foregroundColor: colors.primary,
          shape: const CircleBorder(),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Kz.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          button(
            removeDeletes && quantity <= 1
                ? Icons.delete_outline_rounded
                : Icons.remove_rounded,
            removeDeletes && quantity <= 1
                ? 'Remove $itemName'
                : 'Remove one $itemName',
            onRemove,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 22),
            child: Center(
              widthFactor: 1,
              child: RollingNumber(
                value: quantity,
                semanticsLabel: 'Quantity $quantity',
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          button(Icons.add_rounded, 'Add one $itemName', onAdd),
        ],
      ),
    );
  }
}
