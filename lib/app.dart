import 'package:flutter/material.dart';

import 'controllers/account_controllers.dart';
import 'controllers/app_controllers.dart';
import 'controllers/cart_controller.dart';
import 'controllers/catalog_controller.dart';
import 'data/local_store.dart';
import 'data/repositories.dart';
import 'pages/splash_page.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'widgets/app_scope.dart';

/// Root widget. Owns every controller and disposes them.
///
/// Pass real repositories here once the backend exists; the defaults are
/// mocks with simulated latency.
class KazziApp extends StatefulWidget {
  const KazziApp({
    super.key,
    required this.store,
    this.menuRepository,
    this.authRepository,
    this.orderRepository,
  });

  final LocalStore store;
  final MenuRepository? menuRepository;
  final AuthRepository? authRepository;
  final OrderRepository? orderRepository;

  @override
  State<KazziApp> createState() => _KazziAppState();
}

class _KazziAppState extends State<KazziApp> {
  late final ThemeController _theme = ThemeController(widget.store);
  late final AuthController _auth = AuthController(
    widget.authRepository ?? MockAuthRepository(),
    widget.store,
  );
  late final CartController _cart = CartController();
  late final CatalogController _catalog = CatalogController(
    widget.menuRepository ?? MockMenuRepository(),
  );
  late final FavoritesController _favorites = FavoritesController(widget.store);
  late final OrdersController _orders = OrdersController(
    widget.orderRepository ?? MockOrderRepository(),
  );
  late final AddressesController _addresses = AddressesController(widget.store);
  late final PaymentMethodsController _payments = PaymentMethodsController(
    widget.store,
  );
  late final NotificationSettingsController _notifications =
      NotificationSettingsController(widget.store);
  final ValueNotifier<int> _tabIndex = ValueNotifier<int>(0);
  final GlobalKey _cartTargetKey = GlobalKey(debugLabel: 'cart-target');

  @override
  void dispose() {
    _addresses.dispose();
    _payments.dispose();
    _notifications.dispose();
    _theme.dispose();
    _auth.dispose();
    _cart.dispose();
    _catalog.dispose();
    _favorites.dispose();
    _orders.dispose();
    _tabIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;

    return AppScope(
      theme: _theme,
      auth: _auth,
      cart: _cart,
      catalog: _catalog,
      favorites: _favorites,
      orders: _orders,
      addresses: _addresses,
      payments: _payments,
      notifications: _notifications,
      tabIndex: _tabIndex,
      cartTargetKey: _cartTargetKey,
      child: ListenableBuilder(
        listenable: _theme,
        builder: (BuildContext context, Widget? _) {
          return MaterialApp(
            title: 'Kazzi Bytes',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _theme.mode,
            themeAnimationDuration: reduceMotion ? Duration.zero : Kz.dSlow,
            themeAnimationCurve: Kz.standard,
            // Large text is supported everywhere; cap it at 2× so fixed
            // regions (headers, bars) stay usable.
            builder: (BuildContext context, Widget? child) {
              return MediaQuery.withClampedTextScaling(
                maxScaleFactor: 2,
                child: child!,
              );
            },
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
