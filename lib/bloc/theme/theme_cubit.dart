import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      themeMode: ThemeMode.light,
      locale: Locale('en'),
      selectedStyle: AppThemeStyle.classic,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.index,
      'locale': locale.languageCode,
      'selectedStyle': selectedStyle.index,
    };
  }

  factory ThemeState.fromMap(Map<String, dynamic> map) {
    return ThemeState(
      themeMode: ThemeMode.values[map['themeMode'] ?? ThemeMode.system.index],
      locale: Locale(map['locale'] ?? 'en'),
      selectedStyle: AppThemeStyle.values[map['selectedStyle'] ?? AppThemeStyle.classic.index],
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
  final SharedPreferences prefs;
  static const String _storageKey = 'theme_settings';

  ThemeCubit(this.prefs) : super(_loadInitialState(prefs));

  static ThemeState _loadInitialState(SharedPreferences prefs) {
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      try {
        final Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(data));
        ThemeState state = ThemeState.fromMap(map);
        // Force Light Mode on every startup as requested
        return state.copyWith(themeMode: ThemeMode.light);
      } catch (e) {
        debugPrint("Error loading persistent theme: $e");
      }
    }
    return ThemeState.initial();
  }

  void _saveState() {
    prefs.setString(_storageKey, jsonEncode(state.toMap()));
  }

  void changeTheme(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
    _saveState();
  }

  void changeLocale(Locale locale) {
    emit(state.copyWith(locale: locale));
    _saveState();
  }

  void changeStyle(AppThemeStyle style) {
    emit(state.copyWith(selectedStyle: style));
    _saveState();
  }
}
  