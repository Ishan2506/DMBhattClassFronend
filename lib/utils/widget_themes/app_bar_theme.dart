import 'package:flutter/material.dart';

class CustomAppBarTheme {
  static AppBarTheme getTheme(ColorScheme colorScheme,TextTheme textTheme) {
    return AppBarTheme(
      centerTitle: true,
      elevation: 2,
      scrolledUnderElevation: 3.0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
      // titleTextStyle: textTheme.headlineSmall
    );
  }
}