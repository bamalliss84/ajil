import 'package:flutter/material.dart';

/// رموز ألوان لوحة الإدارة بالمظهرين (القيم من docs/DESIGN.md — نفس رموز التطبيق).
/// المظهر يُختار بـ ‎?theme=ocean‎ في الرابط أو بزر التبديل في الشريط الجانبي.
@immutable
class AdminTheme extends ThemeExtension<AdminTheme> {
  const AdminTheme({
    required this.id,
    required this.nameAr,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.header,
    required this.onHeader,
    required this.onHeaderMuted,
    required this.accent,
    required this.text,
    required this.textMuted,
    required this.background,
    required this.surface,
    required this.border,
    required this.debt,
    required this.debtBg,
    required this.paid,
  });

  final String id;
  final String nameAr;
  final Color primary, primaryDark, primaryLight;
  final Color header, onHeader, onHeaderMuted, accent;
  final Color text, textMuted, background, surface, border;
  final Color debt, debtBg, paid;

  static const classic = AdminTheme(
    id: 'classic',
    nameAr: 'الأخضر الكلاسيكي',
    primary: Color(0xFF0F6E56),
    primaryDark: Color(0xFF085041),
    primaryLight: Color(0xFFE1F5EE),
    header: Color(0xFF0F6E56),
    onHeader: Color(0xFFFFFFFF),
    onHeaderMuted: Color(0xFFCDE9DF),
    accent: Color(0xFF0F6E56),
    text: Color(0xFF1F2A2E),
    textMuted: Color(0xFF5B6B70),
    background: Color(0xFFF5F7F6),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFD5DDDB),
    debt: Color(0xFFB03224),
    debtBg: Color(0xFFFCEDEB),
    paid: Color(0xFF1E7A43),
  );

  static const ocean = AdminTheme(
    id: 'ocean',
    nameAr: 'فيروزي وكحلي',
    primary: Color(0xFF11856F),
    primaryDark: Color(0xFF0D7A66),
    primaryLight: Color(0xFFE3F6F1),
    header: Color(0xFF16324F),
    onHeader: Color(0xFFFFFFFF),
    onHeaderMuted: Color(0xFFC6D5E4),
    accent: Color(0xFF16A085),
    text: Color(0xFF16324F),
    textMuted: Color(0xFF5B7183),
    background: Color(0xFFF4F7FA),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFCFDBE4),
    debt: Color(0xFFC0392B),
    debtBg: Color(0xFFFBEDEB),
    paid: Color(0xFF1E7A43),
  );

  static AdminTheme byId(String? id) => id == ocean.id ? ocean : classic;

  @override
  AdminTheme copyWith() => this;

  @override
  AdminTheme lerp(AdminTheme? other, double t) => t < .5 ? this : (other ?? this);

  ThemeData toThemeData() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          onPrimary: surface,
          error: debt,
          surface: surface,
          onSurface: text,
        ),
        fontFamily: 'IBMPlexSansArabic',
        scaffoldBackgroundColor: background,
        dividerColor: border,
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: header,
          indicatorColor: onHeader.withOpacity(.16),
          selectedIconTheme: IconThemeData(color: onHeader),
          unselectedIconTheme: IconThemeData(color: onHeaderMuted),
          selectedLabelTextStyle: TextStyle(color: onHeader, fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w600),
          unselectedLabelTextStyle: TextStyle(color: onHeaderMuted, fontFamily: 'IBMPlexSansArabic'),
        ),
        extensions: [this],
      );
}

extension AdminThemeContext on BuildContext {
  AdminTheme get adm => Theme.of(this).extension<AdminTheme>() ?? AdminTheme.classic;
}

/// المظهر الحالي للوحة — يبدأ من ‎?theme=‎ في الرابط
final adminTheme = ValueNotifier<AdminTheme>(AdminTheme.byId(Uri.base.queryParameters['theme']));
