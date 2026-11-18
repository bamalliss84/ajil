import 'package:ajil/services/whatsapp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tpl = 'السلام عليكم {الاسم}، نذكّرك بأن رصيدك لدى {البقالة} هو {المبلغ}. كشف حسابك: {الرابط}. شكراً لتعاملك معنا.';

  test('الرابط يُملأ في القالب', () {
    final m = Whatsapp.fill(tpl, name: 'علي', store: 'الأمانة', amount: '5,000 ر.ي', link: 'https://x.app/statement/#abc');
    expect(m, 'السلام عليكم علي، نذكّرك بأن رصيدك لدى الأمانة هو 5,000 ر.ي. كشف حسابك: https://x.app/statement/#abc. شكراً لتعاملك معنا.');
  });

  test('بدون رابط تُحذف جملة الرابط كاملة', () {
    final m = Whatsapp.fill(tpl, name: 'علي', store: 'الأمانة', amount: '120.50 ر.س');
    expect(m, 'السلام عليكم علي، نذكّرك بأن رصيدك لدى الأمانة هو 120.50 ر.س. شكراً لتعاملك معنا.');
    expect(m, isNot(contains('{الرابط}')));
  });

  test('الرابط في آخر القالب أو في سطر مستقل', () {
    expect(Whatsapp.fill('رصيدك {المبلغ}. الكشف: {الرابط}', name: '', store: '', amount: '1'), 'رصيدك 1.');
    expect(Whatsapp.fill('رصيدك {المبلغ}\nالكشف: {الرابط}\nشكراً', name: '', store: '', amount: '1'), 'رصيدك 1\n\nشكراً');
  });
}
