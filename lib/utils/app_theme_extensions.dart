
import 'package:dm_bhatt_tutions/utils/app_theme.dart';
import 'package:dm_bhatt_tutions/utils/widget_themes/app_bar_theme.dart';
import 'package:dm_bhatt_tutions/utils/widget_themes/bottom_navigation_bar_theme.dart';
import 'package:dm_bhatt_tutions/utils/widget_themes/elevated_button_theme.dart';
import 'package:dm_bhatt_tutions/utils/widget_themes/input_decoration_theme.dart';
import 'package:dm_bhatt_tutions/utils/widget_themes/outlined_button_theme.dart';
import 'package:dm_bhatt_tutions/utils/widget_themes/radio_theme.dart';
import 'package:flutter/material.dart';

extension AppThemeSchemes on MaterialTheme {
  
  // Method to get ThemeData based on style
  ThemeData getThemeForStyle(String styleName, bool isDark) {
      ColorScheme scheme;
      switch (styleName) {
        case 'ocean':
          scheme = isDark ? _oceanDark() : _oceanLight();
          break;
        case 'sunset':
          scheme = isDark ? _sunsetDark() : _sunsetLight();
          break;
        case 'forest':
           scheme = isDark ? _forestDark() : _forestLight();
           break;
        case 'lavender':
           scheme = isDark ? _lavenderDark() : _lavenderLight();
           break;
        case 'midnight':
           scheme = isDark ? _midnightDark() : _midnightLight();
           break;
        default:
          scheme = isDark ? MaterialTheme.darkScheme() : MaterialTheme.lightScheme();
      }
      
      return theme(scheme);
  }

  // --- Ocean Scheme (Teal/Aqua) ---
  ColorScheme _oceanLight() => const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF006D77),
      onPrimary: Colors.white,
      secondary: Color(0xFF83C5BE),
      onSecondary: Colors.black,
      surface: Color(0xFFEDF6F9),
      onSurface: Color(0xFF006D77),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      primaryContainer: Color(0xFF83C5BE),

      // Fill remaining with defaults or approximations
      onPrimaryContainer: Color(0xFF00373D),
      secondaryContainer: Color(0xFFD0F4F0),
      onSecondaryContainer: Color(0xFF00201D),
      tertiary: Color(0xFFE29578),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFFDBCF),
      onTertiaryContainer: Color(0xFF3B0B00),
      background: Color(0xFFEDF6F9),
      onBackground: Color(0xFF006D77),
      surfaceVariant: Color(0xFFDBE4E6),
      onSurfaceVariant: Color(0xFF3F484A),
      outline: Color(0xFF6F797A),
  ).copyWith(surface: const Color(0xFFEDF6F9)); // Ensure surface is set

  ColorScheme _oceanDark() => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF83C5BE),
      onPrimary: Color(0xFF00373D),
      secondary: Color(0xFF006D77),
      onSecondary: Colors.white,
      surface: Color(0xFF191C1C),
      onSurface: Color(0xFFE1E3E3),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      background: Color(0xFF191C1C),
      onBackground: Color(0xFFE1E3E3),
  ).copyWith(surface: const Color(0xFF191C1C));

  // --- Sunset Scheme (Orange/Purple) ---
   ColorScheme _sunsetLight() => const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF9E4784), // Purple
      onPrimary: Colors.white,
      secondary: Color(0xFFFF8B13), // Orange
      onSecondary: Colors.black,
      surface: Color(0xFFFFF5E4),
      onSurface: Color(0xFF422343),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      background: Color(0xFFFFF5E4),
      onBackground: Color(0xFF422343),
  ).copyWith(surface: const Color(0xFFFFF5E4));

  ColorScheme _sunsetDark() => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFD27685),
      onPrimary: Color(0xFF5D1136),
      secondary: Color(0xFFFFB84D),
      onSecondary: Color(0xFF4A2800),
      surface: Color(0xFF1F1A1D),
      onSurface: Color(0xFFEAE0E3),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
       background: Color(0xFF1F1A1D),
      onBackground: Color(0xFFEAE0E3),
  ).copyWith(surface: const Color(0xFF1F1A1D));

   // --- Forest Scheme (Green/Brown) ---
   ColorScheme _forestLight() => const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF2E7d32),
      onPrimary: Colors.white,
      secondary: Color(0xFF795548),
      onSecondary: Colors.white,
      surface: Color(0xFFE8F5E9),
      onSurface: Color(0xFF1B5E20),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
       background: Color(0xFFE8F5E9),
      onBackground: Color(0xFF1B5E20),
  ).copyWith(surface: const Color(0xFFE8F5E9));

  ColorScheme _forestDark() => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFA5D6A7),
      onPrimary: Color(0xFF00390B),
      secondary: Color(0xFFA1887F),
      onSecondary: Color(0xFF2D160C),
      surface: Color(0xFF1A1C1A),
      onSurface: Color(0xFFE2E3DE),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
       background: Color(0xFF1A1C1A),
      onBackground: Color(0xFFE2E3DE),
  ).copyWith(surface: const Color(0xFF1A1C1A));

   // --- Lavender Scheme (Purple/Soft Pink) ---
   ColorScheme _lavenderLight() => const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF6750A4),
      onPrimary: Colors.white,
      secondary: Color(0xFF958DA5),
      onSecondary: Colors.white,
      surface: Color(0xFFF3EDF7),
      onSurface: Color(0xFF1D1B20),
      error: Color(0xFFB3261E),
      onError: Colors.white,
       background: Color(0xFFF3EDF7),
      onBackground: Color(0xFF1D1B20),
  ).copyWith(surface: const Color(0xFFF3EDF7));

  ColorScheme _lavenderDark() => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFD0BCFF),
      onPrimary: Color(0xFF381E72),
      secondary: Color(0xFFCBC2DB),
      onSecondary: Color(0xFF332D41),
      surface: Color(0xFF141218),
      onSurface: Color(0xFFE6E1E5),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
       background: Color(0xFF141218),
      onBackground: Color(0xFFE6E1E5),
  ).copyWith(surface: const Color(0xFF141218));

  // --- Midnight Scheme (Deep Blue/Gold) ---
   ColorScheme _midnightLight() => const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF1A237E), // Deep Blue
      onPrimary: Colors.white,
      secondary: Color(0xFFFFD700), // Gold
      onSecondary: Colors.black,
      surface: Color(0xFFE8EAF6),
      onSurface: Color(0xFF1A237E),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
       background: Color(0xFFE8EAF6),
      onBackground: Color(0xFF1A237E),
  ).copyWith(surface: const Color(0xFFE8EAF6));

  ColorScheme _midnightDark() => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF536DFE),
      onPrimary: Color(0xFF000F5D),
      secondary: Color(0xFFFFD700),
      onSecondary: Color(0xFF3F3600),
      surface: Color(0xFF0D101E),
      onSurface: Color(0xFFE0E2EC),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
       background: Color(0xFF0D101E),
      onBackground: Color(0xFFE0E2EC),
  ).copyWith(surface: const Color(0xFF0D101E));

}
