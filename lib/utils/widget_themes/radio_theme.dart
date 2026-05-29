import 'package:flutter/material.dart';

class CustomRadioTheme {
  CustomRadioTheme._();

  static RadioThemeData getTheme(ColorScheme colorScheme) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.onSurface.withOpacity(0.54);
      }),
    );
  }
}
