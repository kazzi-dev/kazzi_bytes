import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'illustrations.dart';
import 'motion_widgets.dart';
import 'surfaces.dart';

// ---------------------------------------------------------------------------
// Page scaffold for Profile sub-pages
// ---------------------------------------------------------------------------

/// Frosted app bar, a staggered scrolling body and an optional frosted
/// bottom action, shared by the account pages.
class AccountPageScaffold extends StatelessWidget {
  const AccountPageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.bottomAction,
  });

  final String title;
  final List<Widget> children;
  final Widget? bottomAction;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets gutter = centeredGutter(
      context,
      maxWidth: Kz.maxReadingWidth,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: FrostedAppBar(title: title),
      body: Builder(
        builder: (BuildContext context) {
          final EdgeInsets padding = MediaQuery.paddingOf(context);
          return ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: gutter.copyWith(
              top: padding.top + Kz.s4,
              bottom: padding.bottom + Kz.s6,
            ),
            children: <Widget>[
              for (int i = 0; i < children.length; i++)
                Entrance(
                  delay: Motion.stagger(
                    context,
                    i,
                    step: const Duration(milliseconds: 30),
                  ),
                  child: children[i],
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: bottomAction == null
          ? null
          : Frosted(
              border: Border(top: BorderSide(color: context.palette.hairline)),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Kz.maxReadingWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Kz.s5,
                        Kz.s3,
                        Kz.s5,
                        Kz.s3,
                      ),
                      child: bottomAction,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Small uppercase label above a group of settings.
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Kz.s1, Kz.s6, 0, Kz.s2),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: context.text.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

/// A note with an icon, e.g. the card security explanation.
class InfoNote extends StatelessWidget {
  const InfoNote({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Kz.s3),
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(Kz.rMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: context.colors.onPrimaryContainer),
          const SizedBox(width: Kz.s3),
          Expanded(
            child: Text(
              text,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a modal bottom sheet sized for a form, padded above the keyboard.
Future<T?> showFormSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Kz.s6, 0, Kz.s6, Kz.s6),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Kz.maxFormWidth),
            child: builder(context),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// In-app notification banner
// ---------------------------------------------------------------------------

OverlayEntry? _currentBanner;

/// Slides a push-style banner down from the top of the screen.
///
/// Stands in for real push notifications until the backend exists.
/// TODO(backend): Show real pushes with firebase_messaging, and keep this
/// banner for messages that arrive while the app is open.
void showInAppNotification(
  BuildContext context, {
  required String title,
  required String body,
  IconData icon = Icons.notifications_rounded,
  VoidCallback? onTap,
}) {
  final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _currentBanner?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (BuildContext context) => _NotificationBanner(
      title: title,
      body: body,
      icon: icon,
      onTap: onTap,
      onDismissed: () {
        if (_currentBanner == entry) _currentBanner = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _currentBanner = entry;
  overlay.insert(entry);
  HapticFeedback.mediumImpact();
  SemanticsService.sendAnnouncement(
    View.of(context),
    '$title. $body',
    Directionality.of(context),
  );
}

class _NotificationBanner extends StatefulWidget {
  const _NotificationBanner({
    required this.title,
    required this.body,
    required this.icon,
    required this.onTap,
    required this.onDismissed,
  });

  final String title;
  final String body;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback onDismissed;

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeInCubic,
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.status == AnimationStatus.dismissed && !_closing) {
      if (Motion.reduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
      _timer = Timer(const Duration(seconds: 4), _close);
    }
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (mounted && !Motion.reduced(context)) await _controller.reverse();
    widget.onDismissed();
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
    final ColorScheme colors = context.colors;
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Kz.s3, Kz.s2, Kz.s3, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1.4),
                end: Offset.zero,
              ).animate(_curve),
              child: Dismissible(
                key: const ValueKey<String>('banner'),
                direction: DismissDirection.up,
                onDismissed: (_) {
                  _closing = true;
                  _timer?.cancel();
                  widget.onDismissed();
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Kz.rLg),
                    boxShadow: Kz.e3(context.palette.shadow),
                  ),
                  child: Frosted(
                    borderRadius: BorderRadius.circular(Kz.rLg),
                    color: colors.surface.withValues(alpha: 0.86),
                    border: Border.all(color: context.palette.hairline),
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () {
                          widget.onTap?.call();
                          _close();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(Kz.s3),
                          child: Row(
                            children: <Widget>[
                              const BrandMark(size: 40),
                              const SizedBox(width: Kz.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Icon(
                                          widget.icon,
                                          size: 14,
                                          color: colors.primary,
                                        ),
                                        const SizedBox(width: Kz.s1),
                                        Expanded(
                                          child: Text(
                                            widget.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: context.text.titleSmall,
                                          ),
                                        ),
                                        Text(
                                          'now',
                                          style: context.text.labelSmall
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.body,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.bodySmall?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
