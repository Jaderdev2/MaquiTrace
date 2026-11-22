import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maquitrace/features/transport/widgets/signature_pad.dart';

void main() {
  testWidgets('exports a signature drawn below the output height', (
    tester,
  ) async {
    final key = GlobalKey<SignaturePadState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 350,
            height: 580,
            child: SignaturePad(key: key, height: 580),
          ),
        ),
      ),
    );
    await tester.dragFrom(const Offset(60, 450), const Offset(180, 60));
    await tester.pump();
    await tester.runAsync(() async {
      final bytes = await key.currentState!.exportPngBytes(
        width: 600,
        height: 350,
      );
      expect(bytes, isNotNull);
      final codec = await ui.instantiateImageCodec(bytes!);
      final frame = await codec.getNextFrame();
      final pixels = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final values = pixels!.buffer.asUint8List();
      var darkPixels = 0;
      for (var i = 0; i < values.length; i += 4) {
        if (values[i] < 80 && values[i + 1] < 80 && values[i + 2] < 80)
          darkPixels++;
      }
      expect(darkPixels, greaterThan(100));
      frame.image.dispose();
      codec.dispose();
    });
  });
}
