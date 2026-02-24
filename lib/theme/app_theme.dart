import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0D0D0D),
    fontFamily: 'Roboto',
    primaryColor: const Color(0xFFFF6A00),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF6A00),
      secondary: Color(0xFFFF6A00),
    ),
  );
}