import 'package:flutter/widgets.dart';

import '../controllers/account_controllers.dart';
import '../controllers/app_controllers.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';

/// Hands the app-wide controllers to every route without prop drilling.
///
/// The controllers never change identity, so this never notifies; widgets
/// listen to the individual controllers with tightly scoped
/// ListenableBuilders instead.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.theme,
    required this.auth,
    required this.cart,
    required this.catalog,
    required this.favorites,
    required this.orders,
    required this.addresses,
    required this.payments,
    required this.notifications,
    required this.tabIndex,
    required this.cartTargetKey,
    required super.child,
  });

  final ThemeController theme;
  final AuthController auth;
  final CartController cart;
  final CatalogController catalog;
  final FavoritesController favorites;
  final OrdersController orders;
  final AddressesController addresses;
  final PaymentMethodsController payments;
  final NotificationSettingsController notifications;

  /// Selected bottom-navigation tab.
  final ValueNotifier<int> tabIndex;

  /// The header cart icon; target of the "fly to cart" animation.
  final GlobalKey cartTargetKey;

  static AppScope of(BuildContext context) {
    final AppScope? scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}
