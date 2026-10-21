import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/ui/auth/session_gate_screen.dart';

void main() {
  testWidgets('muestra la identidad de SerenoYa durante la carga', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SessionGateScreen()));

    final image = tester.widget<Image>(
      find.byKey(const Key('sereno-ya-loading-icon')),
    );

    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, 'assets/icon/app_icon.png');
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
    expect(find.text('Verificando sesión...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
