import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/admin/admin_user_roles_update_request.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';

void main() {
  test('serializa los perfiles de todos los roles seleccionados', () {
    final request = AdminUserRolesUpdateRequest(
      userId: 'user-1',
      roles: {'CITIZEN', 'OFFICER_SERENO'},
      serenoCode: 'SER-01',
      citizenLatitude: -13.66,
      citizenLongitude: -71.68,
    );

    expect(request.toJson(), {
      'userId': 'user-1',
      'roles': ['CITIZEN', 'OFFICER_SERENO'],
      'serenoDTO': {'codeSereno': 'SER-01'},
      'citizenDTO': {'homeLatitude': -13.66, 'homeLongitude': -71.68},
    });
  });

  test('envía la actualización de roles a la API', () async {
    Map<String, dynamic>? sentBody;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/user-role/update-roles') {
            sentBody = Map<String, dynamic>.from(options.data as Map);
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {'isSuccess': true, 'data': null},
            ),
          );
        },
      ),
    );
    final response = await AdminUserApiService(dio).updateRoles(
      AdminUserRolesUpdateRequest(
        userId: 'user-1',
        roles: {'CITIZEN', 'OFFICER_SERENO'},
        serenoCode: 'SER-01',
        citizenLatitude: -13.65,
        citizenLongitude: -71.67,
      ),
    );
    expect(response.isSuccess, isTrue);
    expect(sentBody, {
      'userId': 'user-1',
      'roles': ['CITIZEN', 'OFFICER_SERENO'],
      'serenoDTO': {'codeSereno': 'SER-01'},
      'citizenDTO': {'homeLatitude': -13.65, 'homeLongitude': -71.67},
    });
  });
}
