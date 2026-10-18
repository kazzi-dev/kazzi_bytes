import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_bytes/controllers/cart_controller.dart';
import 'package:kazzi_bytes/data/format.dart';
import 'package:kazzi_bytes/data/menu_data.dart';
import 'package:kazzi_bytes/data/models.dart';

void main() {
  final Dish burger = kMenu.firstWhere((Dish d) => d.id == 'burger-classic');
  final Dish fries = kMenu.firstWhere((Dish d) => d.id == 'side-fries');

  group('formatPeso', () {
    test('adds thousands separators', () {
      expect(formatPeso(0), '₱0');
      expect(formatPeso(189), '₱189');
      expect(formatPeso(1250), '₱1,250');
      expect(formatPeso(1234567), '₱1,234,567');
    });
  });

  group('CartController', () {
    test('adds and removes dishes', () {
      final CartController cart = CartController();
      cart
        ..add(burger)
        ..add(burger)
        ..add(fries);
      expect(cart.quantityOf(burger), 2);
      expect(cart.itemCount, 3);
      expect(cart.total, burger.price * 2 + fries.price);

      cart.remove(burger);
      expect(cart.quantityOf(burger), 1);
      cart
        ..remove(burger)
        ..remove(fries);
      expect(cart.isEmpty, isTrue);
    });

    test('keeps add-on variants on separate lines', () {
      final CartController cart = CartController();
      final AddOn cheese = burger.addOns.first;
      cart
        ..add(burger)
        ..add(burger, addOns: <AddOn>[cheese], quantity: 2);
      expect(cart.lines.length, 2);
      expect(cart.quantityOf(burger), 3);
      expect(cart.total, burger.price + (burger.price + cheese.price) * 2);
    });

    test('restores a removed line at its old position', () {
      final CartController cart = CartController();
      cart
        ..add(burger)
        ..add(fries);
      final CartLine first = cart.lines.first;
      final int index = cart.removeLine(first);
      expect(cart.lines.single.dish, fries);
      cart.restoreLine(first, index);
      expect(cart.lines.first.dish, burger);
    });

    test('applies the demo promo code', () {
      final CartController cart = CartController()..add(burger);
      expect(cart.applyPromo('nope'), isFalse);
      expect(cart.applyPromo(' kazzi10 '), isTrue);
      expect(cart.discount, (burger.price * 0.1).round());
      expect(
        cart.breakdown.total,
        cart.total + cart.serviceFee - cart.discount,
      );
    });
  });
}
