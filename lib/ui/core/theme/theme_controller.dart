import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mapped_palette.dart';
import 'theme.dart';

class ThemeController extends ChangeNotifier {
  static const preferenceKey = '@user_theme_variant';
  final SharedPreferences _preferences;
  late ThemeVariant _variant;
  Future<void> _pendingWrite = Future<void>.value();

  ThemeController({required SharedPreferences preferences})
    : _preferences = preferences {
    final saved = preferences.get(preferenceKey);
    _variant = ThemeVariant.values.firstWhere(
      (variant) => variant.name == saved,
      orElse: () => ThemeVariant.normal,
    );
  }

  ThemeVariant get variant => _variant;
  ThemeMode get themeMode => ThemeMode.system;
  ThemeData get light => buildAppTheme(Brightness.light, _variant);
  ThemeData get dark => buildAppTheme(Brightness.dark, _variant);

  Future<void> setVariant(ThemeVariant variant) {
    _variant = variant;
    notifyListeners();
    // Serialize writes so fast consecutive selections persist the latest one.
    final write = _pendingWrite.then((_) async {
      if (!await _preferences.setString(preferenceKey, variant.name)) {
        throw StateError('Could not persist theme variant.');
      }
    });
    _pendingWrite = write.catchError((Object _) {});
    return write;
  }

  AppTheme themeFor(Brightness brightness) => getTheme(
    brightness == Brightness.dark ? AppThemeMode.dark : AppThemeMode.light,
    _variant,
  );
}
