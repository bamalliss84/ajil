import 'package:flutter/material.dart';

/// مظهر آجِل — رمز لكل لون بمظهرين (المرجع: docs/DESIGN.md «الألوان — مظهران»).
/// **لا تكتب قيمة لون مباشرة في أي شاشة**: استخدم `context.ajil.<رمز>` وإلا لن يتبدّل المظهر.
/// القراءة عبر Theme.of تسجّل اعتماداً، فيُعاد بناء كل شاشة فور تغيير المظهر بلا إعادة تشغيل.
@immutable
class AjilTheme extends ThemeExtension<AjilTheme> {
  const AjilTheme({
    required this.id,
    required this.nameAr,
    required this.descriptionAr,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.header,
    required this.headerMid,
    required this.onHeaderMuted,
    required this.accent,
    required this.text,
    required this.textMuted,
    required this.textSoft,
    required this.background,
    required this.surface,
    required this.onPrimary,
    required this.border,
    required this.borderStrong,
    required this.headerBorder,
    required this.divider,
    required this.track,
    required this.keyBg,
    required this.dotEmpty,
    required this.debt,
    required this.debtBg,
    required this.debtBorder,
    required this.debtText,
    required this.debtTag,
    required this.paid,
    required this.paidBg,
    required this.paidBorder,
    required this.paidDark,
    required this.pendingText,
    required this.pendingBg,
    required this.pendingDot,
    required this.pendingIcon,
    required this.badgeText,
    required this.infoText,
    required this.infoBg,
    required this.chartLight,
    required this.chartProgress,
    required this.chartDebt,
    required this.axis,
    required this.axisEmpty,
    required this.aging30,
    required this.aging60,
    required this.chipSelected,
    required this.paperBorder,
    required this.paperMuted,
    required this.chatBubble,
    required this.shadow,
    required this.scrim,
  });

  /// classic | ocean — القيمة المحفوظة في app.app_users.theme
  final String id;
  final String nameAr;
  final String descriptionAr;

  /// الأزرار والعناصر الفاعلة (أسطح تحمل نصاً أبيض)
  final Color primary;
  final Color primaryDark;
  final Color primaryLight; // primaryTint في DESIGN.md
  /// الهيدر وأعلى الشاشة وبطاقات الملخص الكبيرة
  final Color header;
  final Color headerMid; // زر/بلاطة داخل الهيدر
  final Color onHeaderMuted; // نص ثانوي على الهيدر
  /// الأيقونات والتظليل والرسوم (لا نص أبيض عليه)
  final Color accent;
  final Color text;
  final Color textMuted;
  final Color textSoft;
  final Color background;
  final Color surface;
  final Color onPrimary;
  final Color border; // field
  final Color borderStrong;
  final Color headerBorder;
  final Color divider;
  final Color track;
  final Color keyBg;
  final Color dotEmpty;
  final Color debt;
  final Color debtBg;
  final Color debtBorder;
  final Color debtText;
  final Color debtTag;
  final Color paid;
  final Color paidBg;
  final Color paidBorder;
  final Color paidDark;
  final Color pendingText;
  final Color pendingBg;
  final Color pendingDot;
  final Color pendingIcon;
  final Color badgeText;
  final Color infoText;
  final Color infoBg;
  final Color chartLight;
  final Color chartProgress;
  final Color chartDebt;
  final Color axis;
  final Color axisEmpty;
  final Color aging30;
  final Color aging60;
  final Color chipSelected;
  final Color paperBorder; // حدود الإشعار/السند
  final Color paperMuted; // نص باهت على الإشعار
  final Color chatBubble; // معاينة رسالة واتساب
  final Color shadow;
  final Color scrim; // تظليل خفيف على الهيدر (أزرار شفافة)

  /// أ · الأخضر الكلاسيكي (الافتراضي)
  static const classic = AjilTheme(
    id: 'classic',
    nameAr: 'الأخضر الكلاسيكي',
    descriptionAr: 'هوية آجِل الأساسية',
    primary: Color(0xFF0F6E56),
    primaryDark: Color(0xFF085041),
    primaryLight: Color(0xFFE1F5EE),
    header: Color(0xFF0F6E56),
    headerMid: Color(0xFF1A7D64),
    onHeaderMuted: Color(0xFFCFEDE3),
    accent: Color(0xFF0F6E56),
    text: Color(0xFF1F2A2E),
    textMuted: Color(0xFF5B6B70),
    textSoft: Color(0xFF3D4B50),
    background: Color(0xFFF5F7F6),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
    border: Color(0xFFD5DDDB),
    borderStrong: Color(0xFFC9D6D2),
    headerBorder: Color(0xFFE3E9E7),
    divider: Color(0xFFEEF2F1),
    track: Color(0xFFEEF2F1),
    keyBg: Color(0xFFF1F5F4),
    dotEmpty: Color(0xFF9FB3AD),
    debt: Color(0xFFB03224),
    debtBg: Color(0xFFFCEDEB),
    debtBorder: Color(0xFFE9B8B1),
    debtText: Color(0xFF7A2318),
    debtTag: Color(0xFF8E2519),
    paid: Color(0xFF1E7A43),
    paidBg: Color(0xFFE3F3E9),
    paidBorder: Color(0xFFBFE0CC),
    paidDark: Color(0xFF17603A),
    pendingText: Color(0xFF7A4A07),
    pendingBg: Color(0xFFFBEFD9),
    pendingDot: Color(0xFFE0962A),
    pendingIcon: Color(0xFFA15C07),
    badgeText: Color(0xFF3B2402),
    infoText: Color(0xFF1D4F86),
    infoBg: Color(0xFFE6EEF8),
    chartLight: Color(0xFF9FD3BF),
    chartProgress: Color(0xFF9FE0C6),
    chartDebt: Color(0xFFD9776B),
    axis: Color(0xFFB7C2BF),
    axisEmpty: Color(0xFFE3E9E7),
    aging30: Color(0xFFF2C46B),
    aging60: Color(0xFFE58A55),
    chipSelected: Color(0xFF1F2A2E),
    paperBorder: Color(0xFFB9C4C1),
    paperMuted: Color(0xFF9AA6A3),
    chatBubble: Color(0xFFE7F6EE),
    shadow: Color(0x1F0F2823),
    scrim: Color(0x24FFFFFF),
  );

  /// ب · فيروزي وكحلي — هيدر كحلي، أزرار فيروزية معمّقة (#11856F لتباين 4.56 مع الأبيض)
  static const ocean = AjilTheme(
    id: 'ocean',
    nameAr: 'فيروزي وكحلي',
    descriptionAr: 'هيدر كحلي وأزرار فيروزية',
    primary: Color(0xFF11856F),
    primaryDark: Color(0xFF0D7A66),
    primaryLight: Color(0xFFE3F6F1),
    header: Color(0xFF16324F),
    headerMid: Color(0xFF244766),
    onHeaderMuted: Color(0xFFC6D5E4),
    accent: Color(0xFF16A085),
    text: Color(0xFF16324F),
    textMuted: Color(0xFF5B7183),
    textSoft: Color(0xFF34506A),
    background: Color(0xFFF4F7FA),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
    border: Color(0xFFCFDBE4),
    borderStrong: Color(0xFFBFCFDC),
    headerBorder: Color(0xFFDDE6ED),
    divider: Color(0xFFE8EEF3),
    track: Color(0xFFE8EEF3),
    keyBg: Color(0xFFEEF3F7),
    dotEmpty: Color(0xFF9DB0C0),
    debt: Color(0xFFC0392B),
    debtBg: Color(0xFFFBEDEB),
    debtBorder: Color(0xFFEBBDB7),
    debtText: Color(0xFF7A2318),
    debtTag: Color(0xFF8E2519),
    paid: Color(0xFF1E7A43),
    paidBg: Color(0xFFE4F3EA),
    paidBorder: Color(0xFFBFE0CC),
    paidDark: Color(0xFF17603A),
    pendingText: Color(0xFF7A4A07),
    pendingBg: Color(0xFFFBF0DA),
    pendingDot: Color(0xFFE0962A),
    pendingIcon: Color(0xFFA15C07),
    badgeText: Color(0xFF3B2402),
    infoText: Color(0xFF1F6FB2),
    infoBg: Color(0xFFE7F1FA),
    chartLight: Color(0xFF9FDACD),
    chartProgress: Color(0xFF8FDCCB),
    chartDebt: Color(0xFFDB7F74),
    axis: Color(0xFFB4C3CF),
    axisEmpty: Color(0xFFDDE6ED),
    aging30: Color(0xFFF2C46B),
    aging60: Color(0xFFE58A55),
    chipSelected: Color(0xFF16324F),
    paperBorder: Color(0xFFB7C6D2),
    paperMuted: Color(0xFF98A9B8),
    chatBubble: Color(0xFFE7F6EE),
    shadow: Color(0x1F16324F),
    scrim: Color(0x24FFFFFF),
  );

  static const all = [classic, ocean];

  /// عيّنات الألوان في شاشة «مظهر التطبيق» وصف الإعدادات
  List<Color> get swatches => id == ocean.id ? [header, accent, background] : [primary, primaryLight, background];

  static AjilTheme byId(String? id) => id == ocean.id ? ocean : classic;

  @override
  AjilTheme copyWith() => this;

  /// التبديل فوري (بلا تدرّج) — المظهر يُختار من قائمة ثابتة
  @override
  AjilTheme lerp(covariant AjilTheme? other, double t) => (other == null || t < 0.5) ? this : other;
}

extension AjilThemeContext on BuildContext {
  /// ألوان المظهر الحالي: `context.ajil.primary`
  AjilTheme get ajil => Theme.of(this).extension<AjilTheme>() ?? AjilTheme.classic;
}

const ajilFont = 'IBMPlexSansArabic';

ThemeData buildTheme([AjilTheme c = AjilTheme.classic]) {
  final scheme = ColorScheme.fromSeed(
    seedColor: c.primary,
    primary: c.primary,
    onPrimary: c.onPrimary,
    surface: c.surface,
    onSurface: c.text,
    surfaceTint: c.surface.withAlpha(0),
    error: c.debt,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: ajilFont);
  final text = base.textTheme.apply(fontFamily: ajilFont, bodyColor: c.text, displayColor: c.text);
  final none = c.surface.withAlpha(0);

  const r12 = BorderRadius.all(Radius.circular(12));
  const r14 = BorderRadius.all(Radius.circular(14));
  final border = OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: c.border));

  return base.copyWith(
    extensions: [c],
    scaffoldBackgroundColor: c.background,
    textTheme: text,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.text,
      surfaceTintColor: none,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 72,
      shape: Border(bottom: BorderSide(color: c.headerBorder)),
      titleTextStyle: TextStyle(fontFamily: ajilFont, fontSize: 19, fontWeight: FontWeight.w600, color: c.text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      hintStyle: TextStyle(color: c.textMuted, fontSize: 15),
      labelStyle: TextStyle(color: c.textSoft, fontSize: 14),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      helperStyle: TextStyle(color: c.textMuted, fontSize: 12),
      border: border,
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: c.primary, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: c.debt)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        minimumSize: const Size.fromHeight(54),
        shape: const RoundedRectangleBorder(borderRadius: r14),
        elevation: 0,
        textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.primary,
        backgroundColor: c.surface,
        minimumSize: const Size.fromHeight(54),
        shape: const RoundedRectangleBorder(borderRadius: r14),
        side: BorderSide(color: c.borderStrong),
        textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.primary,
        textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(44, 44), foregroundColor: c.text),
    ),
    cardTheme: CardTheme(
      color: c.surface,
      surfaceTintColor: none,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.textSoft,
      titleTextStyle: TextStyle(fontFamily: ajilFont, fontSize: 15, color: c.text),
      subtitleTextStyle: TextStyle(fontFamily: ajilFont, fontSize: 13, color: c.textMuted),
      minVerticalPadding: 10,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : c.surface),
      side: BorderSide(color: c.textMuted, width: 1.4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onPrimary : c.textMuted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : c.track),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : c.border),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.chipSelected,
      side: BorderSide(color: c.border),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(fontFamily: ajilFont, fontSize: 13, color: c.textSoft),
      secondaryLabelStyle: TextStyle(fontFamily: ajilFont, fontSize: 13, color: c.onPrimary),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: c.track,
        selectedBackgroundColor: c.surface,
        foregroundColor: c.textSoft,
        selectedForegroundColor: c.text,
        side: BorderSide.none,
        textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 15),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: c.surface,
      surfaceTintColor: none,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface, surfaceTintColor: none),
    popupMenuTheme: PopupMenuThemeData(color: c.surface, surfaceTintColor: none),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      contentTextStyle: TextStyle(fontFamily: ajilFont, fontSize: 14, color: c.onPrimary),
    ),
    dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
  );
}
