import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/models/admin/admin_user_update_request.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';
import 'package:sereno_ya/ui/admin/users/admin_user_edit_screen.dart';
import 'package:sereno_ya/ui/admin/users/view_models/admin_user_edit_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

void main() {
  test('la actualización administrativa omite null y conserva false', () {
    expect(const AdminUserUpdateRequest().toJson(), isEmpty);
    expect(
      const AdminUserUpdateRequest(
        name: 'Ana',
        lastName: 'Quispe',
        phone: '+51987654321',
        imageUrl: 'https://example.com/avatar.jpg',
        enabled: false,
        notificationsEnabled: false,
      ).toJson(),
      {
        'name': 'Ana',
        'lastName': 'Quispe',
        'phone': '+51987654321',
        'imageUrl': 'https://example.com/avatar.jpg',
        'enabled': false,
        'notificationsEnabled': false,
      },
    );
  });

  for (final brightness in Brightness.values) {
    for (final size in [const Size(390, 844), const Size(1200, 900)]) {
      testWidgets(
        'edita solo los cambios: ${brightness.name} / ${size.width}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final updates = <RequestOptions>[];
          final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
          dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                final updating = options.method == 'PUT';
                if (updating) updates.add(options);
                handler.resolve(
                  Response<dynamic>(
                    requestOptions: options,
                    statusCode: 200,
                    data: {
                      'isSuccess': !updating,
                      'message': 'No se pudo actualizar el usuario.',
                      'data': updating
                          ? null
                          : {
                              'id': 'user-1',
                              'name': 'Ana',
                              'lastName': 'Quispe',
                              'email': 'ana@example.com',
                              'phone': '987654321',
                              'enabled': true,
                              'notificationsEnabled': true,
                              'roles': [],
                            },
                    },
                  ),
                );
              },
            ),
          );
          final model = AdminUserEditViewModel(
            AdminUserApiService(dio),
            'user-1',
          );
          addTearDown(model.dispose);
          await tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: model,
              child: MaterialApp(
                theme: buildAppTheme(brightness, ThemeVariant.normal),
                home: const AdminUserEditScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('DNI'), findsNothing);
          expect(find.text('Dirección'), findsNothing);
          expect(find.text('Fecha de nacimiento'), findsNothing);

          final submit = find.widgetWithText(FilledButton, 'Guardar cambios');
          await tester.ensureVisible(submit);
          await tester.tap(submit);
          await tester.pumpAndSettle();
          expect(find.text('No hay cambios para guardar.'), findsOneWidget);
          expect(updates, isEmpty);
          await tester.pump(const Duration(seconds: 4));
          await tester.pumpAndSettle();

          await _fill(tester, 'Nombres', '');
          await _fill(tester, 'Celular', '+51987654321');
          await _fill(tester, 'URL de imagen', 'ftp://example.com/avatar.jpg');
          await tester.ensureVisible(submit);
          await tester.tap(submit);
          await tester.pumpAndSettle();
          expect(updates, isEmpty);
          expect(find.text('Ingresa una URL válida.'), findsOneWidget);
          await _fill(
            tester,
            'URL de imagen',
            'https://example.com/avatar.jpg',
          );
          for (final label in ['Cuenta activa', 'Notificaciones activadas']) {
            final toggle = find.widgetWithText(SwitchListTile, label);
            await tester.ensureVisible(toggle);
            await tester.tap(toggle);
            await tester.pumpAndSettle();
          }
          await tester.ensureVisible(submit);
          await tester.tap(submit);
          await tester.pumpAndSettle();

          expect(updates.single.path, '/user-role/update-admin');
          expect(updates.single.queryParameters, {'id': 'user-1'});
          expect(updates.single.data, {
            'phone': '+51987654321',
            'imageUrl': 'https://example.com/avatar.jpg',
            'enabled': false,
            'notificationsEnabled': false,
          });
          expect(
            find.text('No se pudo actualizar el usuario.'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

Future<void> _fill(WidgetTester tester, String label, String value) async {
  final field = find.widgetWithText(TextFormField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}
