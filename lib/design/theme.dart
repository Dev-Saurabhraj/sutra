import 'package:flutter/material.dart';

import 'tokens.dart';
import 'typography.dart';

abstract final class SutraTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: SutraColors.sindoor,
      primary: SutraColors.sindoor,
      onPrimary: Colors.white,
      secondary: SutraColors.neel,
      onSecondary: Colors.white,
      tertiary: SutraColors.haldi,
      surface: SutraColors.paper,
      onSurface: SutraColors.ink,
      error: SutraColors.kumkum,
      outline: SutraColors.rule,
    );
    final text = SutraType.textTheme();
    const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(SutraRadius.md));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: SutraColors.paper,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: SutraColors.paper,
        foregroundColor: SutraColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: SutraType.display(22),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(SutraSpace.minTouch, 52),
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(SutraSpace.minTouch, 52),
          shape: shape,
          side: const BorderSide(color: SutraColors.rule, width: 1.4),
          foregroundColor: SutraColors.ink,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: SutraColors.sindoor, textStyle: text.labelMedium),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SutraColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        // An underline like writing on a ledger line, not a boxed form field.
        border: const UnderlineInputBorder(borderSide: BorderSide(color: SutraColors.rule, width: 1.5)),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SutraColors.rule, width: 1.5)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: SutraColors.sindoor, width: 2)),
        labelStyle: text.bodyMedium?.copyWith(color: SutraColors.inkSoft),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SutraColors.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: shape,
      ),
      dividerTheme: const DividerThemeData(color: SutraColors.rule, thickness: 1, space: 1),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.transparent, elevation: 0),
    );
  }
}
