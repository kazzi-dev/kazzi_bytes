import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/app_scope.dart';
import '../widgets/controls.dart';
import '../widgets/illustrations.dart';
import '../widgets/routes.dart';
import 'auth_page.dart';
import 'shell_page.dart';

class _Slide {
  const _Slide({
    required this.icon,
    required this.accents,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final List<IconData> accents;
  final String title;
  final String body;
}

const List<_Slide> _slides = <_Slide>[
  _Slide(
    icon: Icons.restaurant_menu_rounded,
    accents: <IconData>[
      Icons.lunch_dining_rounded,
      Icons.rice_bowl_rounded,
      Icons.icecream_rounded,
    ],
    title: 'Cravings, sorted.',
    body: 'A menu for every mood, from smash burgers to ube ice cream.',
  ),
  _Slide(
    icon: Icons.touch_app_rounded,
    accents: <IconData>[
      Icons.add_shopping_cart_rounded,
      Icons.tune_rounded,
      Icons.bolt_rounded,
    ],
    title: 'Order in a few taps.',
    body:
        'Pick your add-ons, tap to add, and check out in seconds. '
        'No lines, no fuss.',
  ),
  _Slide(
    icon: Icons.notifications_active_rounded,
    accents: <IconData>[
      Icons.soup_kitchen_rounded,
      Icons.schedule_rounded,
      Icons.room_service_rounded,
    ],
    title: 'Know when it’s ready.',
    body: 'Follow your order live, from the kitchen to your table.',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: Motion.of(context, Kz.dSlower),
      curve: Kz.emphasized,
    );
  }

  void _finish() {
    final AppScope scope = AppScope.of(context);
    scope.auth.markOnboardingSeen();
    Navigator.of(context).pushReplacement(
      KzRoute<void>(
        style: KzTransition.fadeThrough,
        builder: (BuildContext context) =>
            scope.auth.isSignedIn ? const ShellPage() : const AuthPage(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        intensity: 0.7,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Kz.maxFormWidth),
              child: Column(
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, Kz.s2, Kz.s3, 0),
                      child: AnimatedOpacity(
                        opacity: _isLast ? 0 : 1,
                        duration: Motion.of(context, Kz.dMedium),
                        child: TextButton(
                          onPressed: _isLast ? null : _finish,
                          child: const Text('Skip'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (int i) {
                        HapticFeedback.selectionClick();
                        setState(() => _index = i);
                      },
                      itemBuilder: (BuildContext context, int i) {
                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (BuildContext context, Widget? _) {
                            double page = _index.toDouble();
                            if (_controller.hasClients &&
                                _controller.position.haveDimensions) {
                              page = _controller.page ?? page;
                            }
                            return _SlideView(
                              slide: _slides[i],
                              delta: i - page,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Kz.s6,
                      Kz.s4,
                      Kz.s6,
                      Kz.s6,
                    ),
                    child: Column(
                      children: <Widget>[
                        Semantics(
                          label: 'Page ${_index + 1} of ${_slides.length}',
                          excludeSemantics: true,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              for (int i = 0; i < _slides.length; i++)
                                AnimatedContainer(
                                  duration: Motion.of(context, Kz.dSlow),
                                  curve: Kz.emphasized,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  width: i == _index ? 26 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: i == _index
                                        ? context.colors.primary
                                        : context.colors.outlineVariant,
                                    borderRadius: BorderRadius.circular(
                                      Kz.rPill,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Kz.s6),
                        LoadingButton(
                          label: _isLast ? 'Get started' : 'Next',
                          trailing: const Icon(Icons.arrow_forward_rounded),
                          onPressed: _next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide, required this.delta});

  final _Slide slide;

  /// Distance from the centered page; drives the parallax.
  final double delta;

  @override
  Widget build(BuildContext context) {
    final double fade = (1 - delta.abs()).clamp(0.0, 1.0);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: Kz.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Transform.translate(
              offset: Offset(delta * 120, 0),
              child: Opacity(
                opacity: fade,
                child: FloatingIllustration(
                  icon: slide.icon,
                  accents: slide.accents,
                  size: 220,
                ),
              ),
            ),
            const SizedBox(height: Kz.s10),
            Transform.translate(
              offset: Offset(delta * 60, 0),
              child: Column(
                children: <Widget>[
                  Semantics(
                    header: true,
                    child: Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: context.text.headlineMedium,
                    ),
                  ),
                  const SizedBox(height: Kz.s3),
                  Text(
                    slide.body,
                    textAlign: TextAlign.center,
                    style: context.text.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
