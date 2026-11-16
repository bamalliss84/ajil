import 'package:decimal/decimal.dart';

/// العملات المدعومة. الإضافة هنا فقط تكفي لظهورها في الإعدادات.
class Currency {
  final String code;
  final String symbolAr;
  final String nameAr;
  final int decimals;
  const Currency(this.code, this.symbolAr, this.nameAr, {this.decimals = 0});

  static const yer = Currency('YER', 'ر.ي', 'ريال يمني');
  static const sar = Currency('SAR', 'ر.س', 'ريال سعودي', decimals: 2);
  static const usd = Currency('USD', '\$', 'دولار أمريكي', decimals: 2);
  static const aed = Currency('AED', 'د.إ', 'درهم إماراتي', decimals: 2);
  static const omr = Currency('OMR', 'ر.ع', 'ريال عماني', decimals: 3);
  static const kwd = Currency('KWD', 'د.ك', 'دينار كويتي', decimals: 3);

  static const all = [yer, sar, usd, aed, omr, kwd];

  static Currency of(String code) =>
      all.firstWhere((c) => c.code == code, orElse: () => Currency(code, code, code, decimals: 2));
}

/// تنسيق المبالغ: فواصل الآلاف، وخيار الأرقام الهندية (١٢٣)
class MoneyFormat {
  final bool arabicIndicDigits;
  const MoneyFormat({this.arabicIndicDigits = false});

  static const _indic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  String digits(String s) {
    if (!arabicIndicDigits) return s;
    return s.replaceAllMapped(RegExp(r'[0-9]'), (m) => _indic[int.parse(m[0]!)]).replaceAll('.', '٫').replaceAll(',', '٬');
  }

  /// 45250 → "45,250" ، 120.5 SAR → "120.50"
  String amount(Decimal value, String currency, {bool withSymbol = false, bool signed = false}) {
    final c = Currency.of(currency);
    final neg = value < Decimal.zero;
    final abs = neg ? -value : value;
    final fixed = abs.toStringAsFixed(c.decimals);
    final parts = fixed.split('.');
    final intPart = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    var s = parts.length > 1 && !_allZero(parts[1]) ? '$intPart.${parts[1]}' : intPart;
    if (signed) s = '${neg ? '−' : '+'} $s';
    else if (neg) s = '−$s';
    if (withSymbol) s = '$s ${c.symbolAr}';
    return digits(s);
  }

  static bool _allZero(String s) => s.split('').every((ch) => ch == '0');

  /// يقرأ مبلغاً أدخله المستخدم (يقبل الأرقام الهندية والفواصل)
  static Decimal? parse(String input) {
    var s = input.trim();
    const indic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = indic.indexOf(ch);
      final p = persian.indexOf(ch);
      if (i >= 0) {
        b.write(i);
      } else if (p >= 0) {
        b.write(p);
      } else if (ch == '٫') {
        b.write('.');
      } else if (ch == ',' || ch == '٬' || ch == ' ') {
        continue;
      } else {
        b.write(ch);
      }
    }
    s = b.toString();
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(s)) return null;
    return Decimal.parse(s);
  }
}
