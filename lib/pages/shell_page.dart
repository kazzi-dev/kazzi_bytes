import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/app_controllers.dart';
import '../data/models.dart';
import '../theme/context_ext.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import '../widgets/account_widgets.dart';
import '../widgets/app_scope.dart';
import '../widgets/cart_widgets.dart';
import '../widgets/surfaces.dart';
import 'cart_page.dart';
import 'favorites_page.dart';
import 'home_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';

class _TabSpec {
  const _TabSpec(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const List<_TabSpec> _tabs = <_TabSpec>[
  _TabSpec('Home', Icons.home_outlined, Icons.home_rounded),
  _TabSpec('Orders', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  _TabSpec('Favorites', Icons.favorite_border_rounded, Icons.favorite_rounded),
  _TabSpec('Profile', Icons.person_outline_rounded, Icons.person_rounded),
];

/// The signed-in app: four tabs, a frosted nav bar and the floating cart bar.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  // Tabs are built lazily the first time they are opened, then kept alive.
  final Set<int> _built = <int>{};

  // Last known status per order, to detect changes worth announcing.
  final Map<String, OrderStatus> _statuses = <String, OrderStatus>{};
  OrdersController? _orders;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orders != null) return;
    _orders = AppScope.of(context).orders..addListener(_onOrdersChanged);
    for (final PlacedOrder order in _orders!.orders) {
      _statuses[order.id] = order.status;
    }
  }

  @override
  void dispose() {
    _orders?.removeListener(_onOrdersChanged);
    super.dispose();
  }

  /// Shows a banner when an order starts cooking or is ready, if the user
  /// has order updates switched on.
  void _onOrdersChanged() {
    final AppScope scope = AppScope.of(context);
    final bool enabled = scope.notifications.isEnabled(
      NotificationTopic.orderUpdates,
    );
    for (final PlacedOrder order in scope.orders.orders) {
      final OrderStatus? previous = _statuses[order.id];
      _statuses[order.id] = order.status;
      if (!enabled || previous == null || previous == order.status) continue;
      final (String title, String body)? message = switch (order.status) {
        OrderStatus.preparing => (
          'The kitchen is on it 🔥',
          '${order.number} is being prepared. Ready in about '
              '${order.etaMinutes} min.',
        ),
        OrderStatus.ready => (
          'Your order is ready! 🍔',
          '${order.number} is waiting for you at the counter.',
        ),
        _ => null,
      };
      if (message == null || !mounted) continue;
      showInAppNotification(
        context,
        title: message.$1,
        body: message.$2,
        icon: order.status.icon,
        onTap: () {
          Navigator.of(context).popUntil((Route<dynamic> r) => r.isFirst);
          scope.tabIndex.value = 1;
        },
      );
    }
  }

  Widget _page(int index) => switch (index) {
    0 => const HomePage(),
    1 => const OrdersPage(),
    2 => const FavoritesPage(),
    _ => const ProfilePage(),
  };

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: scope.tabIndex,
      builder: (BuildContext context, int index, Widget? _) {
        _built.add(index);
        return PopScope(
          canPop: index == 0,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (!didPop) scope.tabIndex.value = 0;
          },
          child: Scaffold(
            extendBody: true,
            body: Stack(
              children: <Widget>[
                for (int i = 0; i < _tabs.length; i++)
                  if (_built.contains(i))
                    _TabHost(
                      key: ValueKey<int>(i),
                      active: i == index,
                      child: _page(i),
                    ),
              ],
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListenableBuilder(
                  listenable: scope.cart,
                  builder: (BuildContext context, Widget? _) {
                    return CartBarHost(
                      visible:
                          !scope.cart.isEmpty && (index == 0 || index == 2),
                      child: CartBar(
                        count: scope.cart.itemCount,
                        total: scope.cart.total,
                        onTap: () => openCart(context),
                      ),
                    );
                  },
                ),
                _NavBar(
                  index: index,
                  onSelected: (int i) {
                    if (i == index) return;
                    HapticFeedback.selectionClick();
                    scope.tabIndex.value = i;
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Keeps a tab alive offstage and fades it in when it becomes active.
class _TabHost extends StatefulWidget {
  const _TabHost({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_TabHost> createState() => _TabHostState();
}

class _TabHostState extends State<_TabHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Kz.emphasized,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _show();
  }

  @override
  void didUpdateWidget(_TabHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _show();
  }

  void _show() {
    if (Motion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !widget.active,
      child: TickerMode(
        enabled: widget.active,
        // Only the visible tab takes part in Hero flights.
        child: HeroMode(
          enabled: widget.active,
          child: FadeTransition(
            opacity: _curve,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1).animate(_curve),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    return Frosted(
      border: Border(top: BorderSide(color: context.palette.hairline)),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Kz.maxReadingWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Kz.s2,
                vertical: Kz.s1,
              ),
              child: ListenableBuilder(
                listenable: scope.orders,
                builder: (BuildContext context, Widget? _) {
                  final int activeOrders = scope.orders.activeCount;
                  return Row(
                    children: <Widget>[
                      for (int i = 0; i < _tabs.length; i++)
                        Expanded(
                          child: _NavItem(
                            spec: _tabs[i],
                            selected: i == index,
                            badge: i == 1 ? activeOrders : 0,
                            onTap: () => onSelected(i),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = context.colors;
    final Duration duration = Motion.of(context, Kz.dSlow);
    final Color color = selected ? colors.primary : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: badge > 0 ? '${spec.label}, $badge in progress' : spec.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Kz.rMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedContainer(
                duration: duration,
                curve: Kz.emphasized,
                width: selected ? 60 : 40,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.14)
                      : colors.primary.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(Kz.rPill),
                ),
                child: Center(
                  child: Badge.count(
                    count: badge,
                    isLabelVisible: badge > 0,
                    backgroundColor: context.palette.warm,
                    textColor: Colors.black,
                    child: AnimatedSwitcher(
                      duration: Motion.of(context, Kz.dMedium),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.7,
                                end: 1,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                      child: Icon(
                        selected ? spec.selectedIcon : spec.icon,
                        key: ValueKey<bool>(selected),
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Kz.s1),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: duration,
                  style: (context.text.labelMedium ?? const TextStyle())
                      .copyWith(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                  child: Text(spec.label, maxLines: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
