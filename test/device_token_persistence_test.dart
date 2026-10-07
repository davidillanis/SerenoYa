import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository.dart';
import 'package:sereno_ya/data/services/api/device_api_service.dart';
import 'package:sereno_ya/data/services/api/device_token_service.dart';
import 'package:sereno_ya/data/services/local/device_sync_storage.dart';
import 'package:sereno_ya/models/auth/auth_session.dart';
import 'package:sereno_ya/models/auth/auth_state.dart';
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
}

DeviceTokenService buildService(
  FakeAuth auth,
  Dio dio, {
  DeviceSyncStorage? storage,
  Future<String?> Function()? readDeviceId,
}) {
  return DeviceTokenService(
    authRepository: auth,
    apiService: DeviceApiService(dio),
    readDeviceId: readDeviceId ?? () async => 'android-id',
    osType: 'ANDROID',
    syncStorage: storage,
  );
}

Dio buildDio(
  List<RequestOptions> requests, {
  FutureOr<void> Function(RequestOptions, RequestInterceptorHandler)? onRequest,
}) {
  return Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) async {
          if (onRequest != null) {
            await onRequest(r, h);
            return;
          }
          requests.add(r);
          h.resolve(
            Response(
              requestOptions: r,
              data: {
                'isSuccess': true,
                'data': r.method == 'POST' ? 'server-uuid' : 1,
              },
            ),
          );
        },
      ),
    );
}

void main() {
  test('tras reinicio no llama a la red si nada cambió', () async {
    final auth = FakeAuth();
    final storage = InMemoryDeviceSyncStorage();
    final requests = <RequestOptions>[];
    final dio = buildDio(requests);

    auth.signIn('user-1');
    final first = buildService(auth, dio, storage: storage);
    await first.synchronizeToken('token-abc');
    expect(requests.single.path, '/device/create');
    first.dispose();

    // Simula reinicio: nuevo servicio con el mismo almacenamiento.
    requests.clear();
    final second = buildService(auth, dio, storage: storage);
    await second.synchronizeToken('token-abc');
    expect(requests, isEmpty);
    second.dispose();
    await auth.controller.close();
  });

  test('si cambia el token usa update y no create', () async {
    final auth = FakeAuth();
    final storage = InMemoryDeviceSyncStorage();
    final requests = <RequestOptions>[];
    final dio = buildDio(requests);

    auth.signIn('user-1');
    final service = buildService(auth, dio, storage: storage);
    await service.synchronizeToken('one');
    await service.synchronizeToken('two');
    expect(requests.map((r) => r.method), ['POST', 'PUT']);
    expect(requests.last.path, '/device/update/server-uuid');
    service.dispose();
    await auth.controller.close();
  });

  test('si el update devuelve 0 filas reintenta con create una vez', () async {
    final auth = FakeAuth();
    final requests = <RequestOptions>[];
    var updates = 0;
    final dio = buildDio(
      requests,
      onRequest: (r, h) {
        requests.add(r);
        if (r.method == 'POST' &&
            requests.where((e) => e.method == 'POST').length == 1) {
          h.resolve(
            Response(
              requestOptions: r,
              data: {'isSuccess': true, 'data': 'old-id'},
            ),
          );
        } else if (r.method == 'PUT') {
          updates++;
          h.resolve(
            Response(requestOptions: r, data: {'isSuccess': true, 'data': 0}),
          );
        } else {
          h.resolve(
            Response(
              requestOptions: r,
              data: {'isSuccess': true, 'data': 'new-id'},
            ),
          );
        }
      },
    );

    auth.signIn('user-1');
    final service = buildService(auth, dio);
    await service.synchronizeToken('one');
    await service.synchronizeToken('two');
    expect(updates, 1);
    expect(requests.last.method, 'POST');
    expect(requests.last.data['fcmToken'], 'two');
    service.dispose();
    await auth.controller.close();
  });

  test('si el update da 404 reintenta con create', () async {
    final auth = FakeAuth();
    final requests = <RequestOptions>[];
    var posts = 0;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (r, h) {
            requests.add(r);
            if (r.method == 'POST') {
              posts++;
              h.resolve(
                Response(
                  requestOptions: r,
                  data: {'isSuccess': true, 'data': 'id-$posts'},
                ),
              );
            } else {
              h.reject(
                DioException(
                  requestOptions: r,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: r,
                    statusCode: 404,
                    data: {'message': 'x'},
                  ),
                ),
              );
            }
          },
        ),
      );

    auth.signIn('user-1');
    final service = buildService(auth, dio);
    await service.synchronizeToken('one');
    await service.synchronizeToken('two');
    expect(requests.where((r) => r.method == 'POST'), hasLength(2));
    expect(requests.last.data['fcmToken'], 'two');
    service.dispose();
    await auth.controller.close();
  });
}
