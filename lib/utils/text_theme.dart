import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextTheme createTextTheme() {
  return TextTheme(
    // --- DISPLAY: Used for large hero text and branding ---
    displayLarge: GoogleFonts.roboto(
        fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25),
    displayMedium: GoogleFonts.roboto(
        fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0),
    displaySmall: GoogleFonts.roboto(
        fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0),

    // --- HEADLINE: Used for section headers or high-emphasis text ---
    headlineLarge: GoogleFonts.roboto(
        fontSize: 32, fontWeight: FontWeight.w400, letterSpacing: 0),
    headlineMedium: GoogleFonts.roboto(
        fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 0),
    headlineSmall: GoogleFonts.roboto(
        fontSize: 24, fontWeight: FontWeight.w400, letterSpacing: 0),

    // --- TITLE: Used for App Bars, dialog titles, and list headers ---
    titleLarge: GoogleFonts.roboto(
        fontSize: 22, fontWeight: FontWeight.w500, letterSpacing: 0),
    titleMedium: GoogleFonts.roboto(
        fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15),
    titleSmall: GoogleFonts.roboto(
        fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),

    // --- BODY: Used for long-form content, descriptions, and inputs ---
    bodyLarge: GoogleFonts.roboto(
        fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
    bodyMedium: GoogleFonts.roboto(
        fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
    bodySmall: GoogleFonts.roboto(
        fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),

    // --- LABEL: Used for buttons, captions, and small annotations ---
    labelLarge: GoogleFonts.roboto(
        fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.1),
    labelMedium: GoogleFonts.roboto(
        fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    labelSmall: GoogleFonts.roboto(
        fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );
}