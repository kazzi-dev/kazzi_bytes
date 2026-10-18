import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../data/format.dart';
import '../data/models.dart';
import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'app_scope.dart';
import 'motion_widgets.dart';
import 'surfaces.dart';

// ---------------------------------------------------------------------------
// Header cart button with a bouncing badge
// ---------------------------------------------------------------------------

class CartIconButton extends StatelessWidget {
  const CartIconButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.cart,
      builder: (BuildContext context, Widget? _) {
        final int count = scope.cart.itemCount;
        return BounceOnIncrease(
          value: count,
          child: KeyedSubtree(
            key: scope.cartTargetKey,
            child: HeaderIconButton(
              tooltip: count == 0
                  ? 'Open cart'
                  : 'Open cart, ${pluralItems(count)}',
              onPressed: onPressed,
              icon: Badge.count(
                count: count,
                isLabelVisible: count > 0,
                backgroundColor: context.colors.primary,
                textColor: context.colors.onPrimary,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Floating cart bar
// ---------------------------------------------------------------------------

/// Slides the cart bar up with a slight overshoot when it appears.
class CartBarHost extends StatefulWidget {
  const CartBarHost({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  State<CartBarHost> createState() => _CartBarHostState();
}

class _CartBarHostState extends State<CartBarHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 260),
    value: widget.visible ? 1 : 0,
  );
  late final CurvedAnimation _size = CurvedAnimation(
    parent: _controller,
    curve: Kz.emphasized,
    reverseCurve: Curves.easeInCubic,
  );
  late final CurvedAnimation _slide = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
  );

  @override
  void didUpdateWidget(CartBarHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    if (Motion.reduced(context)) {
      _controller.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _size.dispose();
    _slide.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: ExcludeSemantics(
        excluding: !widget.visible,
        child: SizeTransition(
          sizeFactor: _size,
          alignment: Alignment.topCenter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.9),
              end: Offset.zero,
            ).animate(_slide),
            child: FadeTransition(opacity: _controller, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class CartBar extends StatelessWidget {
  const CartBar({
    super.key,
    required this.count,
    required this.total,
    required this.onTap,
  });

  final int count;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextStyle? style = context.text.titleMedium?.copyWith(
      color: colors.onPrimary,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Kz.s4, Kz.s2, Kz.s4, Kz.s2),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Kz.maxReadingWidth),
          child: Semantics(
            button: true,
            label: 'View cart, ${pluralItems(count)}, ${formatPeso(total)}',
            excludeSemantics: true,
            child: PressScale(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Kz.rLg),
                  boxShadow: context.isDark ? null : Kz.glow(colors.primary),
                ),
                child: Material(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(Kz.rLg),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(Kz.rLg),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 60),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Kz.s3,
                          vertical: Kz.s2,
                        ),
                        child: Row(
                          children: <Widget>[
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Kz.s2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.onPrimary.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(Kz.rPill),
                              ),
                              child: RollingNumber(
                                value: count,
                                style: context.text.labelLarge?.copyWith(
                                  color: colors.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: Kz.s3),
                            Expanded(
                              child: Text(
                                'View cart',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: RollingNumber.peso(
                                value: total,
                                style: style?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: Kz.s1),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: colors.onPrimary,
                            ),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Fly to cart
// ---------------------------------------------------------------------------

/// Launches a small dot from a widget to the header cart icon.
abstract final class FlyToCart {
  static void launch(BuildContext from, {Color? color}) {
    if (Motion.reduced(from)) return;
    final AppScope scope = AppScope.of(from);
    // Only the Home tab shows the header cart icon.
    if (scope.tabIndex.value != 0) return;

    final OverlayState? overlay = Overlay.maybeOf(from, rootOverlay: true);
    final RenderObject? startObject = from.findRenderObject();
    final RenderObject? endObject = scope.cartTargetKey.currentContext
        ?.findRenderObject();
    final RenderObject? overlayObject = overlay?.context.findRenderObject();
    if (overlay == null ||
        startObject is! RenderBox ||
        endObject is! RenderBox ||
        overlayObject is! RenderBox ||
        !startObject.attached ||
        !endObject.attached) {
      return;
    }

    final Offset start = overlayObject.globalToLocal(
      startObject.localToGlobal(startObject.size.center(Offset.zero)),
    );
    final Offset end = overlayObject.globalToLocal(
      endObject.localToGlobal(endObject.size.center(Offset.zero)),
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext context) => _FlyingDot(
        start: start,
        end: end,
        color: color ?? Theme.of(from).colorScheme.primary,
        onDone: entry.remove,
      ),
    );
    overlay.insert(entry);
  }
}

class _FlyingDot extends StatefulWidget {
  const _FlyingDot({
    required this.start,
    required this.end,
    required this.color,
    required this.onDone,
  });

  final Offset start;
  final Offset end;
  final Color color;
  final VoidCallback onDone;

  @override
  State<_FlyingDot> createState() => _FlyingDotState();
}

class _FlyingDotState extends State<_FlyingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenCompleteOrCancel(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Offset start = widget.start;
    final Offset end = widget.end;
    final Offset control = Offset(
      start.dx + (end.dx - start.dx) * 0.25,
      math.min(start.dy, end.dy) - 90,
    );

    return IgnorePointer(
      child: Stack(
        children: <Widget>[
          AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              final double t = Curves.easeInOutCubic.transform(
                _controller.value,
              );
              final double u = 1 - t;
              final Offset p =
                  start * (u * u) + control * (2 * u * t) + end * (t * t);
              final double size = lerpDouble(22, 10, t)!;
              final double opacity = t > 0.85 ? (1 - t) / 0.15 : 1;
              return Positioned(
                left: p.dx - size / 2,
                top: p.dy - size / 2,
                width: size,
                height: size,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color,
                      boxShadow: Kz.glow(widget.color, strength: 1.4),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Price breakdown
// ---------------------------------------------------------------------------

class PriceBreakdownCard extends StatelessWidget {
  const PriceBreakdownCard({
    super.key,
    required this.breakdown,
    this.itemCount,
    this.promoCode,
  });

  final PriceBreakdown breakdown;
  final int? itemCount;
  final String? promoCode;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final TextStyle? labelStyle = context.text.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final TextStyle? valueStyle = context.text.bodyLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );

    Widget row(String label, Widget value, {Widget? info}) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                Flexible(child: Text(label, style: labelStyle)),
                ?info,
              ],
            ),
          ),
          const SizedBox(width: Kz.s3),
          value,
        ],
      );
    }

    return SurfaceCard(
      padding: const EdgeInsets.all(Kz.s5),
      child: Column(
        children: <Widget>[
          row(
            itemCount == null
                ? 'Subtotal'
                : 'Subtotal · ${pluralItems(itemCount!)}',
            RollingNumber.peso(value: breakdown.subtotal, style: valueStyle),
          ),
          const SizedBox(height: Kz.s3),
          row(
            'Service fee',
            RollingNumber.peso(value: breakdown.serviceFee, style: valueStyle),
            info: Tooltip(
              message: '5% of your subtotal (₱10 minimum).',
              triggerMode: TooltipTriggerMode.tap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Kz.s1),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: colors.onSurfaceVariant,
                  semanticLabel: 'About the service fee',
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Kz.dMedium),
            curve: Kz.standard,
            child: breakdown.discount > 0
                ? Padding(
                    padding: const EdgeInsets.only(top: Kz.s3),
                    child: row(
                      promoCode == null ? 'Discount' : 'Discount · $promoCode',
                      RollingNumber(
                        value: breakdown.discount,
                        format: (int v) => '−${formatPeso(v)}',
                        style: valueStyle?.copyWith(
                          color: context.palette.success,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: Kz.s4),
          const Divider(),
          const SizedBox(height: Kz.s4),
          Row(
            children: <Widget>[
              Text('Total', style: context.text.titleMedium),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: RollingNumber.peso(
                  value: breakdown.total,
                  style: context.text.headlineSmall?.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
