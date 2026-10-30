import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/models/admin/admin_sereno_update_request.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';

void main() {
  test('serializa únicamente los campos modificados', () {
    expect(
      const AdminSerenoUpdateRequest(serviceStatus: AdminSerenoStatus.offDuty)
          .toJson(),
      {'serviceStatus': 'OFF_DUTY'},
    );
    expect(const AdminSerenoUpdateRequest(codeSereno: 'SER-01').toJson(), {
      'codeSereno': 'SER-01',
    });
    expect(AdminSerenoStatus.values.map((status) => status.apiValue), [
      'AVAILABLE',
      'BUSY',
      'OFF_DUTY',
    ]);
  });

  test('envía la edición de sereno usando su userId', () async {
    String? sentPath;
    Map<String, dynamic>? sentBody;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/sereno-update/')) {
            sentPath = options.path;
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
    final response = await AdminUserApiService(dio).updateSereno(
      'user-1',
      const AdminSerenoUpdateRequest(
        codeSereno: 'SER-01',
        serviceStatus: AdminSerenoStatus.available,
      ),
    );
    expect(response.isSuccess, isTrue);
    expect(sentPath, '/user-role/sereno-update/user-1');
    expect(sentBody, {'codeSereno': 'SER-01', 'serviceStatus': 'AVAILABLE'});
  });
}
