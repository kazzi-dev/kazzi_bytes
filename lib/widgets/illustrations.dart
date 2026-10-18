import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../theme/tokens.dart';

// ---------------------------------------------------------------------------
// Brand
// ---------------------------------------------------------------------------

/// Ink color of the logo, adapted to the theme.
Color kazziInk(BuildContext context) =>
    context.isDark ? const Color(0xFFF2F2F4) : KazziBrand.ink;

/// Wordmark text style: Plus Jakarta Sans ExtraBold, tightly tracked.
TextStyle kazziWordmarkStyle(BuildContext context, double fontSize) =>
    (context.text.displaySmall ?? const TextStyle()).copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: fontSize * -0.04,
      height: 1,
    );

/// The Kazzi Bytes app mark: a "k." monogram on an ink tile, matching the
/// launcher icon (tool/generate_brand_assets_test.dart).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    final bool dark = context.isDark;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF26262C) : KazziBrand.ink,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: dark ? Border.all(color: context.palette.hairline) : null,
        ),
        // Nudged down a touch: lowercase letters sit high in the line box.
        child: Padding(
          padding: EdgeInsets.only(top: size * 0.04),
          child: Text.rich(
            const TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: 'k',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: '.',
                  style: TextStyle(color: KazziBrand.dot),
                ),
              ],
            ),
            textScaler: TextScaler.noScaling,
            style: kazziWordmarkStyle(context, size * 0.58),
          ),
        ),
      ),
    );
  }
}

/// The full "kazzi." wordmark with "BYTES" underneath, as on the launch
/// screen.
class KazziWordmark extends StatelessWidget {
  const KazziWordmark({super.key, this.fontSize = 58});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Kazzi Bytes',
      header: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text.rich(
            TextSpan(
              children: <TextSpan>[
                TextSpan(
                  text: 'kazzi',
                  style: TextStyle(color: kazziInk(context)),
                ),
                const TextSpan(
                  text: '.',
                  style: TextStyle(color: KazziBrand.dot),
                ),
              ],
            ),
            textScaler: TextScaler.noScaling,
            style: kazziWordmarkStyle(context, fontSize),
          ),
          SizedBox(height: fontSize * 0.2),
          Text(
            'BYTES',
            textScaler: TextScaler.noScaling,
            style: kazziWordmarkStyle(context, fontSize * 0.28).copyWith(
              letterSpacing: fontSize * 0.28 * 0.32,
              color: context.isDark
                  ? const Color(0xFF9A9AA3)
                  : const Color(0xFF8A8A93),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mesh gradient background
// ---------------------------------------------------------------------------

/// Soft mesh-gradient backdrop made of drifting radial color blobs.
class MeshBackground extends StatefulWidget {
  const MeshBackground({
    super.key,
    this.child,
    this.animate = false,
    this.intensity = 1,
  });

  final Widget? child;
  final bool animate;

  /// 0..1, how strong the colors are.
  final double intensity;

  @override
  State<MeshBackground> createState() => _MeshBackgroundState();
}

class _MeshBackgroundState extends State<MeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animate && !Motion.reduced(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _MeshPainter(
          progress: _controller,
          base: context.theme.scaffoldBackgroundColor,
          colors: <Color>[
            context.palette.meshA,
            context.palette.meshB,
            context.palette.meshC,
          ],
          intensity: widget.intensity * (context.isDark ? 0.55 : 0.4),
        ),
        child: widget.child,
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({
    required this.progress,
    required this.base,
    required this.colors,
    required this.intensity,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color base;
  final List<Color> colors;
  final double intensity;

  static const List<Offset> _anchors = <Offset>[
    Offset(0.1, 0.05),
    Offset(0.95, 0.2),
    Offset(0.3, 0.75),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final double t = progress.value * 2 * math.pi;
    final double radius = size.longestSide * 0.62;
    for (int i = 0; i < colors.length; i++) {
      final Offset anchor = _anchors[i];
      final Offset center = Offset(
        size.width * (anchor.dx + 0.08 * math.sin(t + i * 2.1)),
        size.height * (anchor.dy + 0.06 * math.cos(t * 0.8 + i * 1.3)),
      );
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              colors[i].withValues(alpha: intensity),
              colors[i].withValues(alpha: 0),
            ],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(_MeshPainter oldDelegate) =>
      oldDelegate.base != base ||
      oldDelegate.intensity != intensity ||
      oldDelegate.colors[0] != colors[0] ||
      oldDelegate.colors[1] != colors[1] ||
      oldDelegate.colors[2] != colors[2];
}

// ---------------------------------------------------------------------------
// Floating illustration (empty states, onboarding)
// ---------------------------------------------------------------------------

/// A gently floating icon "illustration" with orbiting accent icons.
class FloatingIllustration extends StatefulWidget {
  const FloatingIllustration({
    super.key,
    required this.icon,
    this.accents = const <IconData>[],
    this.size = 168,
  });

  final IconData icon;
  final List<IconData> accents;
  final double size;

  @override
  State<FloatingIllustration> createState() => _FloatingIllustrationState();
}

class _FloatingIllustrationState extends State<FloatingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _controller.stop();
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
    final ColorScheme colors = context.colors;
    final Color tint = colors.primary;
    final double size = widget.size;

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (BuildContext context, Widget? _) {
              final double t = _controller.value * 2 * math.pi;
              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tint.withValues(alpha: 0.06),
                    ),
                  ),
                  Transform.scale(
                    scale: 1 + 0.05 * math.sin(t),
                    child: Container(
                      width: size * 0.74,
                      height: size * 0.74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tint.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, 6 * math.sin(t)),
                    child: Container(
                      width: size * 0.48,
                      height: size * 0.48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            Color.lerp(tint, Colors.white, 0.15)!,
                            tint,
                          ],
                        ),
                        boxShadow: Kz.glow(tint),
                      ),
                      child: Icon(
                        widget.icon,
                        color: colors.onPrimary,
                        size: size * 0.22,
                      ),
                    ),
                  ),
                  for (int i = 0; i < widget.accents.length; i++)
                    _accent(context, i, t),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _accent(BuildContext context, int i, double t) {
    final int count = widget.accents.length;
    final double angle =
        -math.pi * 0.75 +
        i * (math.pi * 1.5 / math.max(1, count - 1)) +
        0.12 * math.sin(t + i);
    final double radius = widget.size * 0.42;
    final double bubble = widget.size * 0.22;
    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius),
      child: Container(
        width: bubble,
        height: bubble,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colors.surface,
          border: Border.all(color: context.colors.outlineVariant),
          boxShadow: context.isDark ? null : Kz.e1(context.palette.shadow),
        ),
        child: Icon(
          widget.accents[i],
          size: bubble * 0.5,
          color: i.isEven ? context.palette.warm : context.colors.primary,
        ),
      ),
    );
  }
}

/// Friendly empty / error state with an animated illustration.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.accents = const <IconData>[],
    this.action,
  });

  final IconData icon;
  final List<IconData> accents;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Kz.s8, vertical: Kz.s6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FloatingIllustration(icon: icon, accents: accents),
            const SizedBox(height: Kz.s6),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: Kz.s2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: Kz.s6),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Celebration: animated check + confetti
// ---------------------------------------------------------------------------

/// A checkmark that is drawn stroke by stroke inside a popping disc.
class AnimatedCheck extends StatefulWidget {
  const AnimatedCheck({super.key, this.size = 120});

  final double size;

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Success',
      image: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: _CheckPainter(
            progress: _controller,
            color: context.colors.primary,
            onColor: context.colors.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({
    required this.progress,
    required this.color,
    required this.onColor,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final Color onColor;

  static const Interval _ring = Interval(0.25, 1, curve: Curves.easeOut);
  static const Interval _disc = Interval(0, 0.45, curve: Curves.easeOutBack);
  static const Interval _check = Interval(
    0.4,
    0.85,
    curve: Curves.easeInOutCubic,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress.value;
    final Offset center = size.center(Offset.zero);
    final double r = size.shortestSide / 2;

    // Expanding ripple ring.
    final double ringT = _ring.transform(t);
    if (ringT > 0 && ringT < 1) {
      canvas.drawCircle(
        center,
        r * (0.8 + 0.3 * ringT),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * (1 - ringT) + 0.5
          ..color = color.withValues(alpha: 0.5 * (1 - ringT)),
      );
    }

    // Disc with a soft glow.
    final double discR = r * 0.8 * _disc.transform(t);
    if (discR > 0) {
      canvas.drawCircle(
        center.translate(0, 6),
        discR,
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );
      canvas.drawCircle(center, discR, Paint()..color = color);
    }

    // Check stroke.
    final double checkT = _check.transform(t);
    if (checkT > 0) {
      final double s = r * 1.6;
      final Offset o = center - Offset(s / 2, s / 2);
      final Path path = Path()
        ..moveTo(o.dx + s * 0.28, o.dy + s * 0.52)
        ..lineTo(o.dx + s * 0.44, o.dy + s * 0.67)
        ..lineTo(o.dx + s * 0.73, o.dy + s * 0.37);
      final ui.PathMetric metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * checkT),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.09
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = onColor,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.onColor != onColor;
}

/// A one-shot confetti burst. Paints nothing when motion is reduced.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.particleCount = 72,
    this.origin = const Alignment(0, -0.35),
  });

  final int particleCount;
  final Alignment origin;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final List<_Particle> _particles = _generate();
  bool _started = false;

  List<_Particle> _generate() {
    final math.Random random = math.Random(7);
    return List<_Particle>.generate(widget.particleCount, (int i) {
      return _Particle(
        angle: -math.pi * (0.08 + random.nextDouble() * 0.84),
        speed: 520 + random.nextDouble() * 680,
        spin: (random.nextDouble() - 0.5) * 10,
        size: 6 + random.nextDouble() * 6,
        colorIndex: i % 5,
        circle: random.nextDouble() < 0.3,
        wobble: random.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!Motion.reduced(context)) {
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              progress: _controller,
              particles: _particles,
              origin: widget.origin,
              colors: <Color>[
                context.colors.primary,
                context.palette.warm,
                context.palette.star,
                context.palette.success,
                context.palette.meshC,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.colorIndex,
    required this.circle,
    required this.wobble,
  });

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final int colorIndex;
  final bool circle;
  final double wobble;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.particles,
    required this.origin,
    required this.colors,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final List<_Particle> particles;
  final Alignment origin;
  final List<Color> colors;

  static const double _drag = 2.4;
  static const double _gravity = 240;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress.value;
    if (t == 0 || t == 1) return;
    final double seconds = t * 2.4;
    final Offset start = origin.alongSize(size);
    final double travel = (1 - math.exp(-_drag * seconds)) / _drag;
    final double opacity = t < 0.7 ? 1 : (1 - (t - 0.7) / 0.3);
    final Paint paint = Paint();

    for (final _Particle p in particles) {
      final double x =
          start.dx +
          math.cos(p.angle) * p.speed * travel +
          14 * math.sin(seconds * 5 + p.wobble);
      final double y =
          start.dy +
          math.sin(p.angle) * p.speed * travel +
          _gravity * seconds * seconds;
      paint.color = colors[p.colorIndex].withValues(alpha: opacity);
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(p.spin * seconds);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.55,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}

/// A softly pulsing halo behind the current step of an order timeline.
class PulseHalo extends StatefulWidget {
  const PulseHalo({
    super.key,
    required this.child,
    required this.color,
    this.active = true,
  });

  final Widget child;
  final Color color;
  final bool active;

  @override
  State<PulseHalo> createState() => _PulseHaloState();
}

class _PulseHaloState extends State<PulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PulseHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.active && !Motion.reduced(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              if (widget.active)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.45 * (1 - t)),
                  spreadRadius: 10 * t,
                ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
