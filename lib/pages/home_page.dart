import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/catalog_controller.dart';
import '../data/format.dart';
import '../data/menu_data.dart';
import '../data/models.dart';
import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/app_scope.dart';
import '../widgets/cart_widgets.dart';
import '../widgets/dish_widgets.dart';
import '../widgets/illustrations.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/routes.dart';
import '../widgets/surfaces.dart';
import 'cart_page.dart';
import 'dish_detail_sheet.dart';

/// The menu: promo carousel, search, sticky category chips and dishes.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _all = 'All';

  final TextEditingController _search = TextEditingController();
  String _category = _all;
  String _query = '';

  /// Bumped whenever the filter changes so the list re-staggers in.
  int _generation = 0;

  /// Items that already played their entrance in this generation.
  final Set<String> _seen = <String>{};

  bool _precached = false;

  /// Warms the image cache once the menu arrives so photos are ready by the
  /// time cards scroll into view.
  void _precachePhotos(List<Dish> dishes) {
    if (_precached) return;
    _precached = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final Dish dish in dishes) {
        final String? url = dish.imageUrl;
        if (url != null) {
          precacheImage(
            NetworkImage(url),
            context,
            onError: (Object e, StackTrace? s) {},
          );
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final CatalogController catalog = AppScope.of(context).catalog;
      if (catalog.status == MenuStatus.idle) catalog.load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setCategory(String category) {
    if (category == _category) return;
    HapticFeedback.selectionClick();
    setState(() {
      _category = category;
      _bump();
    });
  }

  void _setQuery(String query) {
    if (query.trim() == _query.trim()) return;
    setState(() {
      _query = query;
      _bump();
    });
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _category = _all;
      _bump();
    });
  }

  void _bump() {
    _generation++;
    _seen.clear();
  }

  List<Dish> _filter(List<Dish> all) {
    final String q = _query.trim().toLowerCase();
    return <Dish>[
      for (final Dish dish in all)
        if ((_category == _all || dish.category == _category) &&
            (q.isEmpty ||
                dish.name.toLowerCase().contains(q) ||
                dish.description.toLowerCase().contains(q) ||
                dish.category.toLowerCase().contains(q)))
          dish,
    ];
  }

  Future<void> _refresh(CatalogController catalog) async {
    final bool ok = await catalog.load(refresh: true);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(catalog.error ?? 'Couldn’t refresh the menu.')),
    );
  }

  void _openDish(Dish dish, String heroTag) {
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
    final double headerHeight = padding.top + _HomeHeader.heightFor(context);

    return ListenableBuilder(
      listenable: scope.catalog,
      builder: (BuildContext context, Widget? _) {
        final CatalogController catalog = scope.catalog;
        if (catalog.status == MenuStatus.ready) _precachePhotos(catalog.dishes);
        final EdgeInsets gutter = centeredGutter(context);

        final List<Widget> body = switch (catalog.status) {
          MenuStatus.idle || MenuStatus.loading => _loadingSlivers(gutter),
          MenuStatus.error => <Widget>[
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  accents: const <IconData>[
                    Icons.cloud_off_rounded,
                    Icons.restaurant_rounded,
                    Icons.refresh_rounded,
                  ],
                  title: 'Couldn’t load the menu',
                  message: catalog.error ?? 'Please try again.',
                  action: FilledButton.icon(
                    onPressed: catalog.load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ),
              ),
            ),
          ],
          MenuStatus.ready => _contentSlivers(catalog, gutter),
        };

        return RefreshIndicator(
          edgeOffset: headerHeight,
          onRefresh: () => _refresh(catalog),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: FrostedHeaderDelegate(
                  height: headerHeight,
                  child: Padding(
                    padding: EdgeInsets.only(top: padding.top) + gutter,
                    child: const _HomeHeader(),
                  ),
                ),
              ),
              ...body,
              SliverToBoxAdapter(
                child: SizedBox(height: padding.bottom + Kz.s6),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Loading skeleton
  // -------------------------------------------------------------------------

  List<Widget> _loadingSlivers(EdgeInsets gutter) {
    return <Widget>[
      SliverPadding(
        padding: gutter.copyWith(top: Kz.s4),
        sliver: SliverToBoxAdapter(
          child: Shimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SkeletonBox(height: 176, radius: Kz.rXl),
                const SizedBox(height: Kz.s4),
                const SkeletonBox(height: 52, radius: Kz.rMd),
                const SizedBox(height: Kz.s5),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    separatorBuilder: (BuildContext context, int i) =>
                        const SizedBox(width: Kz.s2),
                    itemBuilder: (BuildContext context, int i) =>
                        const SkeletonBox(
                          width: 92,
                          height: 44,
                          radius: Kz.rPill,
                        ),
                  ),
                ),
                const SizedBox(height: Kz.s7),
                const SkeletonBox(width: 160, height: 22),
                const SizedBox(height: Kz.s4),
                for (int i = 0; i < 4; i++) ...<Widget>[
                  const _SkeletonDishCard(),
                  const SizedBox(height: Kz.s3),
                ],
              ],
            ),
          ),
        ),
      ),
    ];
  }

  // -------------------------------------------------------------------------
  // Content
  // -------------------------------------------------------------------------

  List<Widget> _contentSlivers(CatalogController catalog, EdgeInsets gutter) {
    final List<Dish> dishes = _filter(catalog.dishes);
    final List<Dish> popular = catalog.dishes
        .where((Dish d) => d.isPopular)
        .toList();
    final bool browsing = _category == _all && _query.trim().isEmpty;
    final double contentWidth =
        MediaQuery.sizeOf(context).width - gutter.horizontal;
    final int columns = contentWidth >= Kz.gridBreakpoint ? 2 : 1;

    return <Widget>[
      SliverPadding(
        padding: gutter.copyWith(top: Kz.s4),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Entrance(
                child: _PromoCarousel(
                  promos: catalog.promos,
                  onTap: (Promo promo) {
                    if (promo.category != null) _setCategory(promo.category!);
                  },
                ),
              ),
              const SizedBox(height: Kz.s4),
              Entrance(
                delay: Motion.stagger(context, 2),
                child: _SearchField(controller: _search, onChanged: _setQuery),
              ),
            ],
          ),
        ),
      ),
      SliverPersistentHeader(
        pinned: true,
        delegate: FrostedHeaderDelegate(
          height: _CategoryBar.heightFor(context),
          child: _CategoryBar(
            categories: <String>[_all, ...catalog.categories],
            selected: _category,
            onSelected: _setCategory,
            padding: gutter,
          ),
        ),
      ),
      if (browsing && popular.isNotEmpty) ...<Widget>[
        SliverPadding(
          padding: gutter.copyWith(top: Kz.s4),
          sliver: SliverToBoxAdapter(
            child: SectionTitle(
              'Popular right now',
              trailing: Icon(
                Icons.local_fire_department_rounded,
                color: context.palette.warm,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: PopularDishCard.heightFor(context) + Kz.s3 * 2,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: gutter.copyWith(top: Kz.s3, bottom: Kz.s3),
              itemCount: popular.length,
              separatorBuilder: (BuildContext context, int i) =>
                  const SizedBox(width: Kz.s3),
              itemBuilder: (BuildContext context, int i) {
                final Dish dish = popular[i];
                final String tag = 'popular-${dish.id}';
                return Entrance(
                  key: ValueKey<String>(tag),
                  delay: Motion.stagger(context, i + 3),
                  offset: 12,
                  child: PopularDishCard(
                    dish: dish,
                    heroTag: tag,
                    onOpen: () => _openDish(dish, tag),
                  ),
                );
              },
            ),
          ),
        ),
      ],
      SliverPadding(
        padding: gutter.copyWith(top: Kz.s5, bottom: Kz.s3),
        sliver: SliverToBoxAdapter(
          child: _ResultsTitle(
            title: _query.trim().isNotEmpty
                ? 'Results'
                : _category == _all
                ? 'Full menu'
                : _category,
            count: dishes.length,
          ),
        ),
      ),
      if (dishes.isEmpty)
        SliverToBoxAdapter(
          child: Center(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              accents: const <IconData>[
                Icons.lunch_dining_rounded,
                Icons.local_drink_rounded,
                Icons.cake_rounded,
              ],
              title: _query.trim().isEmpty
                  ? 'Nothing here yet'
                  : 'No matches for “${_query.trim()}”',
              message: 'Try another dish, or browse a different category.',
              action: OutlinedButton(
                onPressed: _clearFilters,
                child: const Text('Clear filters'),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: gutter,
          sliver: columns == 1
              ? SliverList.separated(
                  itemCount: dishes.length,
                  separatorBuilder: (BuildContext context, int i) =>
                      const SizedBox(height: Kz.s3),
                  itemBuilder: (BuildContext context, int i) =>
                      _dishItem(dishes[i], i),
                )
              : SliverList.separated(
                  itemCount: (dishes.length / 2).ceil(),
                  separatorBuilder: (BuildContext context, int i) =>
                      const SizedBox(height: Kz.s3),
                  itemBuilder: (BuildContext context, int row) {
                    final int a = row * 2;
                    final int b = a + 1;
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(child: _dishItem(dishes[a], a)),
                          const SizedBox(width: Kz.s3),
                          Expanded(
                            child: b < dishes.length
                                ? _dishItem(dishes[b], b)
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
    ];
  }

  Widget _dishItem(Dish dish, int index) {
    final String key = '$_generation-${dish.id}';
    final bool firstTime = _seen.add(key);
    final String heroTag = 'menu-${dish.id}';
    return Entrance(
      key: ValueKey<String>(key),
      animate: firstTime,
      delay: Motion.stagger(context, index),
      child: DishCard(
        dish: dish,
        heroTag: heroTag,
        onOpen: () => _openDish(dish, heroTag),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  static double heightFor(BuildContext context) =>
      math.max(72.0, 26 + 38 * context.textScale);

  String _greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final String? name = scope.auth.user?.isGuest ?? true
        ? null
        : scope.auth.user?.firstName;
    final bool isDark = context.isDark;

    return Row(
      children: <Widget>[
        const BrandMark(size: 40),
        const SizedBox(width: Kz.s3),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name == null
                      ? '${_greeting()} 👋'
                      : '${_greeting()}, $name 👋',
                  style: context.text.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    'What are you craving?',
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: Kz.s2),
        HeaderIconButton(
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: () {
            HapticFeedback.selectionClick();
            scope.theme.toggle(Theme.of(context).brightness);
          },
          icon: AnimatedSwitcher(
            duration: Motion.of(context, const Duration(milliseconds: 320)),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return RotationTransition(
                turns: Tween<double>(begin: 0.75, end: 1).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey<bool>(isDark),
            ),
          ),
        ),
        const SizedBox(width: Kz.s2),
        CartIconButton(onPressed: () => openCart(context)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Promo carousel
// ---------------------------------------------------------------------------

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel({required this.promos, required this.onTap});

  final List<Promo> promos;
  final ValueChanged<Promo> onTap;

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _controller = PageController();
  Timer? _auto;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restartAuto();
  }

  void _restartAuto() {
    _auto?.cancel();
    if (widget.promos.length < 2 || Motion.reduced(context)) return;
    _auto = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      // Pause while the tab is hidden.
      if (!TickerMode.valuesOf(context).enabled) return;
      _controller.animateToPage(
        (_index + 1) % widget.promos.length,
        duration: Kz.dSlower,
        curve: Kz.emphasized,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.promos.isEmpty) return const SizedBox.shrink();
    final double height = 48 + 128 * context.textScale;

    return Column(
      children: <Widget>[
        SizedBox(
          height: height,
          child: NotificationListener<ScrollStartNotification>(
            onNotification: (ScrollStartNotification n) {
              if (n.dragDetails != null) _restartAuto();
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.promos.length,
              onPageChanged: (int i) => setState(() => _index = i),
              itemBuilder: (BuildContext context, int i) {
                final Promo promo = widget.promos[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _PromoCard(
                    promo: promo,
                    onTap: () => widget.onTap(promo),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: Kz.s3),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < widget.promos.length; i++)
                AnimatedContainer(
                  duration: Motion.of(context, Kz.dSlow),
                  curve: Kz.emphasized,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? context.colors.primary
                        : context.colors.outlineVariant,
                    borderRadius: BorderRadius.circular(Kz.rPill),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo, required this.onTap});

  final Promo promo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color onPromo = Colors.white;
    final BorderRadius radius = BorderRadius.circular(Kz.rXl);

    return Semantics(
      button: true,
      label: '${promo.eyebrow}. ${promo.title}. ${promo.subtitle}',
      excludeSemantics: true,
      child: PressScale(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: context.isDark
                ? null
                : Kz.glow(promo.colors.first, strength: 0.7),
          ),
          child: Material(
            borderRadius: radius,
            clipBehavior: Clip.antiAlias,
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: promo.colors,
                ),
              ),
              child: InkWell(
                onTap: onTap,
                child: Stack(
                  children: <Widget>[
                    // Soft glow blobs for a mesh-gradient feel.
                    Positioned(
                      right: -60,
                      top: -70,
                      child: _Glow(
                        size: 220,
                        color: onPromo.withValues(alpha: 0.18),
                      ),
                    ),
                    Positioned(
                      left: -40,
                      bottom: -90,
                      child: _Glow(
                        size: 200,
                        color: onPromo.withValues(alpha: 0.10),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: -14,
                      child: Transform.rotate(
                        angle: -0.22,
                        child: Icon(
                          promo.icon,
                          size: 128,
                          color: onPromo.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(Kz.s5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: onPromo.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(Kz.rPill),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Text(
                                promo.eyebrow.toUpperCase(),
                                style: context.text.labelSmall?.copyWith(
                                  color: onPromo,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: Kz.s3),
                          FractionallySizedBox(
                            widthFactor: 0.78,
                            child: Text(
                              promo.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.headlineSmall?.copyWith(
                                color: onPromo,
                              ),
                            ),
                          ),
                          const SizedBox(height: Kz.s1),
                          FractionallySizedBox(
                            widthFactor: 0.78,
                            child: Text(
                              promo.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodyMedium?.copyWith(
                                color: onPromo.withValues(alpha: 0.92),
                              ),
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
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

class _SearchField extends StatefulWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;

  /// Called 300ms after typing stops.
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  Timer? _debounce;

  void _changed(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => widget.onChanged(value),
    );
  }

  void _clear() {
    _debounce?.cancel();
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: _changed,
      onSubmitted: (String value) {
        _debounce?.cancel();
        widget.onChanged(value);
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search burgers, bowls, drinks…',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (BuildContext context, TextEditingValue value, Widget? _) {
            return AnimatedSwitcher(
              duration: Motion.of(context, Kz.dFast),
              transitionBuilder: (Widget child, Animation<double> animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: value.text.isEmpty
                  ? const SizedBox.shrink(key: ValueKey<String>('empty'))
                  : IconButton(
                      key: const ValueKey<String>('clear'),
                      tooltip: 'Clear search',
                      onPressed: _clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky category bar with a sliding selection pill
// ---------------------------------------------------------------------------

class _CategoryBar extends StatefulWidget {
  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
    required this.padding,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsets padding;

  static double heightFor(BuildContext context) =>
      Kz.s4 + math.max(Kz.minTap, 24 + 18 * context.textScale);

  @override
  State<_CategoryBar> createState() => _CategoryBarState();
}

class _CategoryBarState extends State<_CategoryBar> {
  final Map<String, GlobalKey> _keys = <String, GlobalKey>{};
  final GlobalKey _rowKey = GlobalKey();
  Rect? _indicator;
  bool _animate = false;

  GlobalKey _keyFor(String category) =>
      _keys.putIfAbsent(category, () => GlobalKey(debugLabel: category));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleMeasure(animate: false);
  }

  @override
  void didUpdateWidget(_CategoryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _scheduleMeasure(animate: true, reveal: true);
    } else {
      _scheduleMeasure(animate: false);
    }
  }

  void _scheduleMeasure({required bool animate, bool reveal = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? chipContext = _keys[widget.selected]?.currentContext;
      final RenderObject? chip = chipContext?.findRenderObject();
      final RenderObject? row = _rowKey.currentContext?.findRenderObject();
      if (chip is! RenderBox || row is! RenderBox || !chip.hasSize) return;
      final Rect rect =
          chip.localToGlobal(Offset.zero, ancestor: row) & chip.size;
      if (rect != _indicator) {
        setState(() {
          _indicator = rect;
          _animate = animate;
        });
      }
      if (reveal && chipContext != null) {
        Scrollable.ensureVisible(
          chipContext,
          alignment: 0.5,
          duration: Motion.of(context, Kz.dSlow),
          curve: Kz.standard,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final Rect indicator = _indicator ?? Rect.zero;

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        child: Stack(
          key: _rowKey,
          children: <Widget>[
            AnimatedPositioned(
              duration: _animate ? Motion.of(context, Kz.dSlow) : Duration.zero,
              curve: Kz.emphasized,
              left: indicator.left,
              top: indicator.top,
              width: indicator.width,
              height: indicator.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(Kz.rPill),
                  boxShadow: context.isDark
                      ? null
                      : Kz.glow(colors.primary, strength: 0.6),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                for (int i = 0; i < widget.categories.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: Kz.s2),
                  _CategoryChip(
                    key: _keyFor(widget.categories[i]),
                    label: widget.categories[i],
                    icon:
                        kCategoryIcons[widget.categories[i]] ??
                        Icons.restaurant_rounded,
                    selected: widget.categories[i] == widget.selected,
                    // Before the first measurement, paint the selection on
                    // the chip itself so there is no empty frame.
                    fillSelected: _indicator == null,
                    onTap: () => widget.onSelected(widget.categories[i]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.fillSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool fillSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final Duration duration = Motion.of(context, Kz.dMedium);
    final Color foreground = selected ? colors.onPrimary : colors.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label category',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: duration,
            constraints: const BoxConstraints(minHeight: Kz.minTap),
            padding: const EdgeInsets.symmetric(horizontal: Kz.s4),
            decoration: BoxDecoration(
              color: selected && fillSelected ? colors.primary : null,
              borderRadius: BorderRadius.circular(Kz.rPill),
              border: Border.all(
                color: selected ? Colors.transparent : colors.outlineVariant,
              ),
            ),
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: foreground),
              duration: duration,
              builder: (BuildContext context, Color? color, Widget? _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: context.text.labelLarge?.copyWith(color: color),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsTitle extends StatelessWidget {
  const _ResultsTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final Duration duration = Motion.of(context, Kz.dMedium);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: AnimatedSwitcher(
            duration: duration,
            layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[...previous, ?current],
            ),
            child: Semantics(
              key: ValueKey<String>(title),
              header: true,
              child: Text(title, style: context.text.titleLarge),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: duration,
          child: Text(
            pluralItems(count),
            key: ValueKey<int>(count),
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonDishCard extends StatelessWidget {
  const _SkeletonDishCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(Kz.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SkeletonBox(width: 96, height: 96, radius: Kz.rMd),
          SizedBox(width: Kz.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: Kz.s1),
                SkeletonBox(height: 16, width: 160),
                SizedBox(height: Kz.s3),
                SkeletonBox(height: 11),
                SizedBox(height: 6),
                SkeletonBox(height: 11, width: 120),
                SizedBox(height: Kz.s4),
                Row(
                  children: <Widget>[
                    SkeletonBox(height: 18, width: 56),
                    Spacer(),
                    SkeletonBox(width: 40, height: 40, radius: Kz.rPill),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
