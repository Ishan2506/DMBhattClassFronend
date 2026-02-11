import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppThemeStyle {
  classic,
  ocean,
  sunset,
  forest,
  lavender,
  midnight
}

// --- State ---
class ThemeState {
  final ThemeMode themeMode;
  final Locale locale;
  final AppThemeStyle selectedStyle;

  const ThemeState({
    required this.themeMode,
    required this.locale,
    this.selectedStyle = AppThemeStyle.classic,
  });

  factory ThemeState.initial() {
    return const ThemeState(
      themeMode: ThemeMode.system,
      locale: Locale('en'),
      selectedStyle: AppThemeStyle.classic,
    );
  }

  ThemeState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    AppThemeStyle? selectedStyle,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      selectedStyle: selectedStyle ?? this.selectedStyle,
    );
  }
}

// --- Cubit ---
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(ThemeState.initial());

  void changeTheme(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
  }

  void changeLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
  }

  void changeStyle(AppThemeStyle style) {
    emit(state.copyWith(selectedStyle: style));
  }
}
  