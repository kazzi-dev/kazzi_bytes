// Renders the Kazzi Bytes logo (the "dot wordmark") into the PNGs used for
// the launcher icon and the native splash screen.
//
// Regenerate after changing the logo:
//   flutter test tool/generate_brand_assets_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// To use your own artwork instead, replace the PNGs in assets/branding/ and
// run the last two commands.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazzi_bytes/theme/palette.dart';

const String _font = 'KazziWordmark';

Future<void> _loadFont() async {
  final Uint8List bytes = File('tool/fonts/PlusJakartaSans-ExtraBold.ttf')
      .readAsBytesSync();
  await (FontLoader(
    _font,
  )..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)))).load();
}

Future<void> _write(
  String path,
  Size size,
  void Function(Canvas canvas, Size size) draw,
) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  draw(Canvas(recorder), size);
  final ui.Image image = await recorder.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
  final ByteData? bytes = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

TextPainter _text(
  List<TextSpan> spans,
  double fontSize, {
  double spacing = -0.04,
}) {
  return TextPainter(
    text: TextSpan(
      style: TextStyle(
        fontFamily: _font,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: fontSize * spacing,
        height: 1,
      ),
      children: spans,
    ),
    textDirection: TextDirection.ltr,
  )..layout();
}

/// Paints [painter] so its lowercase letters look vertically centered on
/// [center] (the optical middle of "k", not the middle of the line box).
void _paintCentered(Canvas canvas, TextPainter painter, Offset center) {
  final ui.LineMetrics line = painter.computeLineMetrics().first;
  final double half = painter.text!.style!.fontSize! * 0.36;
  painter.paint(
    canvas,
    Offset(center.dx - painter.width / 2, center.dy - line.baseline + half),
  );
}

/// "k." monogram for the app icon.
TextPainter _monogram(double fontSize, Color letter) => _text(<TextSpan>[
  TextSpan(
    text: 'k',
    style: TextStyle(color: letter),
  ),
  const TextSpan(
    text: '.',
    style: TextStyle(color: KazziBrand.dot),
  ),
], fontSize);

/// "kazzi." with a spaced-out "BYTES" underneath.
void _wordmark(Canvas canvas, Size size, Color ink, Color sub) {
  final TextPainter name = _text(<TextSpan>[
    TextSpan(
      text: 'kazzi',
      style: TextStyle(color: ink),
    ),
    const TextSpan(
      text: '.',
      style: TextStyle(color: KazziBrand.dot),
    ),
  ], 230);
  const double subSize = 64;
  const double subSpacing = 0.32;
  final TextPainter bytes = _text(
    <TextSpan>[
      TextSpan(
        text: 'BYTES',
        style: TextStyle(color: sub),
      ),
    ],
    subSize,
    spacing: subSpacing,
  );
  final Offset c = size.center(Offset.zero);
  _paintCentered(canvas, name, c.translate(0, -40));
  bytes.paint(canvas, Offset(c.dx - bytes.width / 2, c.dy + 70));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate brand assets', () async {
    await _loadFont();
    const Size square = Size.square(1024);
    const Color softWhite = Color(0xFFF2F2F4);

    // Full-bleed icon: iOS, web and legacy Android apply their own masks.
    await _write('assets/branding/app_icon.png', square, (Canvas c, Size s) {
      c.drawRect(Offset.zero & s, Paint()..color = KazziBrand.ink);
      _paintCentered(c, _monogram(600, Colors.white), s.center(Offset.zero));
    });

    // Android adaptive icon layers; the foreground stays in the 66% safe
    // zone so no launcher mask clips it.
    await _write(
      'assets/branding/app_icon_background.png',
      square,
      (Canvas c, Size s) =>
          c.drawRect(Offset.zero & s, Paint()..color = KazziBrand.ink),
    );
    await _write(
      'assets/branding/app_icon_foreground.png',
      square,
      (Canvas c, Size s) => _paintCentered(
        c,
        _monogram(400, Colors.white),
        s.center(Offset.zero),
      ),
    );
    // Themed (Material You) icons are tinted by the system: one flat color.
    await _write(
      'assets/branding/app_icon_monochrome.png',
      square,
      (Canvas c, Size s) => _paintCentered(
        c,
        _text(<TextSpan>[
          const TextSpan(
            text: 'k.',
            style: TextStyle(color: Colors.white),
          ),
        ], 400),
        s.center(Offset.zero),
      ),
    );

    // Splash wordmark, light and dark, drawn at 4x density.
    const Size wide = Size(1200, 600);
    await _write(
      'assets/branding/splash_light.png',
      wide,
      (Canvas c, Size s) =>
          _wordmark(c, s, KazziBrand.ink, const Color(0xFF8A8A93)),
    );
    await _write(
      'assets/branding/splash_dark.png',
      wide,
      (Canvas c, Size s) => _wordmark(c, s, softWhite, const Color(0xFF9A9AA3)),
    );

    // Android 12+ shows a centered icon inside a circle (768px of 1152).
    const Size a12 = Size.square(1152);
    await _write(
      'assets/branding/splash_a12_light.png',
      a12,
      (Canvas c, Size s) => _paintCentered(
        c,
        _monogram(440, KazziBrand.ink),
        s.center(Offset.zero),
      ),
    );
    await _write(
      'assets/branding/splash_a12_dark.png',
      a12,
      (Canvas c, Size s) =>
          _paintCentered(c, _monogram(440, softWhite), s.center(Offset.zero)),
    );
  });
}
