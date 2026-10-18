import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/local_store.dart';
import '../data/models.dart';

// ---------------------------------------------------------------------------
// Account controllers
//
// Saved addresses, payment cards and notification preferences, persisted on
// the device so the demo keeps them between launches.
//
// TODO(backend): Sync these to the user's account (e.g. /v1/me/addresses,
// /v1/me/payment-methods, /v1/me/notification-preferences) and treat the
// server as the source of truth once signed in.
// ---------------------------------------------------------------------------

String _newId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

/// Shared list-with-a-default persistence for addresses and cards.
abstract class SavedListController<T> extends ChangeNotifier {
  SavedListController(this._store, this._key) {
    final String? raw = _store.getString(_key);
    if (raw == null) return;
    try {
      final Map<String, Object?> json = jsonDecode(raw) as Map<String, Object?>;
      _items.addAll(
        (json['items']! as List<Object?>).map(
          (Object? e) => fromJson(e! as Map<String, Object?>),
        ),
      );
      _defaultId = json['defaultId'] as String?;
    } on Object {
      _items.clear();
      _defaultId = null;
    }
  }

  final LocalStore _store;
  final String _key;
  final List<T> _items = <T>[];
  String? _defaultId;

  @protected
  T fromJson(Map<String, Object?> json);

  @protected
  Map<String, Object?> toJson(T item);

  String idOf(T item);

  List<T> get items => List<T>.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  /// The default item, falling back to the first one.
  T? get defaultItem {
    for (final T item in _items) {
      if (idOf(item) == _defaultId) return item;
    }
    return _items.isEmpty ? null : _items.first;
  }

  bool isDefault(T item) {
    final T? d = defaultItem;
    return d != null && idOf(d) == idOf(item);
  }

  /// Adds a new item or replaces an existing one with the same id.
  void save(T item, {bool makeDefault = false}) {
    final int index = _items.indexWhere((T e) => idOf(e) == idOf(item));
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
    if (makeDefault || _items.length == 1) _defaultId = idOf(item);
    _persist();
  }

  void setDefault(T item) {
    _defaultId = idOf(item);
    _persist();
  }

  /// Removes [item] and returns its index, for undo.
  int remove(T item) {
    final int index = _items.indexWhere((T e) => idOf(e) == idOf(item));
    if (index < 0) return -1;
    _items.removeAt(index);
    if (_defaultId == idOf(item)) {
      _defaultId = _items.isEmpty ? null : idOf(_items.first);
    }
    _persist();
    return index;
  }

  void restore(T item, int index, {required bool wasDefault}) {
    _items.insert(index.clamp(0, _items.length), item);
    if (wasDefault) _defaultId = idOf(item);
    _persist();
  }

  void _persist() {
    _store.setString(
      _key,
      jsonEncode(<String, Object?>{
        'defaultId': _defaultId,
        'items': _items.map(toJson).toList(),
      }),
    );
    notifyListeners();
  }
}

class AddressesController extends SavedListController<SavedAddress> {
  AddressesController(LocalStore store) : super(store, 'saved_addresses');

  static String newId() => _newId('addr');

  @override
  SavedAddress fromJson(Map<String, Object?> json) =>
      SavedAddress.fromJson(json);

  @override
  Map<String, Object?> toJson(SavedAddress item) => item.toJson();

  @override
  String idOf(SavedAddress item) => item.id;
}

class PaymentMethodsController extends SavedListController<SavedCard> {
  PaymentMethodsController(LocalStore store) : super(store, 'saved_cards');

  /// Saves a card from raw form input, keeping only display details.
  ///
  /// TODO(backend): Hand the raw details to your payment provider's SDK
  /// (PayMongo, Stripe, Xendit...) and store the token it returns instead.
  /// Raw card numbers must never reach your own servers or device storage.
  SavedCard addFromInput({
    required String number,
    required int expMonth,
    required int expYear,
    required String holder,
    bool makeDefault = false,
  }) {
    final String digits = number.replaceAll(RegExp(r'\D'), '');
    final SavedCard card = SavedCard(
      id: _newId('card'),
      brand: CardBrand.detect(digits),
      last4: digits.substring(digits.length - 4),
      expMonth: expMonth,
      expYear: expYear,
      holder: holder.trim(),
    );
    save(card, makeDefault: makeDefault);
    return card;
  }

  @override
  SavedCard fromJson(Map<String, Object?> json) => SavedCard.fromJson(json);

  @override
  Map<String, Object?> toJson(SavedCard item) => item.toJson();

  @override
  String idOf(SavedCard item) => item.id;
}

class NotificationSettingsController extends ChangeNotifier {
  NotificationSettingsController(this._store) {
    for (final NotificationTopic topic in NotificationTopic.values) {
      _enabled[topic] =
          _store.getBool('notify_${topic.name}') ?? topic.enabledByDefault;
    }
  }

  final LocalStore _store;
  final Map<NotificationTopic, bool> _enabled = <NotificationTopic, bool>{};

  bool isEnabled(NotificationTopic topic) => _enabled[topic] ?? false;

  bool get allOff => !_enabled.values.any((bool on) => on);

  void set(NotificationTopic topic, bool enabled) {
    _enabled[topic] = enabled;
    // TODO(backend): Register the preference with your push service (FCM
    // topics or your notifications API).
    _store.setBool('notify_${topic.name}', enabled);
    notifyListeners();
  }

  void setAll(bool enabled) {
    for (final NotificationTopic topic in NotificationTopic.values) {
      _enabled[topic] = enabled;
      _store.setBool('notify_${topic.name}', enabled);
    }
    notifyListeners();
  }
}
