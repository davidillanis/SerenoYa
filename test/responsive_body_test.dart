import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/ui/core/widgets/responsive_body.dart';

void main() {
  for (final bottom in [0.0, 24.0, 48.0]) {
    testWidgets('Content respects system inset $bottom', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 640),
              padding: EdgeInsets.fromLTRB(20, 30, 10, bottom),
            ),
            child: const Scaffold(
              body: ResponsiveBody(child: SizedBox.expand(key: Key('content'))),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byKey(const Key('content')));
      expect(rect.left, 20);
      expect(rect.right, 310);
      expect(rect.top, 30);
      expect(rect.bottom, 640 - bottom);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Wide web content is constrained and centered', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResponsiveBody(child: SizedBox.expand(key: Key('content'))),
        ),
      ),
    );
    final rect = tester.getRect(find.byKey(const Key('content')));
    expect(rect.width, 960);
    expect(rect.center.dx, 720);
    expect(tester.takeException(), isNull);
  });
}
