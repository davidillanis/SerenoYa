import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/admin/admin_sereno_update_request.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';
import 'package:sereno_ya/ui/admin/users/admin_users_screen.dart';
import 'package:sereno_ya/ui/admin/users/view_models/admin_users_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

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

  testWidgets('edita solo el perfil de un sereno usando su userId', (
    tester,
  ) async {
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
              data: options.path == '/user-role/list'
                  ? {
                      'isSuccess': true,
                      'data': {
                        'content': [
                          {
                            'id': 'user-1',
                            'roles': ['OFFICER_SERENO'],
                          },
                          {
                            'id': 'user-2',
                            'roles': ['CITIZEN'],
                          },
                        ],
                        'page': 0,
                        'totalElements': 2,
                        'totalPages': 1,
                      },
                    }
                  : {'isSuccess': true, 'data': null},
            ),
          );
        },
      ),
    );
    final viewModel = AdminUsersViewModel(AdminUserApiService(dio));
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: viewModel,
        child: MaterialApp(
          theme: buildAppTheme(Brightness.light, ThemeVariant.normal),
          home: const Scaffold(body: AdminUsersScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Editar sereno'), findsOneWidget);
    await tester.tap(find.text('Editar sereno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(sentBody, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código de sereno'),
      'SER-01',
    );
    await tester.tap(find.byType(DropdownButtonFormField<AdminSerenoStatus?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Disponible').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(sentPath, '/user-role/sereno-update/user-1');
    expect(sentBody, {'codeSereno': 'SER-01', 'serviceStatus': 'AVAILABLE'});
  });
}
