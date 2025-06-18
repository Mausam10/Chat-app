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
    'Cupcake': ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFF1F5),
      primaryColor: const Color(0xFF65C3C8),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF65C3C8),
        secondary: Color(0xFFEF9FBC),
      ),
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
    'Rose': ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFF1F5),
      primaryColor: const Color(0xFFF43F5E),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFF43F5E),
        secondary: Color(0xFFFB7185),
      ),
    ),
    'Aqua': ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFDEF7FF),
      primaryColor: const Color(0xFF00B4D8),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00B4D8),
        secondary: Color(0xFF90E0EF),
      ),
    ),

    'Luxury': ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF181028),
      primaryColor: const Color(0xFF9575CD),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD1C4E9),
        secondary: Color(0xFFB39DDB),
      ),
    ),
    'Halloween': ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1F2937),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFB923C),
        secondary: Color(0xFFF97316),
      ),
    ),

    'Synthwave': ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF2E1065),
      colorScheme: const ColorScheme.dark(
        primary: Color.fromARGB(255, 65, 38, 126),
        secondary: Color(0xFFE879F9),
      ),
    ),

    'Winter': ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFE0F2FE),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0284C7),
        secondary: Color(0xFF7DD3FC),
      ),
    ),
    'Dark Blue': ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E3A8A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6),
        secondary: Color(0xFF60A5FA),
      ),
    ),
    'Sunset': ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFEDD5),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFF97316),
        secondary: Color(0xFFFBBF24),
      ),
    ),
    'Royal': ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6366F1),
        secondary: Color(0xFF818CF8),
      ),
    ),
    'Neon': ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111827),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF38BDF8),
        secondary: Color(0xFFA855F7),
      ),
    ),
    'Bubblegum': ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFF0F6),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFF472B6),
        secondary: Color(0xFFF9A8D4),
      ),
    ),
  };
}
