import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ألوان آجِل — المرجع: docs/DESIGN.md
class AjilColors {
  static const primary = Color(0xFF0F6E56);
  static const primaryDark = Color(0xFF085041);
  static const primaryLight = Color(0xFFE1F5EE);
  static const text = Color(0xFF1F2A2E);
  static const textMuted = Color(0xFF5B6B70);
  static const textSoft = Color(0xFF3D4B50);
  static const background = Color(0xFFF5F7F6);
  static const border = Color(0xFFD5DDDB);
  static const divider = Color(0xFFEEF2F1);
  static const debt = Color(0xFFB03224);
  static const debtBg = Color(0xFFFCEDEB);
  static const debtBorder = Color(0xFFE9B8B1);
  static const paid = Color(0xFF1E7A43);
  static const paidBg = Color(0xFFE3F3E9);
  static const pendingText = Color(0xFF7A4A07);
  static const pendingBg = Color(0xFFFBEFD9);
  static const pendingDot = Color(0xFFE0962A);
  static const infoText = Color(0xFF1D4F86);
  static const infoBg = Color(0xFFE6EEF8);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AjilColors.primary, primary: AjilColors.primary, surface: Colors.white),
    scaffoldBackgroundColor: AjilColors.background,
  );
  final text = GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme).apply(
    bodyColor: AjilColors.text,
    displayColor: AjilColors.text,
  );
  const radius = BorderRadius.all(Radius.circular(12));
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AjilColors.text,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AjilColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AjilColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: AjilColors.primary, width: 1.6)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        side: const BorderSide(color: AjilColors.border),
        textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    ),
    cardTheme: const CardTheme(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
    ),
    dividerTheme: const DividerThemeData(color: AjilColors.divider, thickness: 1, space: 1),
  );
}
