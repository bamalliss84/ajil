import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../data/repository.dart';
import '../state/providers.dart';

/// واتساب يُفتح من جوال صاحب البقالة بضغطة منه — لا رسائل آلية (مجاني ولا يعرّض رقمه للحظر)
class Whatsapp {
  static const defaultTemplate =
      'السلام عليكم {الاسم}، نذكّرك بأن رصيدك لدى {البقالة} هو {المبلغ}. شكراً لتعاملك معنا.';

  static String _intl(String phone) {
    try {
      return '${AppConfig.countryCode}${Identity.normalizePhone(phone, countryCode: AppConfig.countryCode)}';
    } catch (_) {
      return phone.replaceAll(RegExp(r'\D'), '');
    }
  }

  static String fill(String template, {required String name, required String store, required String amount, String link = ''}) =>
      template
          .replaceAll('{الاسم}', name)
          .replaceAll('{البقالة}', store)
          .replaceAll('{المبلغ}', amount)
          .replaceAll('{الرابط}', link)
          .replaceAll(RegExp(r'\s+\.\s*$'), '.')
          .trim();

  static String balancesText(MoneyFormat f, Map<String, CurrencyBalance> balances) => balances.values
      .where((b) => b.balance != Decimal.zero)
      .map((b) => f.amount(b.balance, b.currency, withSymbol: true))
      .join(' و ');

  static Future<void> send(String phone, String message) => launchUrl(
        Uri.parse('https://wa.me/${_intl(phone)}?text=${Uri.encodeComponent(message)}'),
        mode: LaunchMode.externalApplication,
      );

  static Future<void> call(String phone) => launchUrl(Uri(scheme: 'tel', path: phone));

  static Future<void> remind(WidgetRef ref, CustomerWithBalance c, {String? template}) async {
    final s = ref.read(sessionProvider).session!;
    final f = ref.read(moneyFormatProvider);
    final phone = c.customer.phone;
    if (phone == null) return;
    await send(
      phone,
      fill(template ?? defaultTemplate,
          name: c.customer.name, store: s.storeName, amount: balancesText(f, c.balances)),
    );
  }
}
