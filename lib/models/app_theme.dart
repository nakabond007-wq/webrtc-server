import 'package:flutter/material.dart';

enum AppThemeMode {
  light,
  dark,
  system,
}

class AppTheme {
  final Color primaryColor;
  final Color accentColor;
  final AppThemeMode themeMode;
  final bool useGradients;
  final double borderRadius;
  final bool compactMode;
  final String fontFamily;

  AppTheme({
    this.primaryColor = const Color(0xFF1A1A1A),
    this.accentColor = const Color(0xFF2D2D2D),
    this.themeMode = AppThemeMode.dark,
    this.useGradients = false,
    this.borderRadius = 12.0,
    this.compactMode = false,
    this.fontFamily = 'default',
  });

  Map<String, dynamic> toJson() => {
    'primaryColor': primaryColor.value,
    'accentColor': accentColor.value,
    'themeMode': themeMode.index,
    'useGradients': useGradients,
    'borderRadius': borderRadius,
    'compactMode': compactMode,
    'fontFamily': fontFamily,
  };

  factory AppTheme.fromJson(Map<String, dynamic> json) => AppTheme(
    primaryColor: Color(json['primaryColor'] as int),
    accentColor: Color(json['accentColor'] as int),
    themeMode: AppThemeMode.values[json['themeMode'] as int],
    useGradients: json['useGradients'] as bool,
    borderRadius: json['borderRadius'] as double,
    compactMode: json['compactMode'] as bool,
    fontFamily: json['fontFamily'] as String,
  );

  AppTheme copyWith({
    Color? primaryColor,
    Color? accentColor,
    AppThemeMode? themeMode,
    bool? useGradients,
    double? borderRadius,
    bool? compactMode,
    String? fontFamily,
  }) {
    return AppTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      themeMode: themeMode ?? this.themeMode,
      useGradients: useGradients ?? this.useGradients,
      borderRadius: borderRadius ?? this.borderRadius,
      compactMode: compactMode ?? this.compactMode,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  ThemeData toThemeData() {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        secondary: accentColor,
      ),
      useMaterial3: true,
      brightness: themeMode == AppThemeMode.dark ? Brightness.dark : Brightness.light,
    );
  }
}
