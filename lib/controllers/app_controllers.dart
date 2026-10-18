import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../data/models.dart';
import '../data/repositories.dart';

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

/// Holds the selected theme mode. Follows the device until the user picks
/// one, then remembers the choice.
class ThemeController extends ChangeNotifier {
  ThemeController(this._store) : _mode = _parse(_store.getString(_key));

  static const String _key = 'theme_mode';

  final LocalStore _store;
  ThemeMode _mode;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    _store.setString(_key, mode.name);
    notifyListeners();
  }

  void toggle(Brightness current) {
    setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
  }

  static ThemeMode _parse(String? value) => ThemeMode.values.firstWhere(
    (ThemeMode m) => m.name == value,
    orElse: () => ThemeMode.system,
  );
}

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

class AuthController extends ChangeNotifier {
  AuthController(this.repository, this._store)
    : _user = _restore(_store.getString(_userKey)),
      _onboardingSeen = _store.getBool(_onboardingKey) ?? false;

  static const String _userKey = 'auth_user';
  static const String _onboardingKey = 'onboarding_seen';

  final AuthRepository repository;
  final LocalStore _store;
  AppUser? _user;
  bool _onboardingSeen;

  AppUser? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isGuest => _user?.isGuest ?? false;
  bool get onboardingSeen => _onboardingSeen;

  void markOnboardingSeen() {
    _onboardingSeen = true;
    _store.setBool(_onboardingKey, true);
  }

  void resetOnboarding() {
    _onboardingSeen = false;
    _store.setBool(_onboardingKey, false);
  }

  Future<void> signIn({required String email, required String password}) async {
    _setUser(await repository.signIn(email: email, password: password));
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _setUser(
      await repository.signUp(name: name, email: email, password: password),
    );
  }

  Future<void> signInWith(SocialProvider provider) async {
    _setUser(await repository.signInWithProvider(provider));
  }

  void continueAsGuest() => _setUser(const AppUser.guest());

  Future<void> sendPasswordReset(String email) =>
      repository.sendPasswordReset(email);

  Future<void> signOut() async {
    await repository.signOut();
    _user = null;
    _store.remove(_userKey);
    notifyListeners();
  }

  void _setUser(AppUser user) {
    _user = user;
    // TODO(backend): Store auth tokens in flutter_secure_storage, not here.
    _store.setString(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
  }

  static AppUser? _restore(String? raw) {
    if (raw == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Favorites
// ---------------------------------------------------------------------------

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._store)
    : _ids = <String>{...?_store.getStringList(_key)};

  static const String _key = 'favorite_dishes';

  final LocalStore _store;
  final Set<String> _ids;

  Set<String> get ids => Set<String>.unmodifiable(_ids);

  bool isFavorite(Dish dish) => _ids.contains(dish.id);

  void toggle(Dish dish) {
    if (!_ids.remove(dish.id)) _ids.add(dish.id);
    // TODO(backend): Sync favorites to the user's account.
    _store.setStringList(_key, _ids.toList());
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Orders
// ---------------------------------------------------------------------------

class OrdersController extends ChangeNotifier {
  OrdersController(
    this.repository, {
    this.progression = const <Duration>[
      Duration(seconds: 6),
      Duration(seconds: 18),
      Duration(seconds: 45),
    ],
  });

  final OrderRepository repository;

  /// Demo delays for received → preparing → ready → completed.
  final List<Duration> progression;

  final List<PlacedOrder> _orders = <PlacedOrder>[];
  final List<Timer> _timers = <Timer>[];

  List<PlacedOrder> get orders => List<PlacedOrder>.unmodifiable(_orders);

  int get activeCount =>
      _orders.where((PlacedOrder o) => o.status.isActive).length;

  PlacedOrder? byId(String id) {
    for (final PlacedOrder order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  Future<PlacedOrder> place({
    required List<CartLine> lines,
    required OrderType type,
    required PaymentMethod payment,
    required PriceBreakdown breakdown,
    String note = '',
  }) async {
    final PlacedOrder order = await repository.submitOrder(
      lines: lines,
      type: type,
      payment: payment,
      breakdown: breakdown,
      note: note,
    );
    _orders.insert(0, order);
    notifyListeners();
    _simulateProgress(order.id);
    return order;
  }

  void _simulateProgress(String id) {
    // TODO(backend): Replace with a realtime subscription (WebSocket, FCM or
    // a Firestore snapshot) that pushes real status changes.
    const List<OrderStatus> steps = <OrderStatus>[
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.completed,
    ];
    for (int i = 0; i < steps.length && i < progression.length; i++) {
      _timers.add(Timer(progression[i], () => _setStatus(id, steps[i])));
    }
  }

  void _setStatus(String id, OrderStatus status) {
    final int index = _orders.indexWhere((PlacedOrder o) => o.id == id);
    if (index < 0) return;
    final PlacedOrder order = _orders[index];
    _orders[index] = order.copyWith(
      status: status,
      statusTimes: <OrderStatus, DateTime>{
        ...order.statusTimes,
        status: DateTime.now(),
      },
    );
    notifyListeners();
  }

  @override
  void dispose() {
    for (final Timer timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }
}
