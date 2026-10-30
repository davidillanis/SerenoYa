import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';
import 'package:sereno_ya/ui/admin/users/admin_users_screen.dart';
import 'package:sereno_ya/ui/admin/users/view_models/admin_users_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

void main() {
  testWidgets('busca en el servidor y conserva el término al paginar', (
    tester,
  ) async {
    final queries = <Map<String, dynamic>>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          queries.add(options.queryParameters);
          final search = options.queryParameters['search'];
          final page = options.queryParameters['page'] as int;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'isSuccess': true,
                'data': {
                  'content': [
                    {
                      'id': 'user-$page',
                      'name': search ?? 'Todos',
                      'enabled': true,
                    },
                  ],
                  'page': page,
                  'totalElements': search == null ? 1 : 2,
                  'totalPages': search == null ? 1 : 2,
                },
              },
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
    await tester.enterText(find.byType(TextField).first, ' Ana ');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Ana'), findsOneWidget);
    await tester.tap(find.text('Cargar más usuarios'));
    await tester.pumpAndSettle();
    expect(queries.map((query) => query['search']), [null, 'Ana', 'Ana']);
    expect(queries.map((query) => query['page']), [0, 0, 1]);
    expect(viewModel.users.length, 2);
    await tester.tap(find.byTooltip('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(queries.last.containsKey('search'), isFalse);
  });

  testWidgets('consulta byId y usa el UUID interno para roles y sereno', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final paths = <String>[];
    Map<String, dynamic>? rolesBody;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          paths.add(options.path);
          if (options.path == '/user-role/update-roles') {
            rolesBody = Map<String, dynamic>.from(options.data as Map);
          }
          final data = switch (options.path) {
            '/user-role/list-details' => {
              'content': [
                {'id': 'issora-1', 'name': 'Ana', 'enabled': true},
              ],
              'page': 0,
              'totalElements': 1,
              'totalPages': 1,
            },
            '/user-role/byId/issora-1' => {
              'issoraId': 'issora-1',
              'id': 'internal-1',
              'name': 'Ana',
              'roles': [
                {'id': 3, 'role': 'OFFICER_SERENO'},
              ],
            },
            _ => null,
          };
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {'isSuccess': true, 'data': data},
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
          theme: buildAppTheme(Brightness.dark, ThemeVariant.normal),
          home: const Scaffold(body: AdminUsersScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gestionar usuario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar roles'));
    await tester.pumpAndSettle();
    expect(find.text('Editar roles'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Código de sereno'),
      'SER-01',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(rolesBody?['userId'], 'internal-1');
    expect(rolesBody?['roles'], ['OFFICER_SERENO']);

    await tester.tap(find.text('Gestionar usuario'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Editar sereno'));
    await tester.tap(find.text('Editar sereno'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Código de sereno'),
      'SER-02',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(paths, contains('/user-role/sereno-update/internal-1'));
    expect(paths.where((path) => path == '/user-role/byId/issora-1').length, 2);
  });
}
