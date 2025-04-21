import 'package:flutter/material.dart';

// imagine a card with a text field and a button
// primary color (dark): all text
// secondary color (dark): AppBar background
// scaffoldBackgroundColor (light): page background
// secondaryBackgroundColor (light): card background
ThemeData createTheme({
  required Color primaryColor,
  required Color secondaryColor,
}) {
  return ThemeData(
    // General Colors
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.grey[50],
    colorScheme: ColorScheme.light(
      primary: Colors.black,
      secondary: Colors.black,
      surface: secondaryColor,
      onPrimary: secondaryColor,
      onSecondary: secondaryColor,
      onSurface: Colors.black,
    ),

    // appbar theme
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: secondaryColor,
      iconTheme: IconThemeData(color: secondaryColor, size: 32.0),
      elevation: 2.0,
      shadowColor: primaryColor,
    ),

    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Colors.grey),
      floatingLabelStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Floating Action Button
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
    ),

    // icon Theme
    iconTheme: IconThemeData(color: primaryColor, size: 24.0),

    // Checkboxes, Radios, Switches
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.all(Colors.transparent),
      checkColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected)
                ? primaryColor
                : Colors.transparent,
      ),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color:
              states.contains(WidgetState.selected)
                  ? primaryColor
                  : Colors.grey,
        ),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected)
                ? primaryColor
                : Colors.transparent,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(primaryColor),
      trackColor: WidgetStateProperty.all(primaryColor.withOpacity(0.5)),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: secondaryColor,
        backgroundColor: primaryColor,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: primaryColor, width: 2.0),
        foregroundColor: primaryColor,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: TextStyle(
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
  );
}
