import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barcode_scanner_app/widgets/common/app_logo.dart';

/// Run with: flutter test test/generate_app_icon_test.dart
/// This generates a 1024x1024 PNG icon at assets/images/app_icon.png
/// Then run: dart run flutter_launcher_icons
void main() {
  test('Generate app icon PNG from AppLogoPainter', () async {
    const double size = 1024;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    AppLogoPainter().paint(canvas, const Size(size, size));

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File('assets/images/app_icon.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());

    // ignore: avoid_print
    print('App icon generated at: ${file.path} (${await file.length()} bytes)');
    expect(file.existsSync(), isTrue);
  });
}
