import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF23B574);
  static const primaryInk = Color(0xFF0F8A55);
  static const mint = Color(0xFFE9F7F0);
  static const bg = Color(0xFFF3F7F4);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF17251D);
  static const sub = Color(0xFF8A9A91);
  static const line = Color(0xFFEDF2EE);
  static const orange = Color(0xFFFF8A4C);
  static const red = Color(0xFFFF5F6D);

  static const dBg = Color(0xFF0E1013);
  static const dCard = Color(0xFF171A1F);
  static const dText = Color(0xFFF2F3F5);
  static const dSub = Color(0xFF8B9099);
  static const dLine = Color(0xFF242830);
  static const dMint = Color(0xFF17352A);
}

const kSubjectPalette = <Color>[
  Color(0xFF5B6CFF),
  Color(0xFF22B07D),
  Color(0xFFF2994A),
  Color(0xFF9B51E0),
  Color(0xFFEB5757),
  Color(0xFF2D9CDB),
  Color(0xFFF2C94C),
  Color(0xFF6B7280),
];

bool isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

Color pageBg(BuildContext c) => isDark(c) ? AppColors.dBg : AppColors.bg;
Color cardBg(BuildContext c) => isDark(c) ? AppColors.dCard : AppColors.card;
Color textColor(BuildContext c) => isDark(c) ? AppColors.dText : AppColors.text;
Color subColor(BuildContext c) => isDark(c) ? AppColors.dSub : AppColors.sub;
Color lineColor(BuildContext c) => isDark(c) ? AppColors.dLine : AppColors.line;
Color mintBg(BuildContext c) => isDark(c) ? AppColors.dMint : AppColors.mint;

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFF3BD08A) : AppColors.primary,
    surface: dark ? AppColors.dCard : AppColors.card,
    onSurface: dark ? AppColors.dText : AppColors.text,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? AppColors.dBg : AppColors.bg,
    splashFactory: InkSparkle.splashFactory,
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: dark ? AppColors.dText : AppColors.text,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: dark ? AppColors.dText : AppColors.text,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: dark ? AppColors.dText : AppColors.text,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: dark ? AppColors.dSub : AppColors.sub,
      ),
    ),
    dividerColor: dark ? AppColors.dLine : AppColors.line,
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? AppColors.dCard : AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? AppColors.dCard : AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF1E2228) : const Color(0xFFF7FAF8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dark ? AppColors.dLine : AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dark ? AppColors.dLine : AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: dark ? const Color(0xFF3BD08A) : AppColors.primary),
      ),
    ),
  );
}
