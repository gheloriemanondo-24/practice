import 'package:flutter/material.dart';

class AppColors {
  static const paper = Color(0xFF111214);
  static const card = Color(0xFF202226);
  static const ink = Color(0xFFF5F5F5);
  static const muted = Color(0xFFB0B3B8);
  static const rule = Color(0xFF414348);

  static const tomato = Color(0xFF777B82);
  static const tomatoSoft = Color(0xFF2A2C30);
  static const green = Color(0xFFC5C9CE);
  static const amber = Color(0xFFAFB3B9);

  // Additional colors
  static const background = paper;
  static const surface = card;
  static const surfaceAlt = tomatoSoft;
  static const text = ink;
  static const secondaryText = muted;
  static const border = rule;
  static const selectedBorder = Color(0xFF92959A);
  static const primary = Color(0xFFF2F2F2);
  static const onPrimary = Color(0xFF141517);
  static const removeBackground = Color(0xFF37393E);
}

ThemeData buildTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.tomato,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.tomato,
        onPrimary: Colors.white,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        outline: AppColors.rule,
      );

  final theme = ThemeData(useMaterial3: true, colorScheme: colorScheme);

  return theme.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    canvasColor: AppColors.paper,
    cardColor: AppColors.card,
    dividerColor: AppColors.rule,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),

    textTheme: theme.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),

    iconTheme: const IconThemeData(color: AppColors.ink),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      modalBackgroundColor: AppColors.card,
      dragHandleColor: AppColors.muted,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      labelStyle: const TextStyle(color: AppColors.muted),
      floatingLabelStyle: const TextStyle(color: AppColors.ink),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.rule),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.rule),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.ink),
    ),

    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.card,
      contentTextStyle: TextStyle(color: AppColors.ink),
      actionTextColor: AppColors.ink,
    ),
  );
}
