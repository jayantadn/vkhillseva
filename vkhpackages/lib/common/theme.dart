import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vkhpackages/common/themeGaruda.dart';

// imagine a card with a text field and a button
// primary color (dark): all text
// secondary color (dark): AppBar background
// scaffoldBackgroundColor (light): page background
// secondaryBackgroundColor (light): card background

class ThemeCreator {
  Color primaryColor;
  Color secondaryColor = Colors.white;
  Color textColor = Colors.black;

  ThemeCreator({required this.primaryColor});

  ThemeData create() {
    return ThemeData(
      // General Colors
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.grey[100],
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: secondaryColor,
        onPrimary: secondaryColor,
        onSecondary: secondaryColor,
        onSurface: Colors.black,
      ),

      // Text Styles
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 18.0),
        bodyMedium: TextStyle(fontSize: 14.0),
        bodySmall: TextStyle(fontSize: 12.0),
        headlineLarge: GoogleFonts.lexend(color: textColor, fontSize: 24.0),
        headlineMedium: GoogleFonts.lexend(
          color: textColor,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: GoogleFonts.lexend(
          color: textColor,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
      ),

      // appbar theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
        iconTheme: IconThemeData(color: secondaryColor, size: 32.0),
        elevation: 2.0,
        shadowColor: primaryColor,
      ),

      // list tile theme
      listTileTheme: ListTileThemeData(
        titleTextStyle: GoogleFonts.lexend(
          color: textColor,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
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
}
