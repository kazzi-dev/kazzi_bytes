import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Menu
// ---------------------------------------------------------------------------

/// An optional extra a customer can add to a dish (e.g. extra cheese).
@immutable
class AddOn {
  const AddOn({required this.id, required this.name, required this.price});

  final String id;
  final String name;

  /// Whole pesos. Zero for free options.
  final int price;
}

@immutable
class Dish {
  const Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.icon,
    this.rating = 4.6,
    this.ratingCount = 120,
    this.prepMinutes = 10,
    this.calories = 400,
    this.isPopular = false,
    this.isNew = false,
    this.imageUrl,
    this.addOns = const <AddOn>[],
  });

  final String id;
  final String name;
  final String description;

  /// Whole pesos.
  final int price;
  final String category;
  final IconData icon;

  final double rating;
  final int ratingCount;
  final int prepMinutes;
  final int calories;
  final bool isPopular;
  final bool isNew;

  /// TODO(backend): Fill this from your API (for example a CDN URL). When set,
  /// DishImage shows the photo and keeps the gradient tile as its placeholder.
  final String? imageUrl;

  final List<AddOn> addOns;

  /// "120+", "1.2k" and so on.
  String get ratingCountLabel {
    if (ratingCount >= 1000) {
      return '${(ratingCount / 1000).toStringAsFixed(1)}k';
    }
    if (ratingCount >= 100) return '${(ratingCount ~/ 100) * 100}+';
    return '$ratingCount';
  }
}

/// A promo banner shown in the home carousel.
@immutable
class Promo {
  const Promo({
    required this.id,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    this.category,
  });

  final String id;
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  /// Gradient stops. Dark enough for white text to pass WCAG AA.
  final List<Color> colors;

  /// When set, tapping the banner filters the menu to this category.
  final String? category;
}

// ---------------------------------------------------------------------------
// Cart
// ---------------------------------------------------------------------------

@immutable
class CartLine {
  const CartLine(this.dish, this.quantity, {this.addOns = const <AddOn>[]});

  final Dish dish;
  final int quantity;
  final List<AddOn> addOns;

  /// Lines with the same dish but different add-ons are kept separate.
  static String keyFor(Dish dish, List<AddOn> addOns) {
    if (addOns.isEmpty) return dish.id;
    final List<String> ids = addOns.map((AddOn a) => a.id).toList()..sort();
    return '${dish.id}+${ids.join('+')}';
  }

  String get key => keyFor(dish, addOns);

  int get unitPrice =>
      dish.price + addOns.fold<int>(0, (int sum, AddOn a) => sum + a.price);

  int get subtotal => unitPrice * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(dish, quantity ?? this.quantity, addOns: addOns);
}

@immutable
class PriceBreakdown {
  const PriceBreakdown({
    required this.subtotal,
    required this.serviceFee,
    required this.discount,
  });

  final int subtotal;
  final int serviceFee;
  final int discount;

  int get total => subtotal + serviceFee - discount;
}

// ---------------------------------------------------------------------------
// Orders
// ---------------------------------------------------------------------------

enum OrderType {
  dineIn('Dine-in', Icons.restaurant_rounded),
  takeOut('Take-out', Icons.takeout_dining_rounded);

  const OrderType(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum PaymentMethod {
  cash('Cash', 'Pay at the counter', Icons.payments_rounded),
  gcash('GCash', 'Scan the QR code when you collect', Icons.qr_code_2_rounded),
  card('Card', 'Visa or Mastercard at the counter', Icons.credit_card_rounded);

  const PaymentMethod(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;
}

enum OrderStatus {
  received(
    'Received',
    'The kitchen has your order',
    Icons.receipt_long_rounded,
  ),
  preparing(
    'Preparing',
    'Your food is being cooked',
    Icons.soup_kitchen_rounded,
  ),
  ready('Ready', 'Come and get it, it’s hot', Icons.room_service_rounded),
  completed('Completed', 'Enjoy your meal!', Icons.check_circle_rounded);

  const OrderStatus(this.label, this.description, this.icon);

  final String label;
  final String description;
  final IconData icon;

  bool get isActive => this != OrderStatus.completed;
}

@immutable
class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.number,
    required this.lines,
    required this.type,
    required this.payment,
    required this.breakdown,
    required this.placedAt,
    this.status = OrderStatus.received,
    this.statusTimes = const <OrderStatus, DateTime>{},
    this.note = '',
  });

  final String id;

  /// Human-friendly number, e.g. "KB-4821".
  final String number;
  final List<CartLine> lines;
  final OrderType type;
  final PaymentMethod payment;
  final PriceBreakdown breakdown;
  final DateTime placedAt;
  final OrderStatus status;
  final Map<OrderStatus, DateTime> statusTimes;
  final String note;

  int get itemCount =>
      lines.fold<int>(0, (int sum, CartLine l) => sum + l.quantity);

  /// Rough ready time: the slowest dish plus a small buffer.
  int get etaMinutes {
    int slowest = 0;
    for (final CartLine line in lines) {
      if (line.dish.prepMinutes > slowest) slowest = line.dish.prepMinutes;
    }
    return slowest + 5;
  }

  String get summary =>
      lines.map((CartLine l) => '${l.quantity}× ${l.dish.name}').join(', ');

  PlacedOrder copyWith({
    OrderStatus? status,
    Map<OrderStatus, DateTime>? statusTimes,
  }) {
    return PlacedOrder(
      id: id,
      number: number,
      lines: lines,
      type: type,
      payment: payment,
      breakdown: breakdown,
      placedAt: placedAt,
      status: status ?? this.status,
      statusTimes: statusTimes ?? this.statusTimes,
      note: note,
    );
  }
}

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.isGuest = false,
  });

  const AppUser.guest()
    : id = 'guest',
      name = 'Guest',
      email = '',
      isGuest = true;

  factory AppUser.fromJson(Map<String, Object?> json) {
    return AppUser(
      id: json['id']! as String,
      name: json['name']! as String,
      email: json['email']! as String,
      isGuest: json['isGuest'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String email;
  final bool isGuest;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  String get initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final String first = parts.first[0];
    final String last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'email': email,
    'isGuest': isGuest,
  };
}

// ---------------------------------------------------------------------------
// Account: saved addresses, payment cards, notification preferences
// ---------------------------------------------------------------------------

enum AddressLabel {
  home('Home', Icons.home_rounded),
  work('Work', Icons.work_rounded),
  other('Other', Icons.place_rounded);

  const AddressLabel(this.label, this.icon);

  final String label;
  final IconData icon;
}

@immutable
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    this.title = '',
    this.details = '',
    this.notes = '',
  });

  factory SavedAddress.fromJson(Map<String, Object?> json) {
    return SavedAddress(
      id: json['id']! as String,
      label: AddressLabel.values.byName(json['label']! as String),
      street: json['street']! as String,
      city: json['city']! as String,
      title: json['title'] as String? ?? '',
      details: json['details'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  final String id;
  final AddressLabel label;

  /// Custom name for "Other" addresses, e.g. "Mom's place".
  final String title;
  final String street;

  /// Unit, floor or landmark.
  final String details;
  final String city;

  /// Instructions for pickup or delivery, e.g. "Gate code 1234".
  final String notes;

  String get displayTitle =>
      label == AddressLabel.other && title.trim().isNotEmpty
      ? title.trim()
      : label.label;

  String get oneLine => <String>[
    street,
    if (details.trim().isNotEmpty) details.trim(),
    city,
  ].join(', ');

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'label': label.name,
    'title': title,
    'street': street,
    'details': details,
    'city': city,
    'notes': notes,
  };
}

enum CardBrand {
  visa('Visa', <Color>[Color(0xFF1A3FD1), Color(0xFF0B1B6B)]),
  mastercard('Mastercard', <Color>[Color(0xFF2B2B33), Color(0xFF111116)]),
  amex('American Express', <Color>[Color(0xFF0E7C86), Color(0xFF0A4F5C)]),
  jcb('JCB', <Color>[Color(0xFF0F7A3D), Color(0xFF0A4A2A)]),
  unknown('Card', <Color>[Color(0xFF4B5563), Color(0xFF1F2937)]);

  const CardBrand(this.label, this.colors);

  final String label;

  /// Card face gradient, dark enough for white text.
  final List<Color> colors;

  /// Detects the brand from the leading digits (IIN ranges).
  static CardBrand detect(String digits) {
    if (digits.startsWith('4')) return CardBrand.visa;
    if (RegExp(r'^3[47]').hasMatch(digits)) return CardBrand.amex;
    if (RegExp(r'^35').hasMatch(digits)) return CardBrand.jcb;
    if (RegExp(r'^5[1-5]').hasMatch(digits)) return CardBrand.mastercard;
    if (digits.length >= 4) {
      final int prefix = int.parse(digits.substring(0, 4));
      if (prefix >= 2221 && prefix <= 2720) return CardBrand.mastercard;
    }
    return CardBrand.unknown;
  }
}

/// A saved card. Only display details are kept: never the full number or
/// the CVV.
@immutable
class SavedCard {
  const SavedCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.holder,
  });

  factory SavedCard.fromJson(Map<String, Object?> json) {
    return SavedCard(
      id: json['id']! as String,
      brand: CardBrand.values.byName(json['brand']! as String),
      last4: json['last4']! as String,
      expMonth: json['expMonth']! as int,
      expYear: json['expYear']! as int,
      holder: json['holder']! as String,
    );
  }

  final String id;
  final CardBrand brand;
  final String last4;
  final int expMonth;

  /// Four-digit year.
  final int expYear;
  final String holder;

  String get masked => '${brand.label} •••• $last4';

  String get expiry =>
      '${expMonth.toString().padLeft(2, '0')}/'
      '${(expYear % 100).toString().padLeft(2, '0')}';

  bool get isExpired {
    final DateTime now = DateTime.now();
    return expYear < now.year || (expYear == now.year && expMonth < now.month);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'brand': brand.name,
    'last4': last4,
    'expMonth': expMonth,
    'expYear': expYear,
    'holder': holder,
  };
}

/// Notification categories the user can switch on or off.
enum NotificationTopic {
  orderUpdates(
    'Order updates',
    'When your order is being prepared and when it’s ready',
    Icons.receipt_long_rounded,
    true,
  ),
  promotions(
    'Deals & promos',
    'Discount codes and limited-time offers',
    Icons.local_offer_rounded,
    true,
  ),
  newItems(
    'New on the menu',
    'Be the first to try new dishes',
    Icons.auto_awesome_rounded,
    false,
  ),
  receipts(
    'Email receipts',
    'A copy of every order in your inbox',
    Icons.mail_outline_rounded,
    true,
  );

  const NotificationTopic(
    this.label,
    this.description,
    this.icon,
    this.enabledByDefault,
  );

  final String label;
  final String description;
  final IconData icon;
  final bool enabledByDefault;
}
