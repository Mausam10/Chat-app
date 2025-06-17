import 'package:flutter/material.dart';

class AppThemes {
  static final allThemes = <String, ThemeData>{
    'Light': ThemeData.light(),
    'Dark': ThemeData.dark(),

    'Cyberpunk': ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      primarySwatch: Colors.deepPurple,
      colorScheme: ColorScheme.dark(
        primary: Colors.deepPurpleAccent,
        secondary: Colors.amberAccent,
        background: Colors.black,
      ),
      appBarTheme: AppBarTheme(backgroundColor: Colors.deepPurple.shade900),
    ),

    'Emerald': ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: Colors.green.shade50,
      colorScheme: ColorScheme.light(
        primary: Colors.green.shade700,
        secondary: Colors.teal,
      ),
      appBarTheme: AppBarTheme(backgroundColor: Colors.green.shade700),
    ),

    'Valentine': ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.pink.shade50,
      primarySwatch: Colors.pink,
      colorScheme: ColorScheme.light(
        primary: Colors.pink.shade300,
        secondary: Colors.redAccent.shade100,
      ),
      appBarTheme: AppBarTheme(backgroundColor: Colors.pink.shade300),
    ),

    'Forest': ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1B2B2A),
      primaryColor: const Color(0xFF1C4532),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF3F6240),
        secondary: const Color(0xFFA3D9A5),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1C4532)),
    ),

    'Lofi': ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F4F5),
      primaryColor: Colors.grey.shade800,
      colorScheme: ColorScheme.light(
        primary: Colors.grey.shade800,
        secondary: Colors.grey.shade500,
      ),
      appBarTheme: AppBarTheme(backgroundColor: Colors.grey.shade200),
    ),

    'Pastel': ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFBF4),
      primaryColor: const Color(0xFFFFB7B2),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFFFFB7B2),
        secondary: const Color(0xFFB4F8C8),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFFB7B2)),
    ),

    'Dracula': ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF282A36),
      primaryColor: const Color(0xFFBD93F9),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFBD93F9),
        secondary: const Color(0xFFFF79C6),
        background: const Color(0xFF282A36),
      ),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF44475A)),
    ),
  };
}
