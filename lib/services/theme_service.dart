import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_theme.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'app_theme';
  AppTheme _currentTheme = AppTheme();

  AppTheme get currentTheme => _currentTheme;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeJson = prefs.getString(_themeKey);
    
    if (themeJson != null) {
      try {
        final decoded = jsonDecode(themeJson);
        _currentTheme = AppTheme.fromJson(decoded);
        notifyListeners();
      } catch (e) {
        print('Error loading theme: $e');
      }
    }
  }

  Future<void> updateTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    final themeJson = jsonEncode(theme.toJson());
    await prefs.setString(_themeKey, themeJson);
  }

  Future<void> updatePrimaryColor(Color color) async {
    await updateTheme(_currentTheme.copyWith(primaryColor: color));
  }

  Future<void> updateAccentColor(Color color) async {
    await updateTheme(_currentTheme.copyWith(accentColor: color));
  }

  Future<void> updateThemeMode(AppThemeMode mode) async {
    await updateTheme(_currentTheme.copyWith(themeMode: mode));
  }

  Future<void> updateUseGradients(bool value) async {
    await updateTheme(_currentTheme.copyWith(useGradients: value));
  }

  Future<void> updateBorderRadius(double value) async {
    await updateTheme(_currentTheme.copyWith(borderRadius: value));
  }

  Future<void> updateCompactMode(bool value) async {
    await updateTheme(_currentTheme.copyWith(compactMode: value));
  }

  Future<void> resetTheme() async {
    await updateTheme(AppTheme());
  }
}
