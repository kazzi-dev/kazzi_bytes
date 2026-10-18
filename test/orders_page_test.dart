import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_bytes/controllers/account_controllers.dart';
import 'package:kazzi_bytes/controllers/app_controllers.dart';
import 'package:kazzi_bytes/controllers/cart_controller.dart';
import 'package:kazzi_bytes/controllers/catalog_controller.dart';
import 'package:kazzi_bytes/data/local_store.dart';
import 'package:kazzi_bytes/data/menu_data.dart';
import 'package:kazzi_bytes/data/models.dart';
import 'package:kazzi_bytes/data/repositories.dart';
import 'package:kazzi_bytes/pages/orders_page.dart';
import 'package:kazzi_bytes/theme/palette.dart';
import 'package:kazzi_bytes/widgets/app_scope.dart';

void main() {
  testWidgets('order detail sheet lays out', (WidgetTester tester) async {
    final LocalStore store = LocalStore.memory();
    final OrdersController orders = OrdersController(
      MockOrderRepository(latency: Duration.zero),
      progression: const <Duration>[],
    );
    await tester.runAsync(
      () => orders.place(
        lines: <CartLine>[CartLine(kMenu.first, 2)],
        type: OrderType.dineIn,
        payment: PaymentMethod.cash,
        breakdown: const PriceBreakdown(
          subtotal: 100,
          serviceFee: 10,
          discount: 0,
        ),
      ),
    );
    await tester.pumpWidget(
      AppScope(
        theme: ThemeController(store),
        auth: AuthController(MockAuthRepository(), store),
        cart: CartController(),
        catalog: CatalogController(MockMenuRepository()),
        favorites: FavoritesController(store),
        orders: orders,
        addresses: AddressesController(store),
        payments: PaymentMethodsController(store),
        notifications: NotificationSettingsController(store),
        tabIndex: ValueNotifier<int>(1),
        cartTargetKey: GlobalKey(),
        child: MaterialApp(
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[KzPalette.light],
          ),
          home: const Scaffold(body: OrdersPage()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text(orders.orders.first.number));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Completed'), findsOneWidget);
  });
}
