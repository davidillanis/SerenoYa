import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sereno_ya/data/repositories/auth/auth_repository_impl.dart';
import 'package:sereno_ya/data/services/api/admin/admin_user_api_service.dart';
import 'package:sereno_ya/data/services/api/auth/auth_api_service.dart';
import 'package:sereno_ya/data/services/storage/session_storage_service.dart';
import 'package:sereno_ya/ui/admin/users/admin_user_create_screen.dart';
import 'package:sereno_ya/ui/admin/users/view_models/admin_user_create_view_model.dart';
import 'package:sereno_ya/ui/auth/register_screen.dart';
import 'package:sereno_ya/ui/auth/view_models/register_view_model.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final size in [const Size(390, 844), const Size(1200, 900)]) {
      final variant = '${brightness.name} / ${size.width}';

      testWidgets('registro ciudadano simplificado: $variant', (tester) async {
        _setSize(tester, size);
        Map<String, dynamic>? sent;
        final dio = _recordingDio((body) => sent = body);
        final viewModel = RegisterViewModel(_repository(dio));
        addTearDown(viewModel.dispose);
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: viewModel,
            child: MaterialApp(
              theme: buildAppTheme(brightness, ThemeVariant.normal),
              home: const RegisterScreen(),
            ),
          ),
        );
        expect(find.text('DNI'), findsNothing);
        expect(find.text('Dirección'), findsNothing);
        expect(find.text('Nombres (opcional)'), findsOneWidget);
        await _fill(tester, 'Celular', '+51987654321');
        await _fill(tester, 'Correo electrónico', 'ana@example.com');
        await _fill(tester, 'Contraseña', 'secret12');
        await _fill(tester, 'Confirmar contraseña', 'secret12');
        final submit = find.widgetWithText(FilledButton, 'Crear cuenta');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();

        expect(sent, {
          'name': '',
          'lastName': '',
          'phone': '+51987654321',
          'email': 'ana@example.com',
          'password': 'secret12',
        });
        expect(find.text('No se pudo crear la cuenta.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('registro administrativo simplificado: $variant', (
        tester,
      ) async {
        _setSize(tester, size);
        Map<String, dynamic>? sent;
        final dio = _recordingDio((body) => sent = body);
        final viewModel = AdminUserCreateViewModel(AdminUserApiService(dio));
        final session = SessionViewModel(_repository(dio));
        addTearDown(viewModel.dispose);
        addTearDown(session.dispose);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: viewModel),
              ChangeNotifierProvider.value(value: session),
            ],
            child: MaterialApp(
              theme: buildAppTheme(brightness, ThemeVariant.normal),
              home: const AdminUserCreateScreen(),
            ),
          ),
        );
        expect(find.text('DNI'), findsNothing);
        expect(find.text('Dirección'), findsNothing);
        expect(find.text('Fecha de nacimiento'), findsNothing);
        await _fill(tester, 'Celular', '+51987654321');
        await _fill(tester, 'Correo electrónico', 'ana@example.com');
        await _fill(tester, 'Contraseña temporal', 'secret12');
        await _fill(tester, 'Latitud operativa inicial', '-13.65');
        await _fill(tester, 'Longitud operativa inicial', '-71.67');
        final submit = find.widgetWithText(FilledButton, 'Registrar usuario');
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pumpAndSettle();

        expect(sent, {
          'userDTO': {
            'name': '',
            'lastName': '',
            'phone': '+51987654321',
            'email': 'ana@example.com',
            'password': 'secret12',
            'application': ['SerenoGo'],
            'roles': ['OFFICER_SERENO'],
          },
          'serenoDTO': {'currentLatitude': -13.65, 'currentLongitude': -71.67},
          'citizenDTO': null,
        });
        expect(find.text('No se pudo crear la cuenta.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

void _setSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _fill(WidgetTester tester, String label, String text) async {
  final field = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

AuthRepositoryImpl _repository(Dio dio) =>
    AuthRepositoryImpl(AuthApiService(dio), SessionStorageService());

Dio _recordingDio(void Function(Map<String, dynamic>) onRequest) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest(Map<String, dynamic>.from(options.data as Map));
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'isSuccess': false,
              'message': 'No se pudo crear la cuenta.',
            },
          ),
        );
      },
    ),
  );
  return dio;
}
