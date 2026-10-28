import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/admin/admin_user_create_request.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';

void main() {
  for (final role in AdminAssignableRole.values) {
    test('crea ${role.apiValue} con el contrato simplificado', () async {
      late RequestOptions sent;
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            sent = options;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'isSuccess': true,
                  'data': {
                    'id': 'user-1',
                    'name': 'Ana',
                    'lastName': 'Quispe',
                    'email': 'ana@example.com',
                    'roles': [role.apiValue],
                  },
                },
              ),
            );
          },
        ),
      );
      final response = await AdminUserApiService(dio).createUser(
        AdminUserCreateRequest(
          firstName: 'Ana',
          lastName: 'Quispe',
          phone: '+51987654321',
          email: 'ana@example.com',
          password: 'secret12',
          role: role,
          latitude: -13.65,
          longitude: -71.67,
        ),
      );

      expect(sent.method, 'POST');
      expect(sent.path, '/user-role/create');
      expect(sent.data, {
        'userDTO': {
          'name': 'Ana',
          'lastName': 'Quispe',
          'phone': '+51987654321',
          'email': 'ana@example.com',
          'password': 'secret12',
          'application': ['SerenoGo'],
          'roles': [role.apiValue],
        },
        'serenoDTO': role == AdminAssignableRole.officer
            ? {'currentLatitude': -13.65, 'currentLongitude': -71.67}
            : null,
        'citizenDTO': role == AdminAssignableRole.citizen
            ? {'homeLatitude': -13.65, 'homeLongitude': -71.67}
            : null,
      });
      expect(response.data?.id, 'user-1');
      expect(response.data?.roles, [role.apiValue]);
    });
  }
}
