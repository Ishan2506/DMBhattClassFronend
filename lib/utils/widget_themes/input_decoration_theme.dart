import 'package:dm_bhatt_tutions/utils/app_sizes.dart';
import 'package:flutter/material.dart';

class CustomInputDecorationTheme {
  static InputDecorationThemeData getTheme(ColorScheme colorScheme) {
    return InputDecorationThemeData(
      contentPadding: P.all16,
      prefixIconColor: colorScheme.primary,
      suffixIconColor: colorScheme.onSurfaceVariant,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(S.s12),
        borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(S.s12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(S.s12),
        borderSide: BorderSide(color: colorScheme.error, width: 1),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(S.s12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
    );
  }
}
