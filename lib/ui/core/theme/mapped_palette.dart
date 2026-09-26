import 'package:flutter/material.dart';

enum ThemeVariant { normal, pink }

class MappedPalette extends ThemeExtension<MappedPalette> {
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color textInverse;

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color card;
  final Color modal;
  final Color row;
  final Color gradient;

  final Color icon;
  final Color tabIconDefault;
  final Color tabIconSelected;

  final Color primary;
  final Color secondary;
  final Color tertiary;

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

  final Color button;
  final Color buttonSecondary;

  final String fontPrimary;
  final String fontSecondary;
  final String fontTertiary;

  const MappedPalette({
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.card,
    required this.modal,
    required this.row,
    required this.gradient,
    required this.icon,
    required this.tabIconDefault,
    required this.tabIconSelected,
    required this.primary,
    required this.secondary,
    required this.tertiary,
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
    required this.button,
    required this.buttonSecondary,
    required this.fontPrimary,
    required this.fontSecondary,
    required this.fontTertiary,
  });

  @override
  MappedPalette copyWith({
    Color? text,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? card,
    Color? modal,
    Color? row,
    Color? gradient,
    Color? icon,
    Color? tabIconDefault,
    Color? tabIconSelected,
    Color? primary,
    Color? secondary,
    Color? tertiary,
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
    Color? button,
    Color? buttonSecondary,
    String? fontPrimary,
    String? fontSecondary,
    String? fontTertiary,
  }) => MappedPalette(
    text: text ?? this.text,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    textInverse: textInverse ?? this.textInverse,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceVariant: surfaceVariant ?? this.surfaceVariant,
    card: card ?? this.card,
    modal: modal ?? this.modal,
    row: row ?? this.row,
    gradient: gradient ?? this.gradient,
    icon: icon ?? this.icon,
    tabIconDefault: tabIconDefault ?? this.tabIconDefault,
    tabIconSelected: tabIconSelected ?? this.tabIconSelected,
    primary: primary ?? this.primary,
    secondary: secondary ?? this.secondary,
    tertiary: tertiary ?? this.tertiary,
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
    button: button ?? this.button,
    buttonSecondary: buttonSecondary ?? this.buttonSecondary,
    fontPrimary: fontPrimary ?? this.fontPrimary,
    fontSecondary: fontSecondary ?? this.fontSecondary,
    fontTertiary: fontTertiary ?? this.fontTertiary,
  );

  @override
  MappedPalette lerp(covariant MappedPalette? other, double t) {
    if (other == null) return this;
    return MappedPalette(
      text: Color.lerp(text, other.text, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      card: Color.lerp(card, other.card, t)!,
      modal: Color.lerp(modal, other.modal, t)!,
      row: Color.lerp(row, other.row, t)!,
      gradient: Color.lerp(gradient, other.gradient, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      tabIconDefault: Color.lerp(tabIconDefault, other.tabIconDefault, t)!,
      tabIconSelected: Color.lerp(tabIconSelected, other.tabIconSelected, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderVariant: Color.lerp(borderVariant, other.borderVariant, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      button: Color.lerp(button, other.button, t)!,
      buttonSecondary: Color.lerp(buttonSecondary, other.buttonSecondary, t)!,
      fontPrimary: t < 0.5 ? fontPrimary : other.fontPrimary,
      fontSecondary: t < 0.5 ? fontSecondary : other.fontSecondary,
      fontTertiary: t < 0.5 ? fontTertiary : other.fontTertiary,
    );
  }
}
