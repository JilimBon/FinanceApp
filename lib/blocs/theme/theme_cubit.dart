import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _themeKey = 'theme_mode';

  ThemeCubit() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    if (themeString == 'dark') {
      emit(ThemeMode.dark);
    } else if (themeString == 'light') {
      emit(ThemeMode.light);
    } else if (themeString == 'system') {
      emit(ThemeMode.system);
    }
  }

  Future<void> toggleTheme() async {
    final newTheme = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(newTheme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, newTheme == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.light ? 'light' : 'system');
  }
}