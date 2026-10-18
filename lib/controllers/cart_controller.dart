import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/models.dart';

/// Holds the cart. Lines keep insertion order, and the same dish with
/// different add-ons becomes a separate line.
class CartController extends ChangeNotifier {
  final Map<String, CartLine> _lines = <String, CartLine>{};
  String? _promoCode;

  // TODO(backend): Validate promo codes on the server instead.
  static const Map<String, double> _promoCodes = <String, double>{
    'KAZZI10': 0.10,
  };

  /// Total quantity of [dish] across all its lines.
  int quantityOf(Dish dish) {
    int quantity = 0;
    for (final CartLine line in _lines.values) {
      if (line.dish.id == dish.id) quantity += line.quantity;
    }
    return quantity;
  }

  bool get isEmpty => _lines.isEmpty;

  int get itemCount =>
      _lines.values.fold<int>(0, (int sum, CartLine l) => sum + l.quantity);

  /// Cart lines in the order they were added.
  List<CartLine> get lines => List<CartLine>.unmodifiable(_lines.values);

  /// Items subtotal, before fees and discounts.
  int get total =>
      _lines.values.fold<int>(0, (int sum, CartLine l) => sum + l.subtotal);

  String? get promoCode => _promoCode;

  int get discount {
    final double? rate = _promoCodes[_promoCode];
    if (rate == null) return 0;
    return (total * rate).round();
  }

  /// 5% service fee with a ₱10 minimum.
  // TODO(backend): Fees should come from the server's pricing endpoint.
  int get serviceFee => total == 0 ? 0 : max(10, (total * 0.05).round());

  PriceBreakdown get breakdown => PriceBreakdown(
    subtotal: total,
    serviceFee: serviceFee,
    discount: discount,
  );

  void add(
    Dish dish, {
    List<AddOn> addOns = const <AddOn>[],
    int quantity = 1,
  }) {
    assert(quantity > 0);
    final String key = CartLine.keyFor(dish, addOns);
    final CartLine? existing = _lines[key];
    _lines[key] = existing == null
        ? CartLine(dish, quantity, addOns: List<AddOn>.unmodifiable(addOns))
        : existing.copyWith(quantity: existing.quantity + quantity);
    notifyListeners();
  }

  /// Removes one of [dish], preferring the plain line without add-ons.
  void remove(Dish dish) {
    CartLine? target = _lines[dish.id];
    if (target == null) {
      for (final CartLine line in _lines.values) {
        if (line.dish.id == dish.id) target = line;
      }
    }
    if (target != null) decrement(target);
  }

  void increment(CartLine line) {
    final CartLine? current = _lines[line.key];
    if (current == null) return;
    _lines[line.key] = current.copyWith(quantity: current.quantity + 1);
    notifyListeners();
  }

  void decrement(CartLine line) {
    final CartLine? current = _lines[line.key];
    if (current == null) return;
    if (current.quantity <= 1) {
      _lines.remove(line.key);
    } else {
      _lines[line.key] = current.copyWith(quantity: current.quantity - 1);
    }
    notifyListeners();
  }

  /// Removes a whole line and returns its position, for undo.
  int removeLine(CartLine line) {
    final int index = _lines.keys.toList().indexOf(line.key);
    if (index < 0) return -1;
    _lines.remove(line.key);
    notifyListeners();
    return index;
  }

  /// Puts a removed line back where it was.
  void restoreLine(CartLine line, int index) {
    final CartLine? existing = _lines[line.key];
    if (existing != null) {
      _lines[line.key] = existing.copyWith(
        quantity: existing.quantity + line.quantity,
      );
    } else {
      final List<MapEntry<String, CartLine>> entries = _lines.entries.toList();
      entries.insert(
        index.clamp(0, entries.length),
        MapEntry<String, CartLine>(line.key, line),
      );
      _lines
        ..clear()
        ..addEntries(entries);
    }
    notifyListeners();
  }

  /// Replaces the whole cart (used to undo "Clear").
  void restoreAll(List<CartLine> lines, {String? promoCode}) {
    _lines
      ..clear()
      ..addEntries(
        lines.map((CartLine l) => MapEntry<String, CartLine>(l.key, l)),
      );
    _promoCode = promoCode;
    notifyListeners();
  }

  /// Returns false when the code is not valid.
  bool applyPromo(String code) {
    final String normalized = code.trim().toUpperCase();
    if (!_promoCodes.containsKey(normalized)) return false;
    _promoCode = normalized;
    notifyListeners();
    return true;
  }

  void clearPromo() {
    if (_promoCode == null) return;
    _promoCode = null;
    notifyListeners();
  }

  void clear() {
    if (_lines.isEmpty && _promoCode == null) return;
    _lines.clear();
    _promoCode = null;
    notifyListeners();
  }
}
