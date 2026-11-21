import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Font families bundled in assets/fonts.
abstract final class AppFonts {
  /// Headings and numbers.
  static const display = 'Prompt';

  /// UI and body text.
  static const body = 'Anuphan';
}

/// Text styles used across the app.
abstract final class AppText {
  static const _numbers = [FontFeature.tabularFigures()];

  static TextStyle display(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w600}) =>
      TextStyle(
          fontFamily: AppFonts.display,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.15,
          fontFeatures: _numbers);

  static TextStyle body(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontFamily: AppFonts.body, fontSize: size, fontWeight: weight, color: color, height: 1.4);

  /// Small uppercase English sublabel (e.g. "TOTAL CREDIT").
  static TextStyle caption({Color color = AppColors.faint}) => TextStyle(
      fontFamily: AppFonts.body, fontSize: 10.5, fontWeight: FontWeight.w500, color: color, letterSpacing: .8);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.magenta,
      primary: AppColors.magenta,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: AppColors.blush,
      splashFactory: InkSparkle.splashFactory,
      textTheme: ThemeData.light()
          .textTheme
          .apply(fontFamily: AppFonts.body, bodyColor: AppColors.ink, displayColor: AppColors.ink),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
        textStyle: AppText.body(12.5, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        waitDuration: const Duration(milliseconds: 300),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: AppText.body(13.5, color: Colors.white),
        shape: const StadiumBorder(),
        width: 520,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        headerBackgroundColor: AppColors.magenta,
        headerForegroundColor: Colors.white,
        rangeSelectionBackgroundColor: AppColors.magentaSoft,
        todayBorder: const BorderSide(color: AppColors.magenta),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintStyle: AppText.body(13.5, color: AppColors.faint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(999), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.magenta, width: 1.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.magenta : null),
      ),
    );
  }
}
