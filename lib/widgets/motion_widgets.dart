import 'dart:async';

import 'package:flutter/material.dart';

import '../data/format.dart';
import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

// ---------------------------------------------------------------------------
// Entrance: fade + slide up, once
// ---------------------------------------------------------------------------

/// Fades and slides its child up the first time it is built.
///
/// Give it a stable key; rebuilds never replay the animation. Pass
/// `animate: false` for items that have already been seen.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Kz.dSlow,
    this.offset = 18,
    this.animate = true,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;
  final bool animate;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Kz.emphasized,
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.animate || Motion.reduced(context)) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: AnimatedBuilder(
        animation: _curve,
        child: widget.child,
        builder: (BuildContext context, Widget? child) {
          return Transform.translate(
            offset: Offset(0, (1 - _curve.value) * widget.offset),
            child: child,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PressScale: springy press feedback
// ---------------------------------------------------------------------------

/// Shrinks its child slightly while pressed and springs back on release.
///
/// Uses a raw [Listener], so it never competes with the child's own tap
/// handling.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.pressedScale = 0.97});

  final Widget child;
  final double pressedScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 420),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeOutBack.flipped,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: widget.pressedScale,
  ).animate(_curve);

  void _down(PointerDownEvent _) {
    if (!Motion.reduced(context)) _controller.forward();
  }

  void _up(PointerEvent _) => _controller.reverse();

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// BounceOnIncrease: badge bounce
// ---------------------------------------------------------------------------

/// Plays a quick bounce whenever [value] goes up.
class BounceOnIncrease extends StatefulWidget {
  const BounceOnIncrease({super.key, required this.value, required this.child});

  final int value;
  final Widget child;

  @override
  State<BounceOnIncrease> createState() => _BounceOnIncreaseState();
}

class _BounceOnIncreaseState extends State<BounceOnIncrease>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _scale = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1,
          end: 1.28,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.28,
          end: 0.92,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0.92,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ],
  ).animate(_controller);

  @override
  void didUpdateWidget(BounceOnIncrease oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value > oldWidget.value && !Motion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

// ---------------------------------------------------------------------------
// Shimmer skeletons
// ---------------------------------------------------------------------------

/// Sweeps a soft highlight across every [SkeletonBox] below it.
///
/// One controller drives a whole skeleton screen, and the work is isolated
/// in a [RepaintBoundary].
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _controller
        ..stop()
        ..value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color base = context.palette.surfaceAlt;
    final Color highlight = Color.lerp(
      base,
      context.isDark ? const Color(0xFF39414E) : Colors.white,
      0.75,
    )!;

    return Semantics(
      label: 'Loading',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (BuildContext context, Widget? child) {
              return ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (Rect bounds) {
                  return LinearGradient(
                    begin: const Alignment(-1, -0.3),
                    end: const Alignment(1, 0.3),
                    colors: <Color>[base, highlight, base],
                    stops: const <double>[0.35, 0.5, 0.65],
                    transform: _SlideGradient(_controller.value * 2.4 - 1.2),
                  ).createShader(bounds);
                },
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0, 0);
  }
}

/// A placeholder block for skeleton screens.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = Kz.rSm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rolling numbers
// ---------------------------------------------------------------------------

/// An odometer-style number. Each digit rolls up when the value grows and
/// down when it shrinks.
class RollingNumber extends StatefulWidget {
  const RollingNumber({
    super.key,
    required this.value,
    this.format = _plain,
    this.style,
    this.semanticsLabel,
  });

  /// Shorthand for a peso amount.
  const RollingNumber.peso({
    super.key,
    required this.value,
    this.style,
    this.semanticsLabel,
  }) : format = formatPeso;

  final int value;
  final String Function(int value) format;
  final TextStyle? style;
  final String? semanticsLabel;

  static String _plain(int value) => '$value';

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  bool _up = true;

  @override
  void didUpdateWidget(RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) _up = widget.value > oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    final String text = widget.format(widget.value);
    final TextStyle style = DefaultTextStyle.of(context).style
        .merge(widget.style)
        .copyWith(
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        );
    final Duration duration = Motion.of(
      context,
      const Duration(milliseconds: 360),
    );

    return Semantics(
      label: widget.semanticsLabel ?? text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < text.length; i++)
            _RollingChar(
              // Keyed from the right so digits stay aligned as length changes.
              key: ValueKey<int>(text.length - i),
              char: text[i],
              up: _up,
              style: style,
              duration: duration,
            ),
        ],
      ),
    );
  }
}

class _RollingChar extends StatelessWidget {
  const _RollingChar({
    super.key,
    required this.char,
    required this.up,
    required this.style,
    required this.duration,
  });

  final String char;
  final bool up;
  final TextStyle style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Kz.emphasized,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (Widget? current, List<Widget> previous) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[...previous, ?current],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          final bool incoming = child.key == ValueKey<String>(char);
          final double from = up ? 0.9 : -0.9;
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, incoming ? from : -from),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Text(char, key: ValueKey<String>(char), style: style),
      ),
    );
  }
}
