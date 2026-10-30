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
  for (final brightness in Brightness.values) {
    for (final width in [320.0, 1200.0]) {
      for (final variant in [ThemeVariant.normal, ThemeVariant.pink]) {
        testWidgets(
          'directorio y ficha legibles: $brightness / $width / $variant',
          (tester) async {
            await _pumpDirectory(
              tester,
              width: width,
              brightness: brightness,
              variant: variant,
            );
            expect(tester.takeException(), isNull);
            expect(find.text('María Elena Apellido de prueba'), findsOneWidget);
            final manage = find.text(
              width < 960 ? 'Gestionar usuario' : 'Gestionar',
            );
            await tester.ensureVisible(manage);
            await tester.tap(manage);
            await tester.pumpAndSettle();
            expect(find.text('Roles actuales'), findsOneWidget);
            expect(find.text('Ciudadano'), findsOneWidget);
            expect(find.text('Editar roles'), findsOneWidget);
            expect(find.text('Editar sereno'), findsNothing);
            expect(tester.takeException(), isNull);
            await tester.tap(find.byTooltip('Cerrar ficha'));
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }

  testWidgets(
    'el buscador admite texto grande, teclado y limpiar antes del debounce',
    (tester) async {
      final queries = <Map<String, dynamic>>[];
      await _pumpDirectory(
        tester,
        width: 320,
        textScale: 1.6,
        queries: queries,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(find.byType(TextField), 'Texto pendiente');
      await tester.pump();
      await tester.ensureVisible(find.byTooltip('Limpiar búsqueda'));
      await tester.pump();
      await tester.tap(find.byTooltip('Limpiar búsqueda'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(queries, hasLength(1));
      expect(find.byTooltip('Limpiar búsqueda'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), 'Sin coincidencias');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(queries.last['search'], 'Sin coincidencias');
      await tester.scrollUntilVisible(
        find.text('Ver todos los usuarios'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver todos los usuarios'));
      await tester.pumpAndSettle();
      expect(queries.last.containsKey('search'), isFalse);
      expect(tester.takeException(), isNull);

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Gestionar usuario'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gestionar usuario'));
      await tester.pumpAndSettle();
      expect(find.text('Roles actuales'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'la ficha reintenta el detalle y conserva los cambios si falla el guardado',
    (tester) async {
      var detailRequests = 0;
      var mutations = 0;
      final bodies = <Object?>[];
      await _pumpDirectory(
        tester,
        onRequest: (options, handler) {
          if (options.path.contains('/byId/')) {
            detailRequests++;
            if (detailRequests == 1) {
              _resolve(options, handler, {
                'isSuccess': false,
                'message': 'No se pudo cargar la cuenta.',
              });
            } else {
              _resolve(options, handler, {
                'isSuccess': true,
                'data': {
                  'issoraId': 'account-1',
                  'id': 'internal-1',
                  'roles': [
                    {'role': 'OFFICER_SERENO'},
                  ],
                },
              });
            }
            return true;
          }
          if (options.path == '/user-role/update-roles') {
            mutations++;
            bodies.add(options.data);
            _resolve(options, handler, {
              'isSuccess': mutations > 1,
              'message': 'Intenta guardar de nuevo.',
            });
            return true;
          }
          return false;
        },
      );
      await tester.tap(find.text('Gestionar usuario'));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo cargar la cuenta.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar roles'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Código de sereno'),
        'SER-PRUEBA',
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(find.text('Intenta guardar de nuevo.'), findsOneWidget);
      expect(find.text('SER-PRUEBA'), findsOneWidget);
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(find.text('Editar roles'), findsNothing);
      expect(bodies, [
        {
          'userId': 'internal-1',
          'roles': ['OFFICER_SERENO'],
          'serenoDTO': {'codeSereno': 'SER-PRUEBA'},
        },
        {
          'userId': 'internal-1',
          'roles': ['OFFICER_SERENO'],
          'serenoDTO': {'codeSereno': 'SER-PRUEBA'},
        },
      ]);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _pumpDirectory(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  ThemeVariant variant = ThemeVariant.normal,
  List<Map<String, dynamic>>? queries,
  bool Function(RequestOptions, RequestInterceptorHandler)? onRequest,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  addTearDown(dio.close);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (onRequest?.call(options, handler) == true) return;
        if (options.path == '/user-role/list-details') {
          queries?.add(options.queryParameters);
          final hasSearch = options.queryParameters.containsKey('search');
          _resolve(options, handler, {
            'isSuccess': true,
            'data': {
              'content': hasSearch
                  ? []
                  : [
                      {
                        'id': 'account-1',
                        'name': 'María Elena',
                        'lastName': 'Apellido de prueba',
                        'email': 'correo.largo.de.prueba@example.com',
                        'dni': '00000001',
                        'phone': '000000000',
                        'enabled': true,
                      },
                    ],
              'page': 0,
              'totalElements': hasSearch ? 0 : 1,
              'totalPages': hasSearch ? 0 : 1,
            },
          });
        } else {
          _resolve(options, handler, {
            'isSuccess': true,
            'data': {
              'issoraId': 'account-1',
              'id': 'internal-1',
              'roles': [
                {'role': 'CITIZEN'},
              ],
            },
          });
        }
      },
    ),
  );
  final viewModel = AdminUsersViewModel(AdminUserApiService(dio));
  addTearDown(viewModel.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: viewModel,
      child: MaterialApp(
        theme: buildAppTheme(brightness, variant),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          appBar: AppBar(title: const Text('Administración')),
          body: const AdminUsersScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _resolve(
  RequestOptions options,
  RequestInterceptorHandler handler,
  Map<String, dynamic> data,
) {
  handler.resolve(
    Response<dynamic>(requestOptions: options, statusCode: 200, data: data),
  );
}
