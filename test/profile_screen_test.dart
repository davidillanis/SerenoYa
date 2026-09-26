import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sereno_ya/routing/route_names.dart';
import 'package:sereno_ya/ui/auth/view_models/session_view_model.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme_controller.dart';
import 'package:sereno_ya/ui/core/widgets/app_drawer.dart';
import 'package:sereno_ya/ui/profile/profile_screen.dart';

import 'auth_view_models_test.dart' show RecordingAuthRepository;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('drawer opens profile and persists theme in $brightness', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final controller = ThemeController(preferences: preferences);
      final session = SessionViewModel(RecordingAuthRepository());
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
            builder: (_, _) => const ProfileScreen(),
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
      await tester.tap(find.text('Normal (verde)'));
      await tester.pumpAndSettle();
      expect(preferences.getString('@user_theme_variant'), 'normal');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
