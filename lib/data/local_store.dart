import 'package:shared_preferences/shared_preferences.dart';

/// Tiny key-value store for session, theme, onboarding and favorites.
///
/// Wraps [SharedPreferences] and falls back to memory (tests, or platforms
/// where the plugin is unavailable) so the app never crashes on startup.
class LocalStore {
  LocalStore._(this._prefs);

  /// A store that only lives in memory. Handy for tests.
  LocalStore.memory() : _prefs = null;

  final SharedPreferences? _prefs;
  final Map<String, Object> _memory = <String, Object>{};

  static Future<LocalStore> open() async {
    try {
      return LocalStore._(await SharedPreferences.getInstance());
    } on Object {
      return LocalStore.memory();
    }
  }

  String? getString(String key) {
    final SharedPreferences? prefs = _prefs;
    return prefs != null ? prefs.getString(key) : _memory[key] as String?;
  }

  bool? getBool(String key) {
    final SharedPreferences? prefs = _prefs;
    return prefs != null ? prefs.getBool(key) : _memory[key] as bool?;
  }

  List<String>? getStringList(String key) {
    final SharedPreferences? prefs = _prefs;
    return prefs != null
        ? prefs.getStringList(key)
        : _memory[key] as List<String>?;
  }

  Future<void> setString(String key, String value) async {
    final SharedPreferences? prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(key, value);
    } else {
      _memory[key] = value;
    }
  }

  Future<void> setBool(String key, bool value) async {
    final SharedPreferences? prefs = _prefs;
    if (prefs != null) {
      await prefs.setBool(key, value);
    } else {
      _memory[key] = value;
    }
  }

  Future<void> setStringList(String key, List<String> value) async {
    final SharedPreferences? prefs = _prefs;
    if (prefs != null) {
      await prefs.setStringList(key, value);
    } else {
      _memory[key] = List<String>.of(value);
    }
  }

  Future<void> remove(String key) async {
    final SharedPreferences? prefs = _prefs;
    if (prefs != null) {
      await prefs.remove(key);
    } else {
      _memory.remove(key);
    }
  }
}
