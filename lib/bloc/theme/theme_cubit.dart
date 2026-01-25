import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- State ---
class ThemeState {
  final ThemeMode themeMode;
  final Locale locale;

  const ThemeState({
    required this.themeMode,
    required this.locale,
  });

  factory ThemeState.initial() {
    return const ThemeState(
      themeMode: ThemeMode.system,
      locale: Locale('en'),
    );
  }

  ThemeState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
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
}
