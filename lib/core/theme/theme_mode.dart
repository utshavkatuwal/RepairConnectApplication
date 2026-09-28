import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light/dark mode separator state. Persisted locally; defaults to the
/// approved dark blueprint. All storage access is guarded so unit tests
/// and first-run never crash on missing plugins.
class ThemeModeState extends StateNotifier<ThemeMode> {
  static const key = 'rc_theme_mode';
  ThemeModeState() : super(ThemeMode.dark) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.getString(key);
      if (v == ThemeMode.light.name && mounted) {
        state = ThemeMode.light;
      }
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(key, mode.name);
    } catch (_) {}
  }

  Future<void> toggle() =>
      setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeState, ThemeMode>(
        (_) => ThemeModeState());
