import 'errors.dart';

/// مطابق لـ supabase/functions/_shared/identity.ts
class Identity {
  Identity._();

  static String normalizePhone(String input, {String countryCode = '967'}) {
    const indic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    final b = StringBuffer();
    for (final ch in input.split('')) {
      final i = indic.indexOf(ch);
      final p = persian.indexOf(ch);
      if (i >= 0) {
        b.write(i);
      } else if (p >= 0) {
        b.write(p);
      } else if (RegExp(r'\d').hasMatch(ch)) {
        b.write(ch);
      }
    }
    var p = b.toString().replaceFirst(RegExp(r'^00'), '');
    if (p.startsWith(countryCode)) p = p.substring(countryCode.length);
    p = p.replaceFirst(RegExp(r'^0+'), '');
    if (p.length < 7 || p.length > 12) throw const AjilError('phone_invalid', 'رقم الجوال غير صحيح');
    return p;
  }

  static String derivedEmail(String storePhone, int userNo) {
    if (userNo < 1) throw const AjilError('user_no_invalid', 'رقم المستخدم غير صحيح');
    return 'u$userNo.$storePhone@users.ajil.app';
  }
}
