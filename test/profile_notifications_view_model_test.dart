import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/services/api/device_api_service.dart';
import 'package:sereno_ya/data/services/api/device_token_service.dart';
import 'package:sereno_ya/ui/profile/view_models/profile_notifications_view_model.dart';

import 'device_token_service_test.dart' show FakeAuth;

void main() {
  late FakeAuth auth;
  late DeviceTokenService deviceTokens;
  late ProfileNotificationsViewModel viewModel;
  late List<RequestOptions> requests;
  late Future<String?> Function() readToken;
  var token = 'current-token';
  var fail = false;
  var viewModelDisposed = false;

  setUp(() {
    auth = FakeAuth()..signIn('user-1');
    requests = [];
    token = 'current-token';
    readToken = () async => token;
    fail = false;
    viewModelDisposed = false;
    final api = DeviceApiService(
      Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  data: {
                    'isSuccess': !fail,
                    'message': fail ? 'No se pudo procesar la prueba.' : 'OK',
                    'data': fail
                        ? null
                        : switch (options.path) {
                            '/device/create' => 'server-uuid',
                            '/device/notification/send' => 'message-id',
                            _ => 1,
                          },
                  },
                ),
              );
            },
          ),
        ),
    );
    deviceTokens = DeviceTokenService(
      authRepository: auth,
      apiService: api,
      readDeviceId: () async => 'hardware-id',
      osType: 'ANDROID',
    );
    viewModel = ProfileNotificationsViewModel(
      apiService: api,
      deviceTokens: deviceTokens,
      readToken: () => readToken(),
    );
  });

  tearDown(() async {
    if (!viewModelDisposed) viewModel.dispose();
    deviceTokens.dispose();
    await auth.controller.close();
  });

  test(
    'actualiza el registro con el token recién obtenido de Firebase',
    () async {
      await deviceTokens.synchronizeToken('old-token');
      expect(await viewModel.updateToken(), isTrue);
      expect(requests.map((r) => r.method), ['POST', 'PUT']);
      expect(requests.last.path, '/device/update/server-uuid');
      expect(requests.last.data['fcmToken'], 'current-token');
      expect(viewModel.successMessage, 'Token actualizado en el servidor.');
      expect(viewModel.isBusy, isFalse);
    },
  );

  test(
    'envía una prueba al token actual y vuelve a leerlo en cada envío',
    () async {
      expect(await viewModel.sendTestNotification(), isTrue);
      expect(requests.single.path, '/device/notification/send');
      expect(requests.single.data, {
        'token': 'current-token',
        'title': 'Prueba de SerenoYa',
        'body':
            'Esta es una notificación de prueba para comprobar los avisos '
            'y el sonido en tu dispositivo.',
      });
      token = 'renewed-token';
      expect(await viewModel.sendTestNotification(), isTrue);
      expect(requests.last.data['token'], 'renewed-token');
      expect(viewModel.successMessage, startsWith('Prueba enviada.'));
    },
  );

  for (final missingToken in [null, '', '  ']) {
    test(
      'sin token ($missingToken) muestra el problema y no llama a la API',
      () async {
        readToken = () async => missingToken;
        expect(await viewModel.updateToken(), isFalse);
        expect(await viewModel.sendTestNotification(), isFalse);
        expect(viewModel.errorMessage, startsWith('Token FCM no disponible.'));
        expect(viewModel.successMessage, isNull);
        expect(viewModel.isBusy, isFalse);
        expect(requests, isEmpty);
      },
    );
  }

  test('el fallo del backend se muestra y permite volver a enviar', () async {
    fail = true;
    expect(await viewModel.sendTestNotification(), isFalse);
    expect(viewModel.errorMessage, 'No se pudo procesar la prueba.');
    expect(viewModel.successMessage, isNull);
    expect(viewModel.isBusy, isFalse);
    fail = false;
    expect(await viewModel.sendTestNotification(), isTrue);
    expect(viewModel.errorMessage, isNull);
    expect(requests, hasLength(2));
  });

  test('una actualización rechazada nunca se presenta como exitosa', () async {
    await deviceTokens.synchronizeToken('old-token');
    fail = true;
    expect(await viewModel.updateToken(), isFalse);
    expect(viewModel.errorMessage, 'No se pudo procesar la prueba.');
    expect(viewModel.successMessage, isNull);
    expect(requests.map((r) => r.method), ['POST', 'PUT']);
  });

  test('un fallo de Firebase libera las acciones para reintentar', () async {
    readToken = () async => throw StateError('Firebase no disponible');
    expect(await viewModel.sendTestNotification(), isFalse);
    expect(viewModel.isBusy, isFalse);
    expect(viewModel.errorMessage, contains('No se pudo enviar'));
    expect(requests, isEmpty);
    readToken = () async => token;
    expect(await viewModel.sendTestNotification(), isTrue);
  });

  test('evita operaciones simultáneas mientras obtiene el token', () async {
    final pending = Completer<String?>();
    readToken = () => pending.future;
    final sending = viewModel.sendTestNotification();
    expect(viewModel.isSendingTest, isTrue);
    expect(await viewModel.updateToken(), isFalse);
    expect(await viewModel.sendTestNotification(), isFalse);
    pending.complete(token);
    expect(await sending, isTrue);
    expect(requests, hasLength(1));
    expect(viewModel.isBusy, isFalse);
  });

  test('salir del perfil antes de obtener el token cancela el envío', () async {
    final pending = Completer<String?>();
    readToken = () => pending.future;
    final sending = viewModel.sendTestNotification();
    viewModel.dispose();
    viewModelDisposed = true;
    pending.complete(token);
    expect(await sending, isFalse);
    expect(requests, isEmpty);
  });
}
