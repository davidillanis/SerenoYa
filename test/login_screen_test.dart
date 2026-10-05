import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/ui/auth/login_screen.dart';
import 'package:sereno_ya/ui/auth/view_models/login_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

import 'auth_view_models_test.dart' show RecordingAuthRepository;

void main() {
  for (final variant in ThemeVariant.values) {
    for (final brightness in Brightness.values) {
      testWidgets('Login adapts and submits in $variant $brightness', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = RecordingAuthRepository();
        final model = LoginViewModel(repository);
        addTearDown(model.dispose);
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: model,
            child: MaterialApp(
              theme: buildAppTheme(brightness, variant),
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).first,
          'citizen@example.com',
        );
        await tester.enterText(find.byType(TextField).last, 'secret');
        await tester.tap(find.byTooltip('Mostrar contraseña'));
        await tester.pump();
        expect(
          tester.widget<TextField>(find.byType(TextField).last).obscureText,
          isFalse,
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pump();
        await tester.ensureVisible(find.text('Iniciar sesión'));
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();
        expect(repository.loginEmail, 'citizen@example.com');
        expect(repository.loginPassword, 'secret');
        tester.view.resetViewInsets();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: model,
            child: MaterialApp(
              theme: buildAppTheme(brightness, variant),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.ensureVisible(find.text('Crear cuenta de ciudadano'));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
