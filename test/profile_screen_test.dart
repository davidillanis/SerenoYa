import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sereno_ya/data/services/api/device_api_service.dart';
import 'package:sereno_ya/data/services/api/device_token_service.dart';
import 'package:sereno_ya/data/services/local/device_sync_storage.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme_controller.dart';
import 'package:sereno_ya/ui/core/widgets/app_drawer.dart';
import 'package:sereno_ya/ui/profile/profile_screen.dart';
import 'package:sereno_ya/data/services/api/profile/profile_api_service.dart';
import 'package:sereno_ya/ui/profile/view_models/profile_view_model.dart';
import 'package:sereno_ya/ui/profile/view_models/profile_notifications_view_model.dart';

import 'auth_view_models_test.dart' show RecordingAuthRepository;
import 'device_token_service_test.dart' show FakeAuth;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('drawer opens profile and persists theme in $brightness', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final controller = ThemeController(preferences: preferences);
      final session = SessionViewModel(RecordingAuthRepository());
      final updates = <Map<String, dynamic>>[];
      final deviceAuth = FakeAuth()..signIn('user-1');
      final deviceRequests = <RequestOptions>[];
      final pendingSend = Completer<void>();
      final deviceApi = DeviceApiService(
        _notificationDio(deviceRequests, pendingSend.future),
      );
      final deviceStorage = InMemoryDeviceSyncStorage();
      await deviceStorage.write(
        const DeviceSyncSnapshot(
          userId: 'user-1',
          recordId: 'server-uuid',
          deviceId: 'hardware-id',
          fcmToken: 'current-token',
          osType: 'ANDROID',
        ),
      );
      final deviceTokens = DeviceTokenService(
        authRepository: deviceAuth,
        apiService: deviceApi,
        readDeviceId: () async => 'hardware-id',
        osType: 'ANDROID',
        syncStorage: deviceStorage,
      );
      addTearDown(deviceTokens.dispose);
      addTearDown(deviceAuth.controller.close);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              appBar: AppBar(title: const Text('Inicio')),
              drawer: const AppDrawer(),
            ),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (_, _) => MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => ProfileViewModel(
                    ProfileApiService(_profileDio(updates)),
                    userId: 'user-1',
                    includeCitizenProfile: false,
                  ),
                ),
                ChangeNotifierProvider(
                  create: (_) => ProfileNotificationsViewModel(
                    apiService: deviceApi,
                    deviceTokens: deviceTokens,
                    readToken: () async => 'current-token',
                  ),
                ),
              ],
              child: const ProfileScreen(),
            ),
          ),
        ],
      );
      addTearDown(controller.dispose);
      addTearDown(session.dispose);
      addTearDown(router.dispose);
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeController>.value(value: controller),
            ChangeNotifierProvider<SessionViewModel>.value(value: session),
          ],
          child: Consumer<ThemeController>(
            builder: (_, theme, _) => MaterialApp.router(
              theme: theme.light,
              darkTheme: theme.dark,
              themeMode: theme.themeMode,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mi perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Datos personales'), findsOneWidget);
      expect(find.text('DNI'), findsNothing);
      await tester.tap(find.text('Editar perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Guardar cambios'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.widgetWithText(TextField, 'Dirección'),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(TextField, 'URL de imagen'), findsOneWidget);
      final nameField = find.widgetWithText(TextField, 'Nombres');
      await tester.ensureVisible(nameField);
      await tester.enterText(nameField, '');
      final phoneField = find.widgetWithText(TextField, 'Celular');
      await tester.ensureVisible(phoneField);
      await tester.enterText(phoneField, '+51987654321');
      final save = find.widgetWithText(FilledButton, 'Guardar cambios');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(updates.single, {'phone': '+51987654321'});
      expect(find.text('Perfil actualizado correctamente.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Recibir notificaciones'), 100);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(find.text('Notificaciones desactivadas.'), findsOneWidget);
      expect(updates.last, {'notificationsEnabled': false});
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      expect(updates.last, {'notificationsEnabled': true});
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      final updateToken = find.widgetWithText(
        OutlinedButton,
        'Actualizar token',
      );
      await tester.scrollUntilVisible(updateToken, 200);
      await tester.tap(updateToken);
      await tester.tap(updateToken);
      await tester.pumpAndSettle();
      expect(deviceRequests.single.path, '/device/update/server-uuid');
      expect(deviceRequests.single.data['fcmToken'], 'current-token');
      expect(find.text('Token actualizado en el servidor.'), findsOneWidget);

      final sendTest = find.widgetWithText(FilledButton, 'Enviar prueba');
      await tester.ensureVisible(sendTest);
      await tester.tap(sendTest);
      await tester.pump();
      expect(tester.widget<OutlinedButton>(updateToken).onPressed, isNull);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Enviando…'),
            )
            .onPressed,
        isNull,
      );
      pendingSend.complete();
      await tester.pumpAndSettle();
      expect(deviceRequests.last.path, '/device/notification/send');
      expect(deviceRequests.last.data['token'], 'current-token');
      expect(find.textContaining('Prueba enviada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Pink (rosa)'), 200);
      expect(find.text('Cambiar tema'), findsOneWidget);
      await tester.tap(find.text('Pink (rosa)'));
      await tester.pumpAndSettle();
      expect(controller.variant, ThemeVariant.pink);
      expect(preferences.getString('@user_theme_variant'), 'pink');
      final profileContext = tester.element(find.byType(ProfileScreen));
      expect(Theme.of(profileContext).brightness, brightness);
      expect(
        Theme.of(profileContext).extension<MappedPalette>()!.primary,
        const Color(0xFFEA044E),
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Azul'), 200);
      final blueTile = find.ancestor(
        of: find.text('Azul'),
        matching: find.byType(RadioListTile<ThemeVariant>),
      );
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: blueTile,
                matching: find.byIcon(Icons.circle),
              ),
            )
            .semanticLabel,
        'Azul',
      );
      await tester.tap(find.text('Azul'));
      await tester.pumpAndSettle();
      expect(controller.variant, ThemeVariant.blue);
      expect(preferences.getString('@user_theme_variant'), 'blue');
      await tester.tap(find.text('Normal (verde)'));
      await tester.pumpAndSettle();
      expect(preferences.getString('@user_theme_variant'), 'normal');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'la prueba permite reintentar con texto grande en $brightness',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final theme = ThemeController(
          preferences: await SharedPreferences.getInstance(),
        );
        final session = SessionViewModel(RecordingAuthRepository());
        final auth = FakeAuth()..signIn('user-1');
        final requests = <RequestOptions>[];
        final api = DeviceApiService(
          _notificationDio(requests, Future.value()),
        );
        final deviceTokens = DeviceTokenService(
          authRepository: auth,
          apiService: api,
          readDeviceId: () async => 'hardware-id',
          osType: 'ANDROID',
        );
        var tokenAvailable = false;
        addTearDown(theme.dispose);
        addTearDown(session.dispose);
        addTearDown(deviceTokens.dispose);
        addTearDown(auth.controller.close);
        await tester.binding.setSurfaceSize(const Size(320, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ThemeController>.value(value: theme),
              ChangeNotifierProvider<SessionViewModel>.value(value: session),
              ChangeNotifierProvider(
                create: (_) => ProfileViewModel(
                  ProfileApiService(_profileDio([])),
                  userId: 'user-1',
                  includeCitizenProfile: false,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => ProfileNotificationsViewModel(
                  apiService: api,
                  deviceTokens: deviceTokens,
                  readToken: () async =>
                      tokenAvailable ? 'current-token' : null,
                ),
              ),
            ],
            child: MaterialApp(
              theme: brightness == Brightness.dark ? theme.dark : theme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
              home: const ProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final sendTest = find.widgetWithText(FilledButton, 'Enviar prueba');
        await tester.scrollUntilVisible(sendTest, 200);
        await tester.pumpAndSettle();
        await tester.tap(sendTest);
        await tester.pumpAndSettle();
        final error = find.textContaining('Token FCM no disponible.');
        await tester.ensureVisible(error);
        await tester.pumpAndSettle();
        expect(error, findsOneWidget);
        expect(requests, isEmpty);
        expect(tester.takeException(), isNull);

        tokenAvailable = true;
        await tester.ensureVisible(sendTest);
        await tester.pumpAndSettle();
        await tester.tap(sendTest);
        await tester.pumpAndSettle();
        expect(error, findsNothing);
        expect(find.textContaining('Prueba enviada.'), findsOneWidget);
        expect(requests.single.path, '/device/notification/send');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

Dio _profileDio(List<Map<String, dynamic>> updates) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.method == 'PUT') {
          updates.add(Map<String, dynamic>.from(options.data as Map));
        }
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'isSuccess': true,
              'message': 'Successful operation',
              'errors': null,
              'data': options.method == 'PUT'
                  ? 'Perfil actualizado'
                  : {
                      'id': 'user-1',
                      'name': 'Ana',
                      'lastName': 'Quispe',
                      'email': 'ana@example.com',
                      'phone': '987654321',
                      'address': 'San Jerónimo',
                      'enabled': true,
                      'emailVerified': true,
                    },
            },
          ),
        );
      },
    ),
  );
  return dio;
}

Dio _notificationDio(List<RequestOptions> requests, Future<void> pendingSend) {
  return Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          requests.add(options);
          final isTest = options.path == '/device/notification/send';
          if (isTest) await pendingSend;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: {'isSuccess': true, 'data': isTest ? 'message-id' : 1},
            ),
          );
        },
      ),
    );
}
