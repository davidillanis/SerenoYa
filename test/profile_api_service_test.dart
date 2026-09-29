import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/profile/profile_update_request.dart';
import 'package:sereno_ya/data/services/api/profile/profile_api_service.dart';

void main() {
  test('consume los perfiles del usuario y ciudadano', () async {
    final requestedPaths = <String>[];
    final service = ProfileApiService(
      _profileDio((request) => requestedPaths.add(request.path)),
    );
    service.useCacheForUser('user-1');

    final user = await service.getUserProfile();
    final citizen = await service.getCitizenProfile();

    expect(requestedPaths, ['/user-role/me', '/citizens/me']);
    expect(user.data?.displayName, 'Ana Quispe');
    expect(user.data?.phone, '987654321');
    expect(citizen.data?.homeLatitude, -13.6519);
    expect(citizen.data?.homeLongitude, -73.365);
    expect(service.cachedUserProfile?.displayName, 'Ana Quispe');

    service.useCacheForUser('user-2');
    expect(service.cachedUserProfile, isNull);
    expect(service.cachedCitizenProfile, isNull);
  });

  test('envía las actualizaciones con los contratos del backend', () async {
    final requests = <RequestOptions>[];
    final service = ProfileApiService(_profileDio(requests.add));

    await service.updateUserProfile(
      const UserProfileUpdateRequest(
        name: 'Ana',
        lastName: 'Quispe',
        phone: '987654321',
        address: 'San Jerónimo',
      ),
    );
    await service.updateCitizenProfile(
      const CitizenProfileUpdateRequest(
        homeLatitude: -13.6519,
        homeLongitude: -73.365,
      ),
    );

    expect(requests[0].path, '/user-role/update-me');
    expect(requests[0].data, {
      'name': 'Ana',
      'lastName': 'Quispe',
      'phone': '987654321',
      'address': 'San Jerónimo',
    });
    expect(requests[1].path, '/citizens/update');
    expect(requests[1].data, {
      'homeLatitude': -13.6519,
      'homeLongitude': -73.365,
    });
  });
}

Dio _profileDio(void Function(RequestOptions request) onRequest) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest(options);
        final data = switch (options.path) {
          '/user-role/me' => {
            'id': 'user-1',
            'name': 'Ana',
            'lastName': 'Quispe',
            'email': 'ana@example.com',
            'dni': '12345678',
            'phone': '987654321',
            'address': 'San Jerónimo',
            'enabled': true,
            'emailVerified': true,
          },
          '/citizens/me' => {
            'id': 'citizen-1',
            'homeLatitude': -13.6519,
            'homeLongitude': -73.365,
            'createdAt': '2026-09-28T10:00:00',
          },
          _ => 'Perfil actualizado',
        };
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'isSuccess': true,
              'message': 'Successful operation',
              'errors': null,
              'data': data,
            },
          ),
        );
      },
    ),
  );
  return dio;
}
