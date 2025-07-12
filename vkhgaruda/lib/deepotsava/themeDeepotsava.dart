// dummy values for deepotsava
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final Color primaryColor = Colors.blue;
final Color primaryColorRRG = Color(0xFFB71C1C);
final Color variantColorRRG = Color(0xFFD32F2F);
final Color textColorRRG = Colors.white;
final Color primaryColorRKC = Color(0xFF0D47A1);
final Color variantColorRKC = Color(0xFF1976D2);
final Color textColorRKC = Colors.white;
final Color primaryColorDefault = Color(0xFF2196F3);
final Color variantColorDefault = Color(0xFF42A5F5);
final Color textColorDefault = Colors.white;

final ThemeData themeDefault = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColorDefault,
  scaffoldBackgroundColor: Colors.grey[100],
  colorScheme: ColorScheme.light(
    primary: primaryColorDefault,
    secondary: variantColorDefault,
    surface: variantColorDefault,
    onPrimary: textColorDefault,
    onSecondary: textColorDefault,
    onSurface: Colors.black,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(fontSize: 18.0),
    bodyMedium: TextStyle(fontSize: 14.0),
    bodySmall: TextStyle(fontSize: 12.0),
    headlineLarge: GoogleFonts.lexend(color: textColorDefault, fontSize: 24.0),
    headlineMedium: GoogleFonts.lexend(
      color: textColorDefault,
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: GoogleFonts.lexend(
      color: textColorDefault,
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColorDefault,
    foregroundColor: textColorDefault,
    iconTheme: IconThemeData(color: textColorDefault, size: 32.0),
    elevation: 2.0,
    shadowColor: primaryColorDefault,
  ),
  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
    titleTextStyle: GoogleFonts.lexend(
      color: textColorDefault,
      fontWeight: FontWeight.bold,
    ),
    dense: true,
    minVerticalPadding: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    hintStyle: TextStyle(color: Colors.grey),
    floatingLabelStyle: TextStyle(
      color: primaryColorDefault,
      fontWeight: FontWeight.bold,
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: primaryColorDefault,
  ),
  iconTheme: IconThemeData(color: primaryColorDefault, size: 24.0),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all(Colors.transparent),
    checkColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? primaryColorDefault
          : Colors.transparent,
    ),
    side: WidgetStateBorderSide.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.selected)
            ? primaryColorDefault
            : Colors.grey,
      ),
    ),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? primaryColorDefault
          : Colors.transparent,
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.all(primaryColorDefault),
    trackColor: WidgetStateProperty.all(primaryColorDefault.withOpacity(0.5)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: textColorDefault,
      backgroundColor: primaryColorDefault,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: primaryColorDefault, width: 2.0),
      foregroundColor: primaryColorDefault,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColorDefault,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
    ),
  ),
);

final ThemeData themeRRG = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColorRRG,
  scaffoldBackgroundColor: Colors.grey[100],
  colorScheme: ColorScheme.light(
    primary: primaryColorRRG,
    secondary: variantColorRRG,
    surface: variantColorRRG,
    onPrimary: textColorRRG,
    onSecondary: textColorRRG,
    onSurface: Colors.black,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(fontSize: 18.0),
    bodyMedium: TextStyle(fontSize: 14.0),
    bodySmall: TextStyle(fontSize: 12.0),
    headlineLarge: GoogleFonts.lexend(color: textColorRRG, fontSize: 24.0),
    headlineMedium: GoogleFonts.lexend(
      color: textColorRRG,
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: GoogleFonts.lexend(
      color: textColorRRG,
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColorRRG,
    foregroundColor: textColorRRG,
    iconTheme: IconThemeData(color: textColorRRG, size: 32.0),
    elevation: 2.0,
    shadowColor: primaryColorRRG,
  ),
  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
    titleTextStyle: GoogleFonts.lexend(
      color: textColorRRG,
      fontWeight: FontWeight.bold,
    ),
    dense: true,
    minVerticalPadding: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    hintStyle: TextStyle(color: Colors.grey),
    floatingLabelStyle: TextStyle(
      color: primaryColorRRG,
      fontWeight: FontWeight.bold,
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: primaryColorRRG,
  ),
  iconTheme: IconThemeData(color: primaryColorRRG, size: 24.0),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all(Colors.transparent),
    checkColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? primaryColorRRG
          : Colors.transparent,
    ),
    side: WidgetStateBorderSide.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.selected)
            ? primaryColorRRG
            : Colors.grey,
      ),
    ),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? primaryColorRRG
          : Colors.transparent,
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.all(primaryColorRRG),
    trackColor: WidgetStateProperty.all(primaryColorRRG.withOpacity(0.5)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: textColorRRG,
      backgroundColor: primaryColorRRG,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: primaryColorRRG, width: 2.0),
      foregroundColor: primaryColorRRG,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColorRRG,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
    ),
  ),
);

final ThemeData themeRKC = ThemeData(
  brightness: Brightness.light,
  primaryColor: primaryColorRKC,
  scaffoldBackgroundColor: Colors.grey[100],
  colorScheme: ColorScheme.light(
    primary: primaryColorRKC,
    secondary: variantColorRKC,
    surface: variantColorRKC,
    onPrimary: textColorRKC,
    onSecondary: textColorRKC,
    onSurface: Colors.black,
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(fontSize: 18.0),
    bodyMedium: TextStyle(fontSize: 14.0),
    bodySmall: TextStyle(fontSize: 12.0),
    headlineLarge: GoogleFonts.lexend(color: textColorRKC, fontSize: 24.0),
    headlineMedium: GoogleFonts.lexend(
      color: textColorRKC,
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: GoogleFonts.lexend(
      color: textColorRKC,
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColorRKC,
    foregroundColor: textColorRKC,
    iconTheme: IconThemeData(color: textColorRKC, size: 32.0),
    elevation: 2.0,
    shadowColor: primaryColorRKC,
  ),
  listTileTheme: ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
    titleTextStyle: GoogleFonts.lexend(
      color: textColorRKC,
      fontWeight: FontWeight.bold,
    ),
    dense: true,
    minVerticalPadding: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    hintStyle: TextStyle(color: Colors.grey),
    floatingLabelStyle: TextStyle(
      color: primaryColorRKC,
      fontWeight: FontWeight.bold,
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: primaryColorRKC,
  ),
  iconTheme: IconThemeData(color: primaryColorRKC, size: 24.0),
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.all(Colors.transparent),
    checkColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? primaryColorRKC
          : Colors.transparent,
    ),
    side: WidgetStateBorderSide.resolveWith(
      (states) => BorderSide(
        color: states.contains(WidgetState.selected)
            ? primaryColorRKC
            : Colors.grey,
      ),
    ),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? primaryColorRKC
          : Colors.transparent,
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.all(primaryColorRKC),
    trackColor: WidgetStateProperty.all(primaryColorRKC.withOpacity(0.5)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: textColorRKC,
      backgroundColor: primaryColorRKC,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: primaryColorRKC, width: 2.0),
      foregroundColor: primaryColorRKC,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColorRKC,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.underline,
      ),
    ),
  ),
);
