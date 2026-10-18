import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/format.dart';
import '../data/models.dart';
import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'app_scope.dart';
import 'cart_widgets.dart';
import 'controls.dart';
import 'motion_widgets.dart';
import 'surfaces.dart';

/// Accent color per category, softened for dark mode.
Color dishTint(BuildContext context, Dish dish) {
  final Color base = switch (dish.category) {
    'Burgers' => const Color(0xFFFF7A3D),
    'Rice Meals' => const Color(0xFFF59E0B),
    'Sides' => const Color(0xFFE5484D),
    'Drinks' => const Color(0xFF0EA5E9),
    'Desserts' => const Color(0xFF8B5CF6),
    _ => context.colors.primary,
  };
  return context.isDark ? Color.lerp(base, Colors.white, 0.15)! : base;
}

// ---------------------------------------------------------------------------
// Dish imagery
// ---------------------------------------------------------------------------

/// The dish visual: a tinted gradient tile with a glowing icon today, or the
/// dish photo once [Dish.imageUrl] is set (the tile becomes its placeholder).
///
/// Sizes itself to its parent and has no LayoutBuilder, so it works inside
/// IntrinsicHeight rows and scales smoothly during Hero flights.
class DishImage extends StatelessWidget {
  const DishImage({
    super.key,
    required this.dish,
    this.radius = Kz.rMd,
    this.heroTag,
  });

  final Dish dish;
  final double radius;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final Color tint = dishTint(context, dish);
    final bool isDark = context.isDark;
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    final Widget placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            tint.withValues(alpha: isDark ? 0.30 : 0.22),
            tint.withValues(alpha: isDark ? 0.10 : 0.07),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          FractionallySizedBox(
            widthFactor: 0.8,
            heightFactor: 0.8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    tint.withValues(alpha: 0.32),
                    tint.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          FractionallySizedBox(
            widthFactor: 0.46,
            heightFactor: 0.46,
            child: FittedBox(child: Icon(dish.icon, color: tint)),
          ),
        ],
      ),
    );

    final String? url = dish.imageUrl;
    Widget content = url == null
        ? placeholder
        : Stack(
            fit: StackFit.expand,
            children: <Widget>[
              placeholder,
              // TODO(backend): Swap for a cached image (cached_network_image)
              // and a blur-hash placeholder once real photos exist.
              Image.network(
                url,
                fit: BoxFit.cover,
                frameBuilder:
                    (
                      BuildContext context,
                      Widget child,
                      int? frame,
                      bool wasSynchronouslyLoaded,
                    ) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: Motion.of(context, Kz.dSlow),
                        child: child,
                      );
                    },
                errorBuilder: (BuildContext context, Object e, StackTrace? s) =>
                    const SizedBox.shrink(),
              ),
            ],
          );

    content = ClipRRect(borderRadius: borderRadius, child: content);
    if (heroTag != null) {
      content = Hero(tag: heroTag!, child: content);
    }
    return ExcludeSemantics(child: content);
  }
}

// ---------------------------------------------------------------------------
// Small pieces
// ---------------------------------------------------------------------------

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.dish, this.onImage = false});

  final Dish dish;

  /// Adds a translucent backdrop so it reads on top of imagery.
  final bool onImage;

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.favorites,
      builder: (BuildContext context, Widget? _) {
        final bool favorite = scope.favorites.isFavorite(dish);
        return IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            scope.favorites.toggle(dish);
          },
          tooltip: favorite
              ? 'Remove ${dish.name} from favorites'
              : 'Save ${dish.name} to favorites',
          style: onImage
              ? IconButton.styleFrom(
                  backgroundColor: context.colors.surface.withValues(
                    alpha: 0.88,
                  ),
                )
              : null,
          icon: AnimatedSwitcher(
            duration: Motion.of(context, Kz.dMedium),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutBack,
                ),
                child: child,
              );
            },
            child: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey<bool>(favorite),
              color: favorite
                  ? context.palette.heart
                  : context.colors.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

/// Rating, prep time and calories in a compact row.
class DishMeta extends StatelessWidget {
  const DishMeta({super.key, required this.dish, this.showCalories = false});

  final Dish dish;
  final bool showCalories;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = context.text.labelMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final Color muted = context.colors.onSurfaceVariant;

    Widget item(IconData icon, Color color, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 3),
          Text(label, style: style),
        ],
      );
    }

    return Semantics(
      label:
          'Rated ${dish.rating} from ${dish.ratingCountLabel} reviews, '
          'ready in about ${dish.prepMinutes} minutes',
      excludeSemantics: true,
      child: Wrap(
        spacing: Kz.s3,
        runSpacing: Kz.s1,
        children: <Widget>[
          item(
            Icons.star_rounded,
            context.palette.star,
            '${dish.rating} (${dish.ratingCountLabel})',
          ),
          item(Icons.schedule_rounded, muted, '${dish.prepMinutes} min'),
          if (showCalories)
            item(
              Icons.local_fire_department_rounded,
              muted,
              '${dish.calories} kcal',
            ),
        ],
      ),
    );
  }
}

/// "Popular" / "New" badge, or nothing.
class DishBadge extends StatelessWidget {
  const DishBadge({super.key, required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    if (dish.isNew) {
      return const KzTag(
        label: 'New',
        icon: Icons.auto_awesome_rounded,
        tone: TagTone.success,
      );
    }
    if (dish.isPopular) {
      return const KzTag(
        label: 'Popular',
        icon: Icons.local_fire_department_rounded,
        tone: TagTone.warm,
      );
    }
    return const SizedBox.shrink();
  }
}

/// Round "+" button that springs, flies a dot to the cart and buzzes.
class AddToCartButton extends StatelessWidget {
  const AddToCartButton({super.key, required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return PressScale(
      pressedScale: 0.86,
      child: Builder(
        builder: (BuildContext buttonContext) {
          return IconButton.filled(
            onPressed: () {
              HapticFeedback.lightImpact();
              // Measure before the cart changes and this button swaps out.
              FlyToCart.launch(buttonContext);
              AppScope.of(context).cart.add(dish);
            },
            tooltip: 'Add ${dish.name} to cart',
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
          );
        },
      ),
    );
  }
}

/// Shows the add button, morphing into a stepper once the dish is in the
/// cart. Only this widget listens to the cart, so the card never rebuilds.
class AddToCartControl extends StatelessWidget {
  const AddToCartControl({super.key, required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    return ListenableBuilder(
      listenable: scope.cart,
      builder: (BuildContext context, Widget? _) {
        final int quantity = scope.cart.quantityOf(dish);
        return AnimatedSwitcher(
          duration: Motion.of(context, Kz.dMedium),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: quantity == 0
              ? AddToCartButton(key: const ValueKey<String>('add'), dish: dish)
              : QtyStepper(
                  key: const ValueKey<String>('stepper'),
                  quantity: quantity,
                  itemName: dish.name,
                  onAdd: () => scope.cart.add(dish),
                  onRemove: () => scope.cart.remove(dish),
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

/// The main menu card.
class DishCard extends StatelessWidget {
  const DishCard({
    super.key,
    required this.dish,
    required this.heroTag,
    required this.onOpen,
  });

  final Dish dish;
  final Object heroTag;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    return PressScale(
      pressedScale: 0.985,
      child: SurfaceCard(
        padding: const EdgeInsets.all(Kz.s3),
        onTap: onOpen,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox.square(
              dimension: 96,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  DishImage(dish: dish, heroTag: heroTag),
                  Positioned(
                    left: 6,
                    top: 6,
                    right: 6,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: DishBadge(dish: dish),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Kz.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: Kz.s1),
                          child: Semantics(
                            button: true,
                            hint: 'Opens details',
                            child: Text(
                              dish.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium,
                            ),
                          ),
                        ),
                      ),
                      FavoriteButton(dish: dish),
                    ],
                  ),
                  Text(
                    dish.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Kz.s2),
                  DishMeta(dish: dish),
                  const SizedBox(height: Kz.s2),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatPeso(dish.price),
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AddToCartControl(dish: dish),
                          ),
                        ),
                      ),
                    ],
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

/// Compact vertical card for the "Popular right now" rail.
class PopularDishCard extends StatelessWidget {
  const PopularDishCard({
    super.key,
    required this.dish,
    required this.heroTag,
    required this.onOpen,
  });

  final Dish dish;
  final Object heroTag;
  final VoidCallback onOpen;

  static const double width = 172;
  static const double imageHeight = 112;

  /// Total height of the card, growing with the text size.
  static double heightFor(BuildContext context) =>
      Kz.s3 * 2 + imageHeight + Kz.s3 + 48 * context.textScale.clamp(1.0, 2.2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: PressScale(
        child: SurfaceCard(
          padding: const EdgeInsets.all(Kz.s3),
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    DishImage(dish: dish, heroTag: heroTag, radius: Kz.rSm),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: KzTag(
                        label: '${dish.rating}',
                        icon: Icons.star_rounded,
                        tone: TagTone.neutral,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Kz.s3),
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            dish.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleSmall,
                          ),
                          Text(
                            formatPeso(dish.price),
                            maxLines: 1,
                            style: context.text.titleSmall?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AddToCartButton(dish: dish),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
