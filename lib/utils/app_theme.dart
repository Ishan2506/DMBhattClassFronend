import "package:dm_bhatt_tutions/utils/widget_themes/app_bar_theme.dart";
import "package:dm_bhatt_tutions/utils/widget_themes/bottom_navigation_bar_theme.dart";
import "package:dm_bhatt_tutions/utils/widget_themes/elevated_button_theme.dart";
import "package:dm_bhatt_tutions/utils/widget_themes/input_decoration_theme.dart";
import "package:dm_bhatt_tutions/utils/widget_themes/outlined_button_theme.dart";
import "package:dm_bhatt_tutions/utils/widget_themes/radio_theme.dart";
import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF0D47A1), // Colors.blue.shade900
      surfaceTint: Color(0xFF0D47A1),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffd8e2ff),
      onPrimaryContainer: Color(0xff2b4678),
      secondary: Color(0xff226a4c),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffaaf2cc),
      onSecondaryContainer: Color(0xff005236),
      tertiary: Color(0xff256489),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffc9e6ff),
      onTertiaryContainer: Color(0xff004c6e),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff7f9fe),
      onSurface: Color(0xff181c20),
      onSurfaceVariant: Color(0xff43474e),
      outline: Color(0xff74777f),
      outlineVariant: Color(0xffc4c6cf),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d3135),
      inversePrimary: Color(0xffadc6ff),
      primaryFixed: Color(0xffd8e2ff),
      onPrimaryFixed: Color(0xff001a42),
      primaryFixedDim: Color(0xffadc6ff),
      onPrimaryFixedVariant: Color(0xff2b4678),
      secondaryFixed: Color(0xffaaf2cc),
      onSecondaryFixed: Color(0xff002113),
      secondaryFixedDim: Color(0xff8ed5b0),
      onSecondaryFixedVariant: Color(0xff005236),
      tertiaryFixed: Color(0xffc9e6ff),
      onTertiaryFixed: Color(0xff001e2f),
      tertiaryFixedDim: Color(0xff94cdf7),
      onTertiaryFixedVariant: Color(0xff004c6e),
      surfaceDim: Color(0xffd7dadf),
      surfaceBright: Color(0xfff7f9fe),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff1f4f9),
      surfaceContainer: Color(0xffebeef3),
      surfaceContainerHigh: Color(0xffe5e8ed),
      surfaceContainerHighest: Color(0xffe0e3e8),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff445e91),
      surfaceTint: Color(0xff445e91),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffd8e2ff),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff003f29),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff337a5a),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff003a56),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff377398),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff7f9fe),
      onSurface: Color(0xff0d1215),
      onSurfaceVariant: Color(0xff33363d),
      outline: Color(0xff4f525a),
      outlineVariant: Color(0xff6a6d75),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d3135),
      inversePrimary: Color(0xffadc6ff),
      primaryFixed: Color(0xff536da1),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff3a5487),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff337a5a),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff156043),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff377398),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff175a7e),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc3c7cc),
      surfaceBright: Color(0xfff7f9fe),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff1f4f9),
      surfaceContainer: Color(0xffe5e8ed),
      surfaceContainerHigh: Color(0xffdadde2),
      surfaceContainerHighest: Color(0xffcfd2d7),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff0a2b5b),
      surfaceTint: Color(0xff445e91),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff2e487a),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff003421),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff005438),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff002f47),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff004e71),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff7f9fe),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff292c33),
      outlineVariant: Color(0xff464951),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2d3135),
      inversePrimary: Color(0xffadc6ff),
      primaryFixed: Color(0xff2e487a),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff143162),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff005438),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff003b26),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff004e71),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff003650),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb6b9be),
      surfaceBright: Color(0xfff7f9fe),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xffeef1f6),
      surfaceContainer: Color(0xffe0e3e8),
      surfaceContainerHigh: Color(0xffd1d5d9),
      surfaceContainerHighest: Color(0xffc3c7cc),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffadc6ff),
      surfaceTint: Color(0xffadc6ff),
      onPrimary: Color(0xff112f60),
      primaryContainer: Color(0xff2b4678),
      onPrimaryContainer: Color(0xffd8e2ff),
      secondary: Color(0xff8ed5b0),
      onSecondary: Color(0xff003824),
      secondaryContainer: Color(0xff005236),
      onSecondaryContainer: Color(0xffaaf2cc),
      tertiary: Color(0xff94cdf7),
      onTertiary: Color(0xff00344d),
      tertiaryContainer: Color(0xff004c6e),
      onTertiaryContainer: Color(0xffc9e6ff),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff101417),
      onSurface: Color(0xffe0e3e8),
      onSurfaceVariant: Color(0xffc4c6cf),
      outline: Color(0xff8e9199),
      outlineVariant: Color(0xff43474e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e3e8),
      inversePrimary: Color(0xff445e91),
      primaryFixed: Color(0xffd8e2ff),
      onPrimaryFixed: Color(0xff001a42),
      primaryFixedDim: Color(0xffadc6ff),
      onPrimaryFixedVariant: Color(0xff2b4678),
      secondaryFixed: Color(0xffaaf2cc),
      onSecondaryFixed: Color(0xff002113),
      secondaryFixedDim: Color(0xff8ed5b0),
      onSecondaryFixedVariant: Color(0xff005236),
      tertiaryFixed: Color(0xffc9e6ff),
      onTertiaryFixed: Color(0xff001e2f),
      tertiaryFixedDim: Color(0xff94cdf7),
      onTertiaryFixedVariant: Color(0xff004c6e),
      surfaceDim: Color(0xff101417),
      surfaceBright: Color(0xff353a3e),
      surfaceContainerLowest: Color(0xff0a0f12),
      surfaceContainerLow: Color(0xff181c20),
      surfaceContainer: Color(0xff1c2024),
      surfaceContainerHigh: Color(0xff262a2e),
      surfaceContainerHighest: Color(0xff313539),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffcfdcff),
      surfaceTint: Color(0xffadc6ff),
      onPrimary: Color(0xff012454),
      primaryContainer: Color(0xff7790c7),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffa4ecc6),
      onSecondary: Color(0xff002c1c),
      secondaryContainer: Color(0xff599e7d),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffbce1ff),
      onTertiary: Color(0xff00293d),
      tertiaryContainer: Color(0xff5e97be),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff101417),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffdadce5),
      outline: Color(0xffafb2bb),
      outlineVariant: Color(0xff8d9099),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e3e8),
      inversePrimary: Color(0xff2d4779),
      primaryFixed: Color(0xffd8e2ff),
      onPrimaryFixed: Color(0xff00102e),
      primaryFixedDim: Color(0xffadc6ff),
      onPrimaryFixedVariant: Color(0xff183566),
      secondaryFixed: Color(0xffaaf2cc),
      onSecondaryFixed: Color(0xff00150b),
      secondaryFixedDim: Color(0xff8ed5b0),
      onSecondaryFixedVariant: Color(0xff003f29),
      tertiaryFixed: Color(0xffc9e6ff),
      onTertiaryFixed: Color(0xff00131f),
      tertiaryFixedDim: Color(0xff94cdf7),
      onTertiaryFixedVariant: Color(0xff003a56),
      surfaceDim: Color(0xff101417),
      surfaceBright: Color(0xff414549),
      surfaceContainerLowest: Color(0xff05080b),
      surfaceContainerLow: Color(0xff1a1e22),
      surfaceContainer: Color(0xff24282c),
      surfaceContainerHigh: Color(0xff2f3337),
      surfaceContainerHighest: Color(0xff3a3e42),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffecefff),
      surfaceTint: Color(0xffadc6ff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffa9c2fc),
      onPrimaryContainer: Color(0xff000a22),
      secondary: Color(0xffbaffda),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xff8ad1ad),
      onSecondaryContainer: Color(0xff000e07),
      tertiary: Color(0xffe4f2ff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xff90c9f3),
      onTertiaryContainer: Color(0xff000d17),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff101417),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffedf0f9),
      outlineVariant: Color(0xffc0c2cc),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe0e3e8),
      inversePrimary: Color(0xff2d4779),
      primaryFixed: Color(0xffd8e2ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffadc6ff),
      onPrimaryFixedVariant: Color(0xff00102e),
      secondaryFixed: Color(0xffaaf2cc),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xff8ed5b0),
      onSecondaryFixedVariant: Color(0xff00150b),
      tertiaryFixed: Color(0xffc9e6ff),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xff94cdf7),
      onTertiaryFixedVariant: Color(0xff00131f),
      surfaceDim: Color(0xff101417),
      surfaceBright: Color(0xff4c5055),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1c2024),
      surfaceContainer: Color(0xff2d3135),
      surfaceContainerHigh: Color(0xff383c40),
      surfaceContainerHighest: Color(0xff43474b),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    textTheme: textTheme.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    scaffoldBackgroundColor: colorScheme.background,
    canvasColor: colorScheme.surface,
    inputDecorationTheme: CustomInputDecorationTheme.getTheme(colorScheme),
    appBarTheme: CustomAppBarTheme.getTheme(colorScheme,textTheme),
    bottomNavigationBarTheme: CustomBottomNavigationBarTheme.getTheme(colorScheme),
    elevatedButtonTheme: CustomElevatedButtonTheme.getTheme(colorScheme),
    outlinedButtonTheme: CustomOutlinedButtonTheme.getTheme(colorScheme),
    radioTheme: CustomRadioTheme.getTheme(colorScheme),
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
