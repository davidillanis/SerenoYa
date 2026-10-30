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
  test(
    'consulta list-details con paginación y decodifica datos personales',
    () async {
      final requests = <Map<String, dynamic>>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, '/user-role/list-details');
            requests.add(options.queryParameters);
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
                        'name': 'Ana',
                        'lastName': 'Quispe',
                        'dni': '12345678',
                        'phone': '987654321',
                        'email': 'ana@example.com',
                        'enabled': false,
                        'emailVerified': true,
                        'birthDate': '1990-02-01',
                        'createdAt': '2026-01-01T12:00:00',
                      },
                    ],
                    'page': page,
                    'size': 15,
                    'totalElements': 2,
                    'totalPages': 2,
                  },
                },
              ),
            );
          },
        ),
      );
      final service = AdminUserApiService(dio);
      final firstPage = await service.listUsers();
      final secondPage = await service.listUsers(page: 1);

      expect(requests, [
        {'page': 0, 'size': 15, 'sortBy': 'createdAt', 'direction': 'DESC'},
        {'page': 1, 'size': 15, 'sortBy': 'createdAt', 'direction': 'DESC'},
      ]);
      expect(firstPage.data!.content.first.id, 'user-0');
      expect(secondPage.data!.content.first.id, 'user-1');
      expect(firstPage.data!.content.first.name, 'Ana');
      expect(firstPage.data!.content.first.lastName, 'Quispe');
      expect(firstPage.data!.content.first.dni, '12345678');
      expect(firstPage.data!.content.first.enabled, isFalse);
    },
  );

  testWidgets('muestra los datos nuevos y las acciones de gestión', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'isSuccess': true,
              'data': {
                'content': [
                  {
                    'id': 'user-1',
                    'name': 'Ana',
                    'lastName': 'Quispe',
                    'dni': '12345678',
                    'phone': '987654321',
                    'email': 'ana@example.com',
                    'enabled': true,
                  },
                ],
                'page': 0,
                'totalElements': 1,
                'totalPages': 1,
              },
            },
          ),
        ),
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
    expect(find.text('Ana Quispe'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.textContaining('12345678'), findsOneWidget);
    expect(find.text('Gestionar usuario'), findsOneWidget);
    expect(find.text('Filtrar por rol'), findsNothing);
    expect(find.text('Buscar usuarios'), findsOneWidget);
  });
}
