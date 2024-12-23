// Define two themes
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// color scheme
const Color primaryColor = Colors.blue;
const Color accentColor = Colors.blueAccent;
const Color textColor = Colors.black;
const Color backgroundColor = Colors.white;

ThemeData themeDefault = ThemeData(
  // General Colors
  brightness: Brightness.light,
  primaryColor: primaryColor,
  scaffoldBackgroundColor: backgroundColor,

  // appbar theme
  appBarTheme: AppBarTheme(
    backgroundColor: accentColor,
    foregroundColor: backgroundColor,
    titleTextStyle: GoogleFonts.pacifico(
      textStyle: TextStyle(
        color: backgroundColor,
        fontSize: 30.0,
      ),
    ),
    elevation: 10, // Increase elevation for a more pronounced shadow
    toolbarHeight: 50.0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(20.0), // Make both top and bottom rounded
      ),
    ),
    shadowColor: Colors.black.withOpacity(0.5), // Add shadow color
    iconTheme: IconThemeData(
      color: backgroundColor, // Set leading icon color
    ),
    actionsIconTheme: IconThemeData(
      color: backgroundColor, // Set action icons color
    ),
  ),

  // Text Styles
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: textColor, fontSize: 18.0),
    bodyMedium: TextStyle(color: textColor, fontSize: 14.0),
    bodySmall: TextStyle(color: textColor, fontSize: 12.0),
    headlineLarge: GoogleFonts.mogra(
      color: accentColor,
      fontSize: 24.0,
    ),
    headlineMedium: GoogleFonts.delius(
      color: primaryColor,
      fontSize: 18.0,
      fontWeight: FontWeight.bold,
    ),
    headlineSmall: GoogleFonts.lexend(
      color: textColor,
      fontSize: 14.0,
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
      side: BorderSide(color: accentColor, width: 2.0),
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
      borderSide: BorderSide(color: accentColor, width: 1.5),
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
    labelStyle: TextStyle(color: accentColor),
    hintStyle: TextStyle(color: Colors.grey),
  ),

  // Cards
  cardTheme: CardTheme(
    color: backgroundColor,
    shadowColor: Colors.grey.withOpacity(0.5),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
      side: BorderSide(color: accentColor, width: 1.0),
    ),
  ),

  // Floating Action Button
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: accentColor,
    foregroundColor: backgroundColor,
    shape: CircleBorder(),
  ),

  // Popup Menu Theme
  popupMenuTheme: PopupMenuThemeData(
    color: backgroundColor,
    textStyle: TextStyle(
      color: textColor,
      fontSize: 16.0,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
      side: BorderSide(color: accentColor, width: 1.0),
    ),
  ),

  // Icon Theme
  iconTheme: IconThemeData(
    color: accentColor,
    size: 24.0,
  ),

  // Icon Button Theme
  iconButtonTheme: IconButtonThemeData(
    style: ButtonStyle(
      iconColor: WidgetStateProperty.all(accentColor),
      iconSize: WidgetStateProperty.all(24.0),
    ),
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
