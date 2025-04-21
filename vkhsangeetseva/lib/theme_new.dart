import 'package:flutter/material.dart';

// imagine a card with a text field and a button
// primary color (dark): all text
// secondary color (dark): AppBar background
// scaffoldBackgroundColor (light): page background
// secondaryBackgroundColor (light): card background
ThemeData createTheme({
  required Color primaryColor,
  required Color secondaryColor,
  required Color scaffoldBackgroundColor,
  required Color secondaryBackgroundColor,
}) {
  return ThemeData(
    // General Colors
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: Colors.black,
      surface: secondaryBackgroundColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: primaryColor,
    ),

    // appbar theme
    appBarTheme: AppBarTheme(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white, size: 32.0),
      elevation: 2.0,
      shadowColor: primaryColor,
    ),

    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.grey),
      floatingLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryColor,
    ),

    // AppBar icon Theme
    iconTheme: IconThemeData(color: secondaryColor, size: 24.0),

    // Checkboxes, Radios, Switches
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.all(Colors.transparent),
      checkColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? secondaryColor
            : Colors.transparent,
      ),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? secondaryColor
              : Colors.grey,
        ),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? secondaryColor
            : Colors.transparent,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(secondaryColor),
      trackColor: WidgetStateProperty.all(secondaryColor.withOpacity(0.5)),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: secondaryColor,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: secondaryColor, width: 2.0),
        foregroundColor: secondaryColor,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryColor,
        textStyle: TextStyle(
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
  );
}
