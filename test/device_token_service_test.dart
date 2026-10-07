import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/data/services/api/device_api_service.dart';
import 'package:sereno_ya/data/services/api/device_token_service.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/authenticated_user.dart';

class FakeAuth extends Fake implements AuthRepository {
  final controller = StreamController<AuthState>.broadcast(sync: true);
  @override
  AuthState state = const AuthState.unauthenticated();
  @override
  Stream<AuthState> get states => controller.stream;
  void signIn(String id) {
    state = AuthState(
      status: AuthStatus.authenticated,
      session: AuthSession(
        accessToken: 'test',
        refreshToken: 'test',
        user: AuthenticatedUser(
          id: id,
          email: '',
          firstName: '',
          lastName: '',
          roles: [],
        ),
      ),
    );
    controller.add(state);
  }

  @override
  Future<void> logout() async {
    state = const AuthState.unauthenticated();
    controller.add(state);
  }
}

void main() {
  late FakeAuth auth;
  late DeviceTokenService service;
  late List<RequestOptions> requests;
  var fail = false;
  setUp(() {
    auth = FakeAuth();
    requests = [];
    fail = false;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            requests.add(r);
            h.resolve(
              Response(
                requestOptions: r,
                data: {
                  'isSuccess': !fail,
                  'data': fail
                      ? null
                      : r.method == 'POST'
                      ? 'server-uuid'
                      : 1,
                },
              ),
            );
          },
        ),
      );
    service = DeviceTokenService(
      authRepository: auth,
      apiService: DeviceApiService(dio),
      readDeviceId: () async => 'android-id',
      osType: 'ANDROID',
    );
  });
  tearDown(() async {
    service.dispose();
    await auth.controller.close();
  });
  test(
    'espera sesión, registra y actualiza usando UUID del servidor',
    () async {
      await service.synchronizeToken('initial');
      expect(requests, isEmpty);
      auth.signIn('user-1');
      await service.synchronizeToken('initial');
      expect(requests.single.path, '/device/create');
      expect(requests.single.data['deviceId'], 'android-id');
      await service.synchronizeToken('renewed');
      expect(requests.last.path, '/device/update/server-uuid');
      expect(requests.last.data['fcmToken'], 'renewed');
      await service.synchronizeToken('renewed');
      expect(requests, hasLength(2));
    },
  );
  test('cierra sesión y registra para la nueva cuenta', () async {
    auth.signIn('user-1');
    await service.synchronizeToken('initial');
    await auth.logout();
    await service.synchronizeToken('renewed');
    expect(requests, hasLength(1));
    auth.signIn('user-2');
    await service.synchronizeToken('renewed');
    expect(requests, hasLength(2));
    expect(requests.last.path, '/device/create');
  });
  test('reintenta un registro fallido sin perder el token', () async {
    auth.signIn('user-1');
    fail = true;
    await service.synchronizeToken('initial');
    fail = false;
    await service.synchronizeToken('initial');
    expect(requests.last.method, 'POST');
    await service.synchronizeToken('renewed');
    expect(requests.last.method, 'PUT');
  });
  test(
    'serializa renovaciones simultáneas y conserva el último token',
    () async {
      auth.signIn('user-1');
      await service.synchronizeToken('initial');
      await Future.wait([
        service.synchronizeToken('second'),
        service.synchronizeToken('third'),
      ]);
      expect(requests.where((r) => r.method == 'POST'), hasLength(1));
      expect(requests.last.data['fcmToken'], 'third');
    },
  );
}
