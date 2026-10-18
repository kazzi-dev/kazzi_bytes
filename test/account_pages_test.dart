import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_bytes/controllers/account_controllers.dart';
import 'package:kazzi_bytes/controllers/app_controllers.dart';
import 'package:kazzi_bytes/controllers/cart_controller.dart';
import 'package:kazzi_bytes/controllers/catalog_controller.dart';
import 'package:kazzi_bytes/data/local_store.dart';
import 'package:kazzi_bytes/data/models.dart';
import 'package:kazzi_bytes/data/repositories.dart';
import 'package:kazzi_bytes/pages/account/addresses_page.dart';
import 'package:kazzi_bytes/pages/account/notifications_page.dart';
import 'package:kazzi_bytes/pages/account/payment_methods_page.dart';
import 'package:kazzi_bytes/theme/palette.dart';
import 'package:kazzi_bytes/widgets/app_scope.dart';

class _Harness {
  _Harness() : store = LocalStore.memory() {
    addresses = AddressesController(store);
    payments = PaymentMethodsController(store);
    notifications = NotificationSettingsController(store);
  }

  final LocalStore store;
  late final AddressesController addresses;
  late final PaymentMethodsController payments;
  late final NotificationSettingsController notifications;

  Widget wrap(Widget page) {
    return AppScope(
      theme: ThemeController(store),
      auth: AuthController(MockAuthRepository(), store),
      cart: CartController(),
      catalog: CatalogController(MockMenuRepository()),
      favorites: FavoritesController(store),
      orders: OrdersController(MockOrderRepository()),
      addresses: addresses,
      payments: payments,
      notifications: notifications,
      tabIndex: ValueNotifier<int>(3),
      cartTargetKey: GlobalKey(),
      child: MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[KzPalette.light],
        ),
        home: page,
      ),
    );
  }
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).last);
  await tester.pump();
  await tester.tap(find.text(text).last);
}

Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('add an address through the form', (WidgetTester tester) async {
    final _Harness h = _Harness();
    await tester.pumpWidget(h.wrap(const AddressesPage()));
    await _settle(tester);
    expect(find.text('No saved addresses yet'), findsOneWidget);

    await tester.tap(find.text('Add new address'));
    await _settle(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Street address'),
      '123 Rizal St',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'City'),
      'Manila',
    );
    await _tap(tester, 'Save address');
    await _settle(tester);

    expect(h.addresses.items.single.street, '123 Rizal St');
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Default'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add a card; only last 4 digits are kept', (
    WidgetTester tester,
  ) async {
    final _Harness h = _Harness();
    await tester.pumpWidget(h.wrap(const PaymentMethodsPage()));
    await _settle(tester);
    expect(find.text('No saved cards'), findsOneWidget);

    await tester.tap(find.text('Add a card'));
    await _settle(tester);

    // An invalid number is rejected by the Luhn check.
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Card number'),
      '4242424242424241',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name on card'),
      'Juan Dela Cruz',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Expiry'),
      '0830',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'CVV'), '123');
    await _tap(tester, 'Save card');
    await _settle(tester);
    expect(find.text('That card number doesn’t look right'), findsOneWidget);
    expect(h.payments.isEmpty, isTrue);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Card number'),
      '4242424242424242',
    );
    // The formatters group the digits and insert the expiry slash.
    expect(find.text('4242 4242 4242 4242'), findsWidgets);
    expect(find.text('08/30'), findsWidgets);

    await _tap(tester, 'Save card');
    await _settle(tester);

    final SavedCard card = h.payments.items.single;
    expect(card.brand, CardBrand.visa);
    expect(card.last4, '4242');
    expect(find.text('Visa •••• 4242'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification switches persist', (WidgetTester tester) async {
    final _Harness h = _Harness();
    await tester.pumpWidget(h.wrap(const NotificationsPage()));
    await _settle(tester);

    await tester.tap(find.text('Order updates'));
    await _settle(tester);
    expect(h.notifications.isEnabled(NotificationTopic.orderUpdates), isFalse);

    await tester.tap(find.text('Send a test notification'));
    await _settle(tester);
    expect(find.text('Your order is ready! 🍔'), findsOneWidget);

    // Let the banner time out and dismiss itself.
    await tester.pump(const Duration(seconds: 5));
    await _settle(tester);
    expect(find.text('Your order is ready! 🍔'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
