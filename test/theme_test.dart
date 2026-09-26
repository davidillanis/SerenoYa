import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';
import 'package:sereno_ya/ui/core/theme/mapped_palette.dart';
import 'package:sereno_ya/ui/core/theme/theme.dart';
import 'package:sereno_ya/ui/core/theme/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'restores preferences and falls back for unknown or malformed values',
    () async {
      for (final saved in [null, 'pink', 'normal', 'unknown', 42]) {
        SharedPreferences.setMockInitialValues({
          ThemeController.preferenceKey: ?saved,
        });
        final controller = ThemeController(
          preferences: await SharedPreferences.getInstance(),
        );
        expect(
          controller.variant,
          saved == 'pink' ? ThemeVariant.pink : ThemeVariant.normal,
        );
        expect(controller.themeMode, ThemeMode.system);
        controller.dispose();
      }
    },
  );

  test(
    'notifies immediately and persists the latest consecutive selection',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final controller = ThemeController(preferences: preferences);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final first = controller.setVariant(ThemeVariant.pink);
      expect(controller.variant, ThemeVariant.pink);
      expect(notifications, 1);
      final last = controller.setVariant(ThemeVariant.normal);
      await Future.wait([first, last]);
      expect(preferences.getString('@user_theme_variant'), 'normal');
    },
  );

  test(
    'every registered palette preserves Material and custom color roles',
    () {
      expect(themeVariants.keys.toSet(), ThemeVariant.values.toSet());
      for (final variant in ThemeVariant.values) {
        for (final brightness in Brightness.values) {
          final source = getTheme(
            brightness == Brightness.dark
                ? AppThemeMode.dark
                : AppThemeMode.light,
            variant,
          );
          final theme = buildAppTheme(brightness, variant);
          final palette = theme.extension<MappedPalette>()!;
          expect(theme.colorScheme.primary, source.colors.primary);
          expect(theme.colorScheme.secondary, source.colors.secondary);
          expect(theme.colorScheme.tertiary, source.colors.tertiary);
          expect(theme.colorScheme.surface, source.colors.surface);
          expect(theme.scaffoldBackgroundColor, source.colors.background);
          expect(palette.tertiary, source.colors.tertiary);
          expect(palette.tabIconDefault, source.colors.tabIcon);
          expect(palette.tabIconSelected, source.colors.tabIconSelected);
          expect(palette.fontPrimary, 'Roboto');
        }
      }
    },
  );

  test('extension interpolates custom colors and supports copyWith', () {
    final light = mapTheme(lightTheme);
    final dark = mapTheme(darkTheme);
    expect(light.lerp(dark, 0).card, light.card);
    expect(light.lerp(dark, 1).card, dark.card);
    expect(
      light.lerp(dark, .5).tabIconDefault,
      Color.lerp(light.tabIconDefault, dark.tabIconDefault, .5),
    );
    expect(light.copyWith(tertiary: Colors.purple).tertiary, Colors.purple);
    expect(light.copyWith().background, light.background);
  });

  testWidgets('existing consumers rebuild for variant and system brightness', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController(
      preferences: await SharedPreferences.getInstance(),
    );
    addTearDown(controller.dispose);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final probe = Builder(
      builder: (context) => ColoredBox(
        key: const ValueKey('palette'),
        color: context.appColors.background,
        child: Text(
          'Theme',
          style: TextStyle(color: context.appColors.tertiary),
        ),
      ),
    );
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: controller,
        builder: (context, child) => MaterialApp(
          theme: controller.light,
          darkTheme: controller.dark,
          themeMode: controller.themeMode,
          home: child,
        ),
        child: probe,
      ),
    );
    Color background() =>
        tester.widget<ColoredBox>(find.byKey(const ValueKey('palette'))).color;
    expect(background(), const Color(0xFFE8F8F5));
    await controller.setVariant(ThemeVariant.pink);
    await tester.pumpAndSettle();
    expect(background(), const Color(0xFFF7F7F7));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(background(), const Color(0xFF2D2D2D));
    await controller.setVariant(ThemeVariant.normal);
    await tester.pumpAndSettle();
    expect(background(), const Color(0xFF08110D));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
