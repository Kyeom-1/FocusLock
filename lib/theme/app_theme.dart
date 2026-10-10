import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FocusLock's palette: a dim instrument panel with one warm signal color
/// standing in for the indicator lamp that lights up while a session is
/// locked in. Deliberately small — one accent, used everywhere it means
/// "focus is active" or "this is the primary action".
class AppColors {
  AppColors._();

  static const graphite = Color(0xFF15161B); // app background
  static const panel = Color(0xFF1D1F26); // cards / surfaces
  static const hairline = Color(0xFF2A2D36); // borders, dividers, ticks
  static const signal = Color(0xFFE8A33D); // primary accent — the lamp
  static const signalDim = Color(0xFF6B5327); // signal at rest / medium state
  static const paper = Color(0xFFF2EFE9); // primary text
  static const ash = Color(0xFF8D8F99); // secondary text
  static const alert = Color(0xFFE2604F); // errors, destructive actions
}

/// Two families doing clearly different jobs: Big Shoulders Display is the
/// condensed, stamped-metal face used for headings, the wordmark, and the
/// focus countdown; IBM Plex Sans carries everything you actually read.
TextTheme _buildTextTheme() {
  final display = GoogleFonts.bigShouldersDisplayTextTheme();
  final body = GoogleFonts.ibmPlexSansTextTheme();

  return TextTheme(
    displayLarge: display.displayLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.paper,
      height: 1.0,
    ),
    displayMedium: display.displayMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.paper,
      height: 1.0,
    ),
    headlineLarge: display.headlineLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.paper,
      fontSize: 32,
    ),
    headlineMedium: display.headlineMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.paper,
      fontSize: 26,
    ),
    headlineSmall: display.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.paper,
      fontSize: 21,
    ),
    titleLarge: body.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.paper,
      fontSize: 18,
    ),
    titleMedium: body.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.paper,
      fontSize: 16,
    ),
    bodyLarge: body.bodyLarge?.copyWith(color: AppColors.paper, fontSize: 16, height: 1.4),
    bodyMedium: body.bodyMedium?.copyWith(color: AppColors.ash, fontSize: 14, height: 1.4),
    bodySmall: body.bodySmall?.copyWith(color: AppColors.ash, fontSize: 12.5, height: 1.3),
    labelLarge: body.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.paper,
      fontSize: 14,
    ),
    labelMedium: body.labelMedium?.copyWith(color: AppColors.ash, fontSize: 12.5),
    labelSmall: body.labelSmall?.copyWith(color: AppColors.ash, fontSize: 11.5),
  );
}

ThemeData buildAppTheme() {
  final textTheme = _buildTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.graphite,
    fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
    textTheme: textTheme,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.panel,
      primary: AppColors.signal,
      onPrimary: AppColors.graphite,
      secondary: AppColors.signal,
      onSurface: AppColors.paper,
      error: AppColors.alert,
    ),
    dividerColor: AppColors.hairline,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.graphite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: AppColors.paper,
      titleTextStyle: textTheme.headlineSmall,
      iconTheme: const IconThemeData(color: AppColors.paper),
    ),
    cardTheme: CardThemeData(
      color: AppColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.hairline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium,
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.signal, width: 2),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.alert),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.alert, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.signal,
        foregroundColor: AppColors.graphite,
        disabledBackgroundColor: AppColors.hairline,
        disabledForegroundColor: AppColors.ash,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.paper,
        side: const BorderSide(color: AppColors.hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.signal,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconTheme: const IconThemeData(color: AppColors.paper),
    dividerTheme: const DividerThemeData(color: AppColors.hairline, thickness: 1, space: 1),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.signal,
      foregroundColor: AppColors.graphite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.signal,
      linearTrackColor: AppColors.hairline,
      circularTrackColor: AppColors.hairline,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.panel,
      contentTextStyle: textTheme.bodyLarge,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.hairline),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.paper,
      textColor: AppColors.paper,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: AppColors.hairline),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyLarge,
    ),
  );
}
