import 'package:flutter/material.dart';

class CustomRadioTheme {
  CustomRadioTheme._();

  static RadioThemeData getTheme(ColorScheme colorScheme) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.onSurface.withValues(alpha: 0.54);
      }),
    );
  }
}
