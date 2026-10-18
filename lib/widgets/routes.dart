import 'package:flutter/material.dart';

import '../theme/motion.dart';
import '../theme/tokens.dart';

enum KzTransition {
  /// Horizontal shared-axis: for forward flows (Menu → Cart → Checkout).
  sharedAxis,

  /// Fade-through with a gentle scale: for switching contexts
  /// (Splash → Home, Auth → Home, Checkout → Success).
  fadeThrough,
}

/// Full-screen page route with Kazzi Bytes motion.
class KzRoute<T> extends PageRoute<T> {
  KzRoute({
    required this.builder,
    this.style = KzTransition.sharedAxis,
    super.settings,
  });

  final WidgetBuilder builder;
  final KzTransition style;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 340);

  // Translucent routes (the dish sheet) must not fade the page beneath.
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is PageRoute && nextRoute.opaque;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.reduced(context)) return child;
    return _KzPageTransition(
      style: style,
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _KzPageTransition extends StatefulWidget {
  const _KzPageTransition({
    required this.style,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final KzTransition style;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<_KzPageTransition> createState() => _KzPageTransitionState();
}

class _KzPageTransitionState extends State<_KzPageTransition> {
  late CurvedAnimation _exit;
  late CurvedAnimation _exitSlide;
  late CurvedAnimation _enter;

  @override
  void initState() {
    super.initState();
    _create();
  }

  @override
  void didUpdateWidget(_KzPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _disposeCurves();
      _create();
    }
  }

  void _create() {
    // Outgoing: this page fades and drifts left while the next one arrives.
    _exit = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: const Interval(0, 0.35, curve: Curves.easeIn),
    );
    _exitSlide = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: Kz.standard,
    );
    // Incoming.
    _enter = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.3, 1, curve: Kz.emphasized),
      reverseCurve: const Interval(0.3, 1, curve: Curves.easeIn),
    );
  }

  void _disposeCurves() {
    _exit.dispose();
    _exitSlide.dispose();
    _enter.dispose();
  }

  @override
  void dispose() {
    _disposeCurves();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> enter = _enter;

    // The scaffold-colored backdrop sits outside the exit fade, so a page
    // being covered fades its content into its own background instead of
    // into black.
    final Widget page = ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0).animate(_exit),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.05, 0),
          ).animate(_exitSlide),
          child: widget.child,
        ),
      ),
    );

    return switch (widget.style) {
      KzTransition.sharedAxis => FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(enter),
          child: page,
        ),
      ),
      KzTransition.fadeThrough => FadeTransition(
        opacity: enter,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(enter),
          child: page,
        ),
      ),
    };
  }
}

/// A translucent route that slides a sheet up from the bottom.
///
/// Unlike showModalBottomSheet this is a [PageRoute], so Hero animations
/// fly from the menu card into the sheet.
class SheetRoute<T> extends PageRoute<T> {
  SheetRoute({required this.builder, super.settings});

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.45);

  @override
  String? get barrierLabel => 'Close';

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 440);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (Motion.reduced(context)) return child;
    final CurvedAnimation curve = _curve ??= CurvedAnimation(
      parent: animation,
      curve: Kz.emphasized,
      reverseCurve: Curves.easeInCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curve),
      child: child,
    );
  }

  CurvedAnimation? _curve;

  @override
  void dispose() {
    _curve?.dispose();
    super.dispose();
  }
}
