import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme get textTheme {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 34 / 28,
        letterSpacing: -0.02 * 28,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 30 / 24,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        letterSpacing: -0.01 * 20,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 20 / 15,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 18 / 13,
        letterSpacing: 0.01 * 13,
      ),
    );
  }
}
