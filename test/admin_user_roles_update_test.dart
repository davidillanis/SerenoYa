import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/admin/admin_user_roles_update_request.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';
import 'package:sereno_ya/ui/admin/users/admin_users_screen.dart';
import 'package:sereno_ya/ui/admin/users/view_models/admin_users_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

void main() {
  test('serializa los perfiles de todos los roles seleccionados', () {
    final request = AdminUserRolesUpdateRequest(
      userId: 'user-1',
      roles: {'CITIZEN', 'OFFICER_SERENO'},
      serenoCode: 'SER-01',
      serenoLatitude: -13.65,
      serenoLongitude: -71.67,
      citizenLatitude: -13.66,
      citizenLongitude: -71.68,
    );

    expect(request.toJson(), {
      'userId': 'user-1',
      'roles': ['CITIZEN', 'OFFICER_SERENO'],
      'serenoDTO': {
        'codeSereno': 'SER-01',
        'currentLatitude': -13.65,
        'currentLongitude': -71.67,
      },
      'citizenDTO': {'homeLatitude': -13.66, 'homeLongitude': -71.68},
    });
  });

  testWidgets('exige ubicación al asignar ciudadano y envía citizenDTO', (
    tester,
  ) async {
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
              data: options.path == '/user-role/list'
                  ? {
                      'isSuccess': true,
                      'data': {
                        'content': [
                          {
                            'id': 'user-1',
                            'roles': [],
                          },
                        ],
                        'page': 0,
                        'totalElements': 1,
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
    await tester.tap(find.byTooltip('Editar roles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ciudadano'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(sentBody, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Latitud del domicilio'),
      '-13.65',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Longitud del domicilio'),
      '-71.67',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(sentBody, {
      'userId': 'user-1',
      'roles': ['CITIZEN'],
      'citizenDTO': {'homeLatitude': -13.65, 'homeLongitude': -71.67},
    });
  });
}
