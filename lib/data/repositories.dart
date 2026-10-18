import 'dart:math';

import 'menu_data.dart';
import 'models.dart';

// ---------------------------------------------------------------------------
// Repositories
//
// Each repository is an interface plus a mock. The mocks fake network latency
// so every loading, error and success state in the UI can be seen today.
// When the backend is ready, write a class that implements the same interface
// (for example HttpMenuRepository) and pass it to KazziApp in main.dart.
// No UI code needs to change.
// ---------------------------------------------------------------------------

// ----- Menu ----------------------------------------------------------------

class MenuData {
  const MenuData({
    required this.categories,
    required this.dishes,
    required this.promos,
  });

  final List<String> categories;
  final List<Dish> dishes;
  final List<Promo> promos;
}

class MenuException implements Exception {
  const MenuException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class MenuRepository {
  Future<MenuData> fetchMenu();
}

class MockMenuRepository implements MenuRepository {
  MockMenuRepository({this.latency = const Duration(milliseconds: 1200)});

  final Duration latency;

  /// Demo switch (Profile > Demo controls) to show the error state.
  bool simulateFailure = false;

  @override
  Future<MenuData> fetchMenu() async {
    // TODO(backend): Replace with a real request, e.g. GET /v1/menu, and map
    // the JSON into Dish / Promo objects.
    await Future<void>.delayed(latency);
    if (simulateFailure) {
      throw const MenuException(
        'We couldn’t reach the kitchen. Check your connection and try again.',
      );
    }
    return const MenuData(
      categories: kCategories,
      dishes: kMenu,
      promos: kPromos,
    );
  }
}

// ----- Auth ----------------------------------------------------------------

enum SocialProvider { google, apple }

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthRepository {
  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUser> signInWithProvider(SocialProvider provider);

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

/// Accepts any well-formed email and password.
///
/// Demo accounts that show the error states:
/// - error@kazzi.dev signs in with "Incorrect email or password".
/// - taken@kazzi.dev fails sign-up with "account already exists".
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.latency = const Duration(milliseconds: 900)});

  final Duration latency;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    // TODO(backend): Call your auth provider (Firebase Auth, Supabase,
    // or POST /v1/auth/sign-in) and store the returned token securely.
    await Future<void>.delayed(latency);
    final String normalized = email.trim().toLowerCase();
    if (normalized == 'error@kazzi.dev') {
      throw const AuthException('Incorrect email or password.');
    }
    return AppUser(
      id: 'user_${normalized.hashCode.abs()}',
      name: _nameFromEmail(normalized),
      email: normalized,
    );
  }

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // TODO(backend): POST /v1/auth/sign-up.
    await Future<void>.delayed(latency);
    final String normalized = email.trim().toLowerCase();
    if (normalized == 'taken@kazzi.dev') {
      throw const AuthException('An account with this email already exists.');
    }
    return AppUser(
      id: 'user_${normalized.hashCode.abs()}',
      name: name.trim(),
      email: normalized,
    );
  }

  @override
  Future<AppUser> signInWithProvider(SocialProvider provider) async {
    // TODO(backend): Start the Google / Apple OAuth flow here
    // (google_sign_in, sign_in_with_apple, or your provider's SDK).
    await Future<void>.delayed(latency);
    return switch (provider) {
      SocialProvider.google => const AppUser(
        id: 'user_google_demo',
        name: 'Kazzi Foodie',
        email: 'foodie@gmail.com',
      ),
      SocialProvider.apple => const AppUser(
        id: 'user_apple_demo',
        name: 'Kazzi Foodie',
        email: 'foodie@icloud.com',
      ),
    };
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    // TODO(backend): POST /v1/auth/password-reset.
    await Future<void>.delayed(latency);
  }

  @override
  Future<void> signOut() async {
    // TODO(backend): Revoke the session token on the server.
  }

  static String _nameFromEmail(String email) {
    final String local = email.split('@').first;
    final List<String> words = local
        .split(RegExp(r'[._\-+0-9]+'))
        .where((String w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'Foodie';
    return words
        .map((String w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

// ----- Orders --------------------------------------------------------------

class OrderException implements Exception {
  const OrderException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class OrderRepository {
  Future<PlacedOrder> submitOrder({
    required List<CartLine> lines,
    required OrderType type,
    required PaymentMethod payment,
    required PriceBreakdown breakdown,
    String note,
  });
}

class MockOrderRepository implements OrderRepository {
  MockOrderRepository({this.latency = const Duration(milliseconds: 1600)});

  final Duration latency;
  final Random _random = Random();

  @override
  Future<PlacedOrder> submitOrder({
    required List<CartLine> lines,
    required OrderType type,
    required PaymentMethod payment,
    required PriceBreakdown breakdown,
    String note = '',
  }) async {
    // TODO(backend): POST /v1/orders with the lines, type, payment method and
    // note. The server should be the source of truth for prices and totals.
    await Future<void>.delayed(latency);
    final DateTime now = DateTime.now();
    return PlacedOrder(
      id: 'ord_${now.microsecondsSinceEpoch}',
      number: 'KB-${1000 + _random.nextInt(9000)}',
      lines: List<CartLine>.unmodifiable(lines),
      type: type,
      payment: payment,
      breakdown: breakdown,
      placedAt: now,
      statusTimes: <OrderStatus, DateTime>{OrderStatus.received: now},
      note: note,
    );
  }
}
