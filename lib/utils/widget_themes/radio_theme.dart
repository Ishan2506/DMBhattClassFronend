import 'package:flutter/material.dart';

class CustomRadioTheme {
  CustomRadioTheme._();

  static RadioThemeData getTheme(ColorScheme colorScheme) {
    return RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.onSurface.withOpacity(0.54);
      }),
    );
  }
}
