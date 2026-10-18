import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/context_ext.dart';
import '../theme/tokens.dart';

/// Keeps content readable on wide screens by capping its width.
class PageWidth extends StatelessWidget {
  const PageWidth({
    super.key,
    required this.child,
    this.maxWidth = Kz.maxReadingWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Horizontal padding that keeps sliver content centered within [maxWidth].
EdgeInsets centeredGutter(
  BuildContext context, {
  double maxWidth = Kz.maxContentWidth,
  double gutter = Kz.gutter,
}) {
  final double width = MediaQuery.sizeOf(context).width;
  final double side = width > maxWidth + gutter * 2
      ? (width - maxWidth) / 2
      : gutter;
  return EdgeInsets.symmetric(horizontal: side);
}

/// The standard card: surface color, hairline border, soft shadow in light
/// mode, optional ink ripple.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Kz.s4),
    this.radius = Kz.rLg,
    this.onTap,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final Widget content = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: context.isDark ? null : Kz.e1(context.palette.shadow),
      ),
      child: Material(
        color: color ?? context.colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: borderColor ?? context.colors.outlineVariant),
        ),
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Frosted glass: blurs whatever scrolls underneath and tints it with a
/// translucent surface.
class Frosted extends StatelessWidget {
  const Frosted({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.border,
    this.blur = 24,
    this.color,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final BoxBorder? border;
  final double blur;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bool rounded = borderRadius != BorderRadius.zero;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color ?? context.palette.glass,
            borderRadius: rounded ? borderRadius : null,
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}

enum TagTone { brand, warm, success, neutral }

/// Small pill label, e.g. "Popular" or "New".
class KzTag extends StatelessWidget {
  const KzTag({
    super.key,
    required this.label,
    this.icon,
    this.tone = TagTone.brand,
  });

  final String label;
  final IconData? icon;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final (Color background, Color foreground) = switch (tone) {
      TagTone.brand => (colors.primaryContainer, colors.onPrimaryContainer),
      TagTone.warm => (
        context.palette.warmContainer,
        context.palette.onWarmContainer,
      ),
      TagTone.success => (
        context.palette.successContainer,
        context.palette.onSuccessContainer,
      ),
      TagTone.neutral => (context.palette.surfaceAlt, colors.onSurfaceVariant),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Kz.rPill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 13, color: foreground),
              const SizedBox(width: Kz.s1),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section heading with an optional trailing widget.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(title, style: context.text.titleLarge),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Round 48×48 icon button with a hairline border, used in headers.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(Kz.minTap, Kz.minTap),
        backgroundColor: context.colors.surface.withValues(alpha: 0.7),
        foregroundColor: context.colors.onSurface,
        side: BorderSide(color: context.colors.outlineVariant),
        shape: const CircleBorder(),
      ),
      icon: icon,
    );
  }
}

/// Frosted app bar for pushed pages (Cart, Checkout).
class FrostedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FrostedAppBar({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
  });

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();
    return Frosted(
      border: Border(bottom: BorderSide(color: context.palette.hairline)),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Kz.s3),
            child: Row(
              children: <Widget>[
                if (canPop)
                  HeaderIconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                const SizedBox(width: Kz.s3),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleLarge,
                    ),
                  ),
                ),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A pinned, frosted sliver header of fixed height.
class FrostedHeaderDelegate extends SliverPersistentHeaderDelegate {
  FrostedHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Pinned headers get loose constraints; the child must fill the full
    // extent or the sliver's paint extent ends up smaller than its layout
    // extent (a hard error once a status-bar inset is added).
    return SizedBox.expand(
      child: Frosted(
        border: Border(
          bottom: BorderSide(
            color: overlapsContent
                ? context.palette.hairline
                : context.palette.hairline.withValues(alpha: 0),
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(FrostedHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

/// Large title for the top of a tab (Orders, Favorites, Profile).
class TabTitle extends StatelessWidget {
  const TabTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  /// Height of the title area, growing with the user's text size.
  static double heightFor(BuildContext context) =>
      math.max(76.0, 28 + 50 * context.textScale);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: centeredGutter(context, maxWidth: Kz.maxReadingWidth),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(title, style: context.text.headlineSmall),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
