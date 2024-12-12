// Define two themes
import 'package:flutter/material.dart';

// color scheme
const Color primaryColor = Colors.blue;
const Color outlineColor = Colors.blueAccent;
const Color textColor = Colors.black;
const Color backgroundColor = Colors.white;

ThemeData themeDefault = ThemeData(
  // General Colors
  brightness: Brightness.light,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: backgroundColor,

  // appbar theme
  appBarTheme: AppBarTheme(
    backgroundColor: backgroundColor,
    foregroundColor: outlineColor,
    titleTextStyle: TextStyle(
      color: outlineColor,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
    centerTitle: true,
    elevation: 0,
    toolbarHeight: 70.0,
    shape: Border(
      top: BorderSide(
        color: outlineColor,
        width: 4.0,
      ),
      bottom: BorderSide(
        color: outlineColor,
        width: 4.0,
      ),
    ),
  ),

  // Text Styles
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: textColor, fontSize: 16.0),
    bodyMedium: TextStyle(color: textColor, fontSize: 14.0),
    bodySmall: TextStyle(color: textColor, fontSize: 12.0),
    headlineLarge: TextStyle(
      color: textColor,
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
    ),
    headlineMedium: TextStyle(
      color: textColor,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    ),
  ),

  // Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: backgroundColor,
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16.0,
      ),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: outlineColor, width: 2.0),
      textStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 16.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: primaryColor,
      textStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16.0,
      ),
    ),
  ),

  // Input Fields
  inputDecorationTheme: InputDecorationTheme(
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: outlineColor, width: 1.5),
      borderRadius: BorderRadius.circular(8.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: primaryColor, width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 1.5),
      borderRadius: BorderRadius.circular(8.0),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    ),
    labelStyle: TextStyle(color: outlineColor),
    hintStyle: TextStyle(color: Colors.grey),
  ),

  // Cards
  cardTheme: CardTheme(
    color: backgroundColor,
    shadowColor: Colors.grey.withOpacity(0.5),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
      side: BorderSide(color: outlineColor, width: 1.0),
    ),
  ),

  // Floating Action Button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: backgroundColor,
    foregroundColor: primaryColor,
    shape: CircleBorder(
      side: BorderSide(color: primaryColor, width: 2.0),
    ),
  ),

  // Icon Theme
  iconTheme: IconThemeData(
    color: primaryColor,
    size: 24.0,
  ),

  // Checkboxes, Radios, Switches
  checkboxTheme: CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? primaryColor : Colors.grey),
  ),
  radioTheme: RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) =>
        states.contains(WidgetState.selected) ? primaryColor : Colors.grey),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.all(primaryColor),
    trackColor: WidgetStateProperty.all(primaryColor.withOpacity(0.5)),
  ),
);
