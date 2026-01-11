import 'package:flutter/material.dart';

class CustomBottomNavigationBarTheme {
  CustomBottomNavigationBarTheme._();

  static BottomNavigationBarThemeData getTheme(ColorScheme colorScheme) {
    return BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    );
  }
}
