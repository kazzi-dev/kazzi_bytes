import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_bytes/theme/palette.dart';
import 'package:kazzi_bytes/widgets/surfaces.dart';

void main() {
  testWidgets('pinned header fills its extent when content is shorter', (
    WidgetTester tester,
  ) async {
    // Mirrors a phone with a 24px status bar: the header reserves 96px but
    // its row is only 48px tall plus the 24px top padding.
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const <ThemeExtension<dynamic>>[KzPalette.light],
        ),
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: FrostedHeaderDelegate(
                  height: 96,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Row(children: <Widget>[SizedBox(height: 48)]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
