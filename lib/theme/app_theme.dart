import 'package:flutter/material.dart';

class PixBarColors {
  static const Color background = Color(0xFF080808);
  static const Color panel = Color(0xFF111318);
  static const Color panel2 = Color(0xFF161A20);
  static const Color border = Color(0xFF252A33);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color magenta = Color(0xFFFF2D78);
  static const Color green = Color(0xFF39FF14);
  static const Color yellow = Color(0xFFFFE600);
  static const Color white = Color(0xFFF0F4FF);
  static const Color grey = Color(0xFF6B7280);
  static const Color grey2 = Color(0xFF9CA3AF);
}

class PixBarTheme {
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: PixBarColors.background,
    fontFamily: 'ExoTwo',
    colorScheme: const ColorScheme.dark(
      primary: PixBarColors.cyan,
      secondary: PixBarColors.magenta,
      surface: PixBarColors.panel,
    ),
  );
}

class PixBarText {
  static const TextStyle display = TextStyle(
    fontFamily: 'BlackOpsOne',
    color: PixBarColors.white,
    letterSpacing: 2,
  );
  static const TextStyle mono = TextStyle(
    fontFamily: 'ShareTechMono',
    color: PixBarColors.grey2,
    letterSpacing: 1,
  );
  static const TextStyle monoCyan = TextStyle(
    fontFamily: 'ShareTechMono',
    color: PixBarColors.cyan,
    letterSpacing: 2,
  );
}