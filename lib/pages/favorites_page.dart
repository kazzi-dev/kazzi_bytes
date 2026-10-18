import 'package:flutter/material.dart';

import '../data/menu_data.dart';
import '../data/models.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/app_scope.dart';
import '../widgets/dish_widgets.dart';
import '../widgets/illustrations.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/routes.dart';
import '../widgets/surfaces.dart';
import 'dish_detail_sheet.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final Set<String> _seen = <String>{};

  void _open(Dish dish, String heroTag) {
    Navigator.of(context).push(
      SheetRoute<void>(
        builder: (BuildContext context) =>
            DishDetailSheet(dish: dish, heroTag: heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final EdgeInsets gutter = centeredGutter(context);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        scope.favorites,
        scope.catalog,
      ]),
      builder: (BuildContext context, Widget? _) {
        final List<Dish> source = scope.catalog.dishes.isEmpty
            ? kMenu
            : scope.catalog.dishes;
        final List<Dish> favorites = <Dish>[
          for (final Dish dish in source)
            if (scope.favorites.isFavorite(dish)) dish,
        ];
        final double width =
            MediaQuery.sizeOf(context).width - gutter.horizontal;
        final int columns = width >= Kz.gridBreakpoint ? 2 : 1;
        final int rows = (favorites.length / columns).ceil();

        return CustomScrollView(
          slivers: <Widget>[
            SliverPersistentHeader(
              pinned: true,
              delegate: FrostedHeaderDelegate(
                height: padding.top + TabTitle.heightFor(context),
                child: Padding(
                  padding: EdgeInsets.only(top: padding.top),
                  child: TabTitle(
                    title: 'Favorites',
                    subtitle: favorites.isEmpty
                        ? null
                        : '${favorites.length} saved',
                  ),
                ),
              ),
            ),
            if (favorites.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyState(
                    icon: Icons.favorite_rounded,
                    accents: const <IconData>[
                      Icons.lunch_dining_rounded,
                      Icons.star_rounded,
                      Icons.icecream_rounded,
                    ],
                    title: 'No favorites yet',
                    message: 'Tap the heart on any dish to save it here for next time.',
                    action: FilledButton(
                      onPressed: () => scope.tabIndex.value = 0,
                      child: const Text('Browse menu'),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: gutter.copyWith(
                  top: Kz.s4,
                  bottom: padding.bottom + Kz.s6,
                ),
                sliver: SliverList.separated(
                  itemCount: rows,
                  separatorBuilder: (BuildContext context, int i) =>
                      const SizedBox(height: Kz.s3),
                  itemBuilder: (BuildContext context, int row) {
                    Widget item(int i) {
                      final Dish dish = favorites[i];
                      final String tag = 'fav-${dish.id}';
                      return Entrance(
                        key: ValueKey<String>(tag),
                        animate: _seen.add(tag),
                        delay: Motion.stagger(context, i),
                        child: DishCard(
                          dish: dish,
                          heroTag: tag,
                          onOpen: () => _open(dish, tag),
                        ),
                      );
                    }

                    if (columns == 1) return item(row);
                    final int a = row * 2;
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(child: item(a)),
                          const SizedBox(width: Kz.s3),
                          Expanded(
                            child: a + 1 < favorites.length
                                ? item(a + 1)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
