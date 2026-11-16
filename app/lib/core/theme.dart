import 'package:flutter/material.dart';

/// ألوان آجِل — المرجع: docs/DESIGN.md و docs/design/*.dc.html
class AjilColors {
  static const primary = Color(0xFF0F6E56);
  static const primaryDark = Color(0xFF085041);
  static const primaryLight = Color(0xFFE1F5EE);
  static const primaryMid = Color(0xFF1A7D64); // زر الجرس في الهيدر
  static const onPrimaryMuted = Color(0xFFCFEDE3); // نص ثانوي على الأخضر
  static const text = Color(0xFF1F2A2E);
  static const textMuted = Color(0xFF5B6B70);
  static const textSoft = Color(0xFF3D4B50);
  static const background = Color(0xFFF5F7F6);
  static const surface = Colors.white;
  static const border = Color(0xFFD5DDDB);
  static const borderStrong = Color(0xFFC9D6D2); // حدود الزر الثانوي
  static const headerBorder = Color(0xFFE3E9E7); // خط أسفل الهيدر وأعلى الشريط السفلي
  static const divider = Color(0xFFEEF2F1);
  static const track = Color(0xFFEEF2F1); // خلفية المقطّع والوحدات
  static const keyBg = Color(0xFFF1F5F4); // أزرار PIN
  static const dotEmpty = Color(0xFF9FB3AD);
  static const debt = Color(0xFFB03224);
  static const debtBg = Color(0xFFFCEDEB);
  static const debtBorder = Color(0xFFE9B8B1);
  static const debtText = Color(0xFF7A2318); // نص على خلفية الدين
  static const debtTag = Color(0xFF8E2519);
  static const paid = Color(0xFF1E7A43);
  static const paidBg = Color(0xFFE3F3E9);
  static const paidBorder = Color(0xFFBFE0CC);
  static const paidDark = Color(0xFF17603A);
  static const pendingText = Color(0xFF7A4A07);
  static const pendingBg = Color(0xFFFBEFD9);
  static const pendingDot = Color(0xFFE0962A);
  static const pendingIcon = Color(0xFFA15C07);
  static const badgeText = Color(0xFF3B2402);
  static const infoText = Color(0xFF1D4F86);
  static const infoBg = Color(0xFFE6EEF8);
  static const chartLight = Color(0xFF9FD3BF);
  static const aging30 = Color(0xFFF2C46B);
  static const aging60 = Color(0xFFE58A55);
  static const chipSelected = Color(0xFF1F2A2E);
}

const ajilFont = 'IBMPlexSansArabic';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AjilColors.primary,
    primary: AjilColors.primary,
    onPrimary: Colors.white,
    surface: Colors.white,
    onSurface: AjilColors.text,
    surfaceTint: Colors.transparent,
    error: AjilColors.debt,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: ajilFont);
  final text = base.textTheme.apply(fontFamily: ajilFont, bodyColor: AjilColors.text, displayColor: AjilColors.text);

  const r12 = BorderRadius.all(Radius.circular(12));
  const r14 = BorderRadius.all(Radius.circular(14));
  const border = OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: AjilColors.border));

  return base.copyWith(
    scaffoldBackgroundColor: AjilColors.background,
    textTheme: text,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AjilColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 72,
      shape: Border(bottom: BorderSide(color: AjilColors.headerBorder)),
      titleTextStyle: TextStyle(fontFamily: ajilFont, fontSize: 19, fontWeight: FontWeight.w600, color: AjilColors.text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      hintStyle: const TextStyle(color: AjilColors.textMuted, fontSize: 15),
      labelStyle: const TextStyle(color: AjilColors.textSoft, fontSize: 14),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      helperStyle: const TextStyle(color: AjilColors.textMuted, fontSize: 12),
      border: border,
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: const OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: AjilColors.primary, width: 1.6)),
      errorBorder: const OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: AjilColors.debt)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AjilColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: const RoundedRectangleBorder(borderRadius: r14),
        elevation: 0,
        textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AjilColors.primary,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: const RoundedRectangleBorder(borderRadius: r14),
        side: const BorderSide(color: AjilColors.borderStrong),
        textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AjilColors.primary,
        textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(44, 44), foregroundColor: AjilColors.text),
    ),
    cardTheme: const CardTheme(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AjilColors.textSoft,
      titleTextStyle: TextStyle(fontFamily: ajilFont, fontSize: 15, color: AjilColors.text),
      subtitleTextStyle: TextStyle(fontFamily: ajilFont, fontSize: 13, color: AjilColors.textMuted),
      minVerticalPadding: 10,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AjilColors.primary : Colors.white),
      side: const BorderSide(color: AjilColors.textMuted, width: 1.4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : AjilColors.textMuted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AjilColors.primary : AjilColors.track),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: AjilColors.chipSelected,
      side: const BorderSide(color: AjilColors.border),
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(fontFamily: ajilFont, fontSize: 13, color: AjilColors.textSoft),
      secondaryLabelStyle: const TextStyle(fontFamily: ajilFont, fontSize: 13, color: Colors.white),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: AjilColors.track,
        selectedBackgroundColor: Colors.white,
        foregroundColor: AjilColors.textSoft,
        selectedForegroundColor: AjilColors.text,
        side: BorderSide.none,
        textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 15),
      ),
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
    popupMenuTheme: const PopupMenuThemeData(color: Colors.white, surfaceTintColor: Colors.transparent),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(fontFamily: ajilFont, fontSize: 14, color: Colors.white),
    ),
    dividerTheme: const DividerThemeData(color: AjilColors.divider, thickness: 1, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AjilColors.primary),
  );
}
