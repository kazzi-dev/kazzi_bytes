import 'package:flutter/material.dart';

import 'app.dart';
import 'data/local_store.dart';

// Kazzi Bytes
//
// lib/
//   main.dart          Entry point
//   app.dart           Root widget, controllers, MaterialApp
//   theme/             Design tokens, palette, theme, motion helpers
//   data/              Models, menu data, repositories (mock backend), storage
//   controllers/       ChangeNotifier state (cart, menu, auth, orders, ...)
//   widgets/           Reusable UI and motion building blocks
//   pages/             Screens

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final LocalStore store = await LocalStore.open();
  // TODO(backend): Pass real repositories here, e.g.
  // KazziApp(store: store, menuRepository: HttpMenuRepository(apiClient)).
  runApp(KazziApp(store: store));
}
