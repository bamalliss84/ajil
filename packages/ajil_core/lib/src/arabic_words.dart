import 'package:decimal/decimal.dart';

import 'money.dart';

/// التفقيط: كتابة المبلغ بالحروف العربية — «ثلاثون ألف ريال يمني»
class ArabicWords {
  ArabicWords._();

  static const _ones = ['', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة'];
  static const _teens = [
    'عشرة', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر',
    'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر',
  ];
  static const _tens = ['', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون'];
  static const _hundreds = [
    '', 'مائة', 'مائتان', 'ثلاثمائة', 'أربعمائة', 'خمسمائة', 'ستمائة', 'سبعمائة', 'ثمانمائة', 'تسعمائة',
  ];

  /// (مفرد، مثنى، جمع 3–10، تمييز 11 فأكثر)
  static const _scales = [
    ('', '', '', ''),
    ('ألف', 'ألفان', 'آلاف', 'ألف'),
    ('مليون', 'مليونان', 'ملايين', 'مليون'),
    ('مليار', 'ملياران', 'مليارات', 'مليار'),
  ];

  /// رقم من 0 إلى 999
  static String _under1000(int n) {
    final parts = <String>[];
    final h = n ~/ 100;
    final rest = n % 100;
    if (h > 0) parts.add(_hundreds[h]);
    if (rest > 0) {
      if (rest < 10) {
        parts.add(_ones[rest]);
      } else if (rest < 20) {
        parts.add(_teens[rest - 10]);
      } else {
        final o = rest % 10;
        final t = _tens[rest ~/ 10];
        parts.add(o == 0 ? t : '${_ones[o]} و$t');
      }
    }
    return parts.join(' و');
  }

  static String integer(int n) {
    if (n == 0) return 'صفر';
    final groups = <String>[];
    var scale = 0;
    var rest = n;
    while (rest > 0 && scale < _scales.length) {
      final g = rest % 1000;
      if (g > 0) {
        final (one, two, few, many) = _scales[scale];
        String w;
        if (scale == 0) {
          w = _under1000(g);
        } else if (g == 1) {
          w = one;
        } else if (g == 2) {
          w = two;
        } else if (g <= 10) {
          w = '${_under1000(g)} $few';
        } else {
          w = '${_under1000(g)} $many';
        }
        groups.insert(0, w);
      }
      rest ~/= 1000;
      scale++;
    }
    return groups.join(' و');
  }

  static const _fractionNames = {'SAR': 'هللة', 'AED': 'فلس', 'KWD': 'فلس', 'OMR': 'بيسة', 'USD': 'سنت'};

  /// المبلغ كاملاً مع العملة: 30000 YER → «ثلاثون ألف ريال يمني»
  static String amount(Decimal value, String currency) {
    final c = Currency.of(currency);
    final abs = value < Decimal.zero ? -value : value;
    final whole = abs.truncate().toBigInt().toInt();
    var text = '${integer(whole)} ${c.nameAr}';
    if (c.decimals > 0) {
      final frac = ((abs - abs.truncate()) * Decimal.fromInt(10).pow(c.decimals).toDecimal())
          .round()
          .toBigInt()
          .toInt();
      if (frac > 0) text += ' و${integer(frac)} ${_fractionNames[currency] ?? 'جزء'}';
    }
    return '$text فقط لا غير';
  }
}
