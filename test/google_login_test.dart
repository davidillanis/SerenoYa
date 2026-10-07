import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/services/auth/google_identity_service.dart';
import 'package:sereno_ya/models/auth/auth_failure.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/result.dart';
import 'package:sereno_ya/ui/auth/login_screen.dart';
import 'package:sereno_ya/ui/auth/view_models/login_view_model.dart';

import 'auth_view_models_test.dart' show RecordingAuthRepository;

class GoogleRepository extends RecordingAuthRepository {
  String? googleToken;
  bool fail = false;

  @override
  Future<Result<AuthSession>> loginWithGoogleIdToken(String idToken) {
    googleToken = idToken;
    if (fail) {
      return Future.value(
        Result.failure(
          const AuthFailure(AuthFailureCode.network, 'Sin conexión'),
        ),
      );
    }
    return super.loginWithGoogleIdToken(idToken);
  }
}

class FakeGoogleIdentity implements GoogleIdentityService {
  final completer = Completer<String?>();
  int calls = 0;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<String?> authenticateForIdToken() {
    calls++;
    return completer.future;
  }
}

void main() {
  late GoogleRepository repository;
  late FakeGoogleIdentity identity;
  late LoginViewModel model;
  var deviceRegistrations = 0;
  setUp(() {
    repository = GoogleRepository();
    identity = FakeGoogleIdentity();
    deviceRegistrations = 0;
    model = LoginViewModel(
      repository,
      googleIdentityService: identity,
      onLoginSuccess: () async {
        deviceRegistrations++;
      },
    );
  });

  test(
    'exchanges Google token and blocks simultaneous login attempts',
    () async {
      final pending = model.loginWithGoogle();
      expect(model.isGoogleLoading, isTrue);
      expect(await model.loginWithGoogle(), isFalse);
      expect(
        await model.login(email: 'test@example.com', password: 'test'),
        isFalse,
      );
      identity.completer.complete(' google-token ');
      expect(await pending, isTrue);
      expect(repository.googleToken, 'google-token');
      expect(identity.calls, 1);
      expect(deviceRegistrations, 1);
      expect(model.isLoading, isFalse);
      expect(model.errorMessage, isNull);
    },
  );

  test('canceling does not contact backend or display an error', () async {
    identity.completer.complete(null);
    expect(await model.loginWithGoogle(), isFalse);
    expect(repository.googleToken, isNull);
    expect(deviceRegistrations, 0);
    expect(model.errorMessage, isNull);
    expect(model.isLoading, isFalse);
  });

  test('empty token is rejected before backend exchange', () async {
    identity.completer.complete(' ');
    expect(await model.loginWithGoogle(), isFalse);
    expect(repository.googleToken, isNull);
    expect(model.errorMessage, contains('token válido'));
  });

  test('configuration failure resets loading and allows retry', () async {
    identity.completer.completeError(
      const GoogleIdentityException('Sin configuración'),
    );
    expect(await model.loginWithGoogle(), isFalse);
    expect(model.errorMessage, 'Sin configuración');
    expect(model.isGoogleLoading, isFalse);
    expect(model.isLoading, isFalse);
  });

  test('backend failure is shown without authenticating locally', () async {
    repository.fail = true;
    identity.completer.complete('google-token');
    expect(await model.loginWithGoogle(), isFalse);
    expect(model.errorMessage, 'Sin conexión');
    expect(deviceRegistrations, 0);
    expect(model.isLoading, isFalse);
  });

  test(
    'disposal during account selection avoids backend and notifications',
    () async {
      final pending = model.loginWithGoogle();
      model.dispose();
      identity.completer.complete('google-token');
      expect(await pending, isFalse);
      expect(repository.googleToken, isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('Google button loading and cancellation in $brightness', (
      tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: model,
          child: MaterialApp(
            theme: ThemeData(
              brightness: brightness,
              platform: TargetPlatform.android,
            ),
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Continuar con Google'));
      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.runAsync(() async {
        identity.completer.complete(null);
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(find.text('Continuar con Google'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
