import 'package:flutter/material.dart';

import 'mapped_palette.dart';
import 'colors.dart';

enum AppThemeMode { light, dark }

class AppThemeColors {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;

  final Color secondary;
  final Color secondaryLight;
  final Color secondaryDark;

  final Color tertiary;
  final Color tertiaryLight;
  final Color tertiaryDark;

  final Color background;
  final Color surface;
  final Color surfaceVariant;

  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;

  final Color border;
  final Color borderVariant;

  final Color success;
  final Color successLight;

  final Color warning;
  final Color warningLight;

  final Color error;
  final Color errorLight;

  final Color info;
  final Color infoLight;

  final Color card;
  final Color modal;
  final Color row;
  final Color gradient;

  final Color button;
  final Color buttonSecondary;

  final Color icon;
  final Color tabIcon;
  final Color tabIconSelected;

  const AppThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.secondary,
    required this.secondaryLight,
    required this.secondaryDark,
    required this.tertiary,
    required this.tertiaryLight,
    required this.tertiaryDark,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.border,
    required this.borderVariant,
    required this.success,
    required this.successLight,
    required this.warning,
    required this.warningLight,
    required this.error,
    required this.errorLight,
    required this.info,
    required this.infoLight,
    required this.card,
    required this.modal,
    required this.row,
    required this.gradient,
    required this.button,
    required this.buttonSecondary,
    required this.icon,
    required this.tabIcon,
    required this.tabIconSelected,
  });

  AppThemeColors copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? secondary,
    Color? secondaryLight,
    Color? secondaryDark,
    Color? tertiary,
    Color? tertiaryLight,
    Color? tertiaryDark,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? text,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? border,
    Color? borderVariant,
    Color? success,
    Color? successLight,
    Color? warning,
    Color? warningLight,
    Color? error,
    Color? errorLight,
    Color? info,
    Color? infoLight,
    Color? card,
    Color? modal,
    Color? row,
    Color? gradient,
    Color? button,
    Color? buttonSecondary,
    Color? icon,
    Color? tabIcon,
    Color? tabIconSelected,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      secondaryDark: secondaryDark ?? this.secondaryDark,
      tertiary: tertiary ?? this.tertiary,
      tertiaryLight: tertiaryLight ?? this.tertiaryLight,
      tertiaryDark: tertiaryDark ?? this.tertiaryDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textInverse: textInverse ?? this.textInverse,
      border: border ?? this.border,
      borderVariant: borderVariant ?? this.borderVariant,
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      card: card ?? this.card,
      modal: modal ?? this.modal,
      row: row ?? this.row,
      gradient: gradient ?? this.gradient,
      button: button ?? this.button,
      buttonSecondary: buttonSecondary ?? this.buttonSecondary,
      icon: icon ?? this.icon,
      tabIcon: tabIcon ?? this.tabIcon,
      tabIconSelected: tabIconSelected ?? this.tabIconSelected,
    );
  }
}

class AppFonts {
  final String primary;
  final String secondary;
  final String tertiary;

  const AppFonts({
    required this.primary,
    required this.secondary,
    required this.tertiary,
  });
}

class AppTheme {
  final AppThemeColors colors;
  final AppFonts fonts;

  const AppTheme({required this.colors, required this.fonts});

  AppTheme copyWith({AppThemeColors? colors, AppFonts? fonts}) {
    return AppTheme(colors: colors ?? this.colors, fonts: fonts ?? this.fonts);
  }
}

const appFonts = AppFonts(
  primary: 'Roboto',
  secondary: 'Inter',
  tertiary: 'Copperplate',
);

const lightTheme = AppTheme(
  colors: AppThemeColors(
    primary: Color(0xFF2ECC71),
    primaryLight: Color(0xFF58D68D),
    primaryDark: Color(0xFF239B56),

    secondary: Color(0xFFE67E22),
    secondaryLight: Color(0xFFF39C12),
    secondaryDark: Color(0xFFA04000),

    tertiary: Color(0xFF7F8C8D),
    tertiaryLight: Color(0xFFBDC3C7),
    tertiaryDark: Color(0xFF566573),

    background: Color(0xFFE8F8F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFD1F2EB),

    text: Color(0xFF0E2F1D),
    textSecondary: Color(0xFF196F3D),
    textTertiary: Color(0xFF5D6D7E),
    textInverse: Color(0xFFFFFFFF),

    border: Color(0xFFA9DFBF),
    borderVariant: Color(0xFFD1F2EB),

    success: Color(0xFF27AE60),
    successLight: Color(0xFFD4EFDF),

    warning: Color(0xFFF39C12),
    warningLight: Color(0xFFFDEBD0),

    error: Color(0xFFC0392B),
    errorLight: Color(0xFFFADBD8),

    info: Color(0xFF2980B9),
    infoLight: Color(0xFFEBF5FB),

    card: Color(0xFFFFFFFF),
    modal: Color(0xFFEAFAF1),
    row: Color(0xFFD1F2EB),
    gradient: Color(0xFF1E8449),

    button: Color(0xFF2ECC71),
    buttonSecondary: Color(0xFFE67E22),

    icon: Color(0xFF196F3D),
    tabIcon: Color(0xFF5D6D7E),
    tabIconSelected: Color(0xFF2ECC71),
  ),
  fonts: appFonts,
);

const darkTheme = AppTheme(
  colors: AppThemeColors(
    primary: Color(0xFF2ECC71),
    primaryLight: Color(0xFF58D68D),
    primaryDark: Color(0xFF239B56),

    secondary: Color(0xFFE67E22),
    secondaryLight: Color(0xFFF5B041),
    secondaryDark: Color(0xFFA04000),

    tertiary: Color(0xFF0E1A14),
    tertiaryLight: Color(0xFF145A32),
    tertiaryDark: Color(0xFF08110D),

    background: Color(0xFF08110D),
    surface: Color(0xFF0E1F15),
    surfaceVariant: Color(0xFF145A32),

    text: Color(0xFFE8F8F5),
    textSecondary: Color(0xFFA9DFBF),
    textTertiary: Color(0xFF52BE80),
    textInverse: Color(0xFF08110D),

    border: Color(0xFF2ECC71),
    borderVariant: Color(0xFF145A32),

    success: Color(0xFF27AE60),
    successLight: Color(0xFF145A32),

    warning: Color(0xFFF1C40F),
    warningLight: Color(0xFF7D6608),

    error: Color(0xFFE74C3C),
    errorLight: Color(0xFF641E16),

    info: Color(0xFF3498DB),
    infoLight: Color(0xFF1B4F72),

    card: Color(0xFF0E1F15),
    modal: Color(0xFF145A32),
    row: Color(0xFF112F1D),
    gradient: Color(0xFF1E8449),

    button: Color(0xFF2ECC71),
    buttonSecondary: Color(0xFFE67E22),

    icon: Color(0xFFA9DFBF),
    tabIcon: Color(0xFF52BE80),
    tabIconSelected: Color(0xFF2ECC71),
  ),
  fonts: appFonts,
);

const lightThemePink = AppTheme(
  colors: AppThemeColors(
    primary: Color(0xFFEA044E),
    primaryLight: Color(0xFFD8C99B),
    primaryDark: Color(0xFF1E40AF),

    secondary: Color(0xFF2D2D2D),
    secondaryLight: Color(0xFF10B981),
    secondaryDark: Color(0xFF047857),

    tertiary: Color(0xFFD97706),
    tertiaryLight: Color(0xFFF59E0B),
    tertiaryDark: Color(0xFFB45309),

    background: Color(0xFFF7F7F7),
    surface: Color(0xFFD1D1D1),
    surfaceVariant: Color(0xFFEA044E),

    text: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF000000),
    textInverse: Color(0xFFFFFFFF),

    border: Color(0xFF2D2D2D),
    borderVariant: Color(0xFFCBD5E1),

    success: Color(0xFF0A9C07),
    successLight: Color(0xFFD1FAE5),

    warning: Color(0xFFD97706),
    warningLight: Color(0xFFFEF3C7),

    error: Color(0xFFDC2626),
    errorLight: Color(0xFFFEE2E2),

    info: Color(0xFF2563EB),
    infoLight: Color(0xFFDBEAFE),

    card: Color(0xFFC0D6DF),
    modal: Color(0xFFC9C5BA),
    row: Color(0xFFC9C5BA),
    gradient: Color(0xFFF8441E),

    button: Color(0xFF2D2D2D),
    buttonSecondary: Color(0xFF626267),

    icon: Color(0xFF475569),
    tabIcon: Color(0xFF64748B),
    tabIconSelected: Color(0xFFC20114),
  ),
  fonts: appFonts,
);

const darkThemePink = AppTheme(
  colors: AppThemeColors(
    primary: Color(0xFFEA044E),
    primaryLight: Color(0xFF93C5FD),
    primaryDark: Color(0xFF3B82F6),

    secondary: Color(0xFFD8973C),
    secondaryLight: Color(0xFF6EE7B7),
    secondaryDark: Color(0xFF10B981),

    tertiary: Color(0xFF273E47),
    tertiaryLight: Color(0xFFFCD34D),
    tertiaryDark: Color(0xFFF59E0B),

    background: Color(0xFF2D2D2D),
    surface: Color(0xFF535353),
    surfaceVariant: Color(0xFFF8441E),

    text: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textTertiary: Color(0xFFA7A7A7),
    textInverse: Color(0xFF0F172A),

    border: Color(0xFFA4243B),
    borderVariant: Color(0xFF475569),

    success: Color(0xFF2AF527),
    successLight: Color(0xFF064E3B),

    warning: Color(0xFFFBBF24),
    warningLight: Color(0xFF451A03),

    error: Color(0xFFF87171),
    errorLight: Color(0xFF450A0A),

    info: Color(0xFF2196F3),
    infoLight: Color(0xFF1E3A8A),

    card: Color(0xFF333333),
    modal: Color(0xFF233D4D),
    row: Color(0xFF535353),
    gradient: Color(0xFFF8441E),

    button: Color(0xFF756E5C),
    buttonSecondary: Color(0xFFC9C9C9),

    icon: Color(0xFFCBD5E1),
    tabIcon: Color(0xFF94A3B8),
    tabIconSelected: Color(0xFFFF3A20),
  ),
  fonts: appFonts,
);

/// Add each new variant and its light/dark palettes here.
const themeVariants = <ThemeVariant, ({AppTheme light, AppTheme dark})>{
  ThemeVariant.normal: (light: lightTheme, dark: darkTheme),
  ThemeVariant.pink: (light: lightThemePink, dark: darkThemePink),
};

AppTheme getTheme(
  AppThemeMode mode, [
  ThemeVariant variant = ThemeVariant.normal,
]) {
  final pair = themeVariants[variant]!;
  return mode == AppThemeMode.dark ? pair.dark : pair.light;
}

ThemeData buildAppTheme(Brightness brightness, ThemeVariant variant) {
  final source = getTheme(
    brightness == Brightness.dark ? AppThemeMode.dark : AppThemeMode.light,
    variant,
  );
  final c = source.colors;
  // Explicit roles preserve the reference hex values; no seed generation.
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.textInverse,
    primaryContainer: c.primaryLight,
    onPrimaryContainer: c.text,
    secondary: c.secondary,
    onSecondary: c.textInverse,
    secondaryContainer: c.secondaryLight,
    onSecondaryContainer: c.text,
    tertiary: c.tertiary,
    onTertiary: c.textInverse,
    tertiaryContainer: c.tertiaryLight,
    onTertiaryContainer: c.text,
    error: c.error,
    onError: c.textInverse,
    errorContainer: c.errorLight,
    onErrorContainer: c.error,
    surface: c.surface,
    onSurface: c.text,
    onSurfaceVariant: c.textSecondary,
    surfaceContainerLowest: c.background,
    surfaceContainerLow: c.card,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.modal,
    surfaceContainerHighest: c.surfaceVariant,
    surfaceDim: c.background,
    surfaceBright: c.surface,
    outline: c.border,
    outlineVariant: c.borderVariant,
    inverseSurface: c.text,
    onInverseSurface: c.background,
    inversePrimary: c.primaryDark,
    surfaceTint: Colors.transparent,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: source.fonts.primary,
    scaffoldBackgroundColor: c.background,
    extensions: [mapTheme(source)],
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    iconTheme: IconThemeData(color: c.icon),
    dividerColor: c.borderVariant,
    disabledColor: c.textTertiary,
    appBarTheme: AppBarThemeData(
      backgroundColor: c.primary,
      foregroundColor: c.textInverse,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: c.card,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.modal,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.modal,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: c.surface,
      selectedItemColor: c.tabIconSelected,
      unselectedItemColor: c.tabIcon,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surface,
      indicatorColor: c.surfaceVariant,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? c.tabIconSelected
              : c.tabIcon,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? c.tabIconSelected
              : c.tabIcon,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.button,
        foregroundColor: c.textInverse,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.button,
        foregroundColor: c.textInverse,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      labelStyle: TextStyle(color: c.textSecondary),
      hintStyle: TextStyle(color: c.textTertiary),
      border: OutlineInputBorder(borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: c.primary, width: 2),
      ),
    ),
  );
}
