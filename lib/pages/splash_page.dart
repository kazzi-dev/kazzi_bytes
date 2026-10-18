import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/palette.dart';
import '../widgets/app_scope.dart';
import '../widgets/illustrations.dart';
import '../widgets/routes.dart';
import 'auth_page.dart';
import 'onboarding_page.dart';
import 'shell_page.dart';

/// Picks up exactly where the native launch screen leaves off (same
/// wordmark, same background), lets the orange dot hop, then fades through
/// to onboarding, sign-in or the menu.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  /// Background of the native launch screen (see pubspec.yaml), so the
  /// hand-off from native to Flutter is invisible.
  static Color background(BuildContext context) =>
      context.isDark ? const Color(0xFF111114) : Colors.white;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const double _fontSize = 58;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// The dot jumps up, squashes on landing and settles.
  late final Animation<double> _dotLift = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: ConstantTween<double>(0), weight: 20),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 0,
          end: -0.55,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 28,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: -0.55,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 22,
      ),
      TweenSequenceItem<double>(tween: ConstantTween<double>(0), weight: 30),
    ],
  ).animate(_controller);

  late final Animation<double> _dotSquash = TweenSequence<double>(
    <TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 70),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1,
          end: 1.35,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(
          begin: 1.35,
          end: 1,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 20,
      ),
    ],
  ).animate(_controller);

  bool _started = false;
  bool _navigated = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _timer = Timer(const Duration(milliseconds: 500), _goNext);
    } else {
      _controller.forward().whenComplete(() {
        _timer = Timer(const Duration(milliseconds: 150), _goNext);
      });
    }
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;
    final AppScope scope = AppScope.of(context);
    final Widget next = !scope.auth.onboardingSeen
        ? const OnboardingPage()
        : scope.auth.isSignedIn
        ? const ShellPage()
        : const AuthPage();
    Navigator.of(context).pushReplacement(
      KzRoute<void>(
        builder: (BuildContext context) => next,
        style: KzTransition.fadeThrough,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = kazziWordmarkStyle(context, _fontSize);
    final TextStyle sub = kazziWordmarkStyle(context, _fontSize * 0.28)
        .copyWith(
          letterSpacing: _fontSize * 0.28 * 0.32,
          color: context.isDark
              ? const Color(0xFF9A9AA3)
              : const Color(0xFF8A8A93),
        );

    return Scaffold(
      backgroundColor: SplashPage.background(context),
      body: Center(
        child: Semantics(
          label: 'Kazzi Bytes',
          header: true,
          excludeSemantics: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    'kazzi',
                    textScaler: TextScaler.noScaling,
                    style: style.copyWith(color: kazziInk(context)),
                  ),
                  AnimatedBuilder(
                    animation: _controller,
                    child: Text(
                      '.',
                      textScaler: TextScaler.noScaling,
                      style: style.copyWith(color: KazziBrand.dot),
                    ),
                    builder: (BuildContext context, Widget? dot) {
                      return Transform.translate(
                        // Matches the letter spacing inside "kazzi.".
                        offset: Offset(
                          _fontSize * -0.04,
                          _dotLift.value * _fontSize,
                        ),
                        child: Transform.scale(
                          scaleX: _dotSquash.value,
                          scaleY: 2 - _dotSquash.value,
                          alignment: Alignment.bottomCenter,
                          child: dot,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: _fontSize * 0.2),
              Text('BYTES', textScaler: TextScaler.noScaling, style: sub),
            ],
          ),
        ),
      ),
    );
  }
}
