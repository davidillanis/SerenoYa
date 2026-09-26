import 'package:flutter/material.dart';

import 'mapped_palette.dart';
import 'theme.dart';

MappedPalette mapTheme(AppTheme theme) {
  return MappedPalette(
    text: theme.colors.text,
    textSecondary: theme.colors.textSecondary,
    textTertiary: theme.colors.textTertiary,
    textInverse: theme.colors.textInverse,

    background: theme.colors.background,
    surface: theme.colors.surface,
    surfaceVariant: theme.colors.surfaceVariant,
    card: theme.colors.card,
    modal: theme.colors.modal,
    row: theme.colors.row,
    gradient: theme.colors.gradient,

    icon: theme.colors.icon,
    tabIconDefault: theme.colors.tabIcon,
    tabIconSelected: theme.colors.tabIconSelected,

    primary: theme.colors.primary,
    secondary: theme.colors.secondary,

    tertiary: theme.colors.tertiary,

    border: theme.colors.border,
    borderVariant: theme.colors.borderVariant,

    success: theme.colors.success,
    successLight: theme.colors.successLight,
    warning: theme.colors.warning,
    warningLight: theme.colors.warningLight,
    error: theme.colors.error,
    errorLight: theme.colors.errorLight,
    info: theme.colors.info,
    infoLight: theme.colors.infoLight,

    button: theme.colors.button,
    buttonSecondary: theme.colors.buttonSecondary,

    fontPrimary: theme.fonts.primary,
    fontSecondary: theme.fonts.secondary,
    fontTertiary: theme.fonts.tertiary,
  );
}

/// Theme.of registers a dependency so consumers rebuild on theme changes.
extension AppColorsContext on BuildContext {
  MappedPalette get appColors {
    final palette = Theme.of(this).extension<MappedPalette>();
    if (palette == null) {
      throw FlutterError(
        'Register MappedPalette with buildAppTheme in MaterialApp.',
      );
    }
    return palette;
  }
}
