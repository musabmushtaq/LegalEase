import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color background = Color(0xFF131313);
  static const Color highlight = Color(0xFFFCE566);
  static const Color textBody = Color(0xFFF7F1FF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: highlight,
        secondary: highlight,
        surface: background,
        onSurface: textBody,
        onPrimary: background,
      ),
      fontFamily: GoogleFonts.lexend().fontFamily,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.lexend(
          textStyle: const TextStyle(
            color: highlight,
            fontWeight: FontWeight.bold,
          ),
        ),
        displayMedium: GoogleFonts.lexend(
          textStyle: const TextStyle(
            color: highlight,
            fontWeight: FontWeight.bold,
          ),
        ),
        bodyLarge: GoogleFonts.lexend(
          textStyle: const TextStyle(color: textBody, fontSize: 16),
        ),
        bodyMedium: GoogleFonts.lexend(
          textStyle: const TextStyle(color: textBody, fontSize: 14),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}
