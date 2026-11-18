import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config.dart';
import '../data/repository.dart';
import '../state/providers.dart';
import 'statement_links.dart';

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

  /// الجملة التي فيها {الرابط} (حتى النقطة التالية) — تُحذف كاملة إن لم يوجد رابط
  static final _linkSentence = RegExp(r'[^.،\n\s][^.،\n]*\{الرابط\}[^.\n]*\.?[^\S\n]*');

  static String fill(String template, {required String name, required String store, required String amount, String? link}) =>
      (link == null || link.isEmpty ? template.replaceAll(_linkSentence, '') : template)
          .replaceAll('{الاسم}', name)
          .replaceAll('{البقالة}', store)
          .replaceAll('{المبلغ}', amount)
          .replaceAll('{الرابط}', link ?? '')
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

  /// تذكير برصيد الزبون بقالب البقالة (إعدادات التنبيهات)، مع رابط الكشف إن وُجد
  static Future<void> remind(WidgetRef ref, CustomerWithBalance c, {String? template}) async {
    final ctl = ref.read(sessionProvider);
    final s = ctl.session!;
    final f = ref.read(moneyFormatProvider);
    final phone = c.customer.phone;
    if (phone == null) return;
    final tpl = template ?? (ctl.settings?['reminder_template'] as String?) ?? defaultTemplate;
    final link = tpl.contains('{الرابط}') ? await StatementLinks.linkFor(ctl, c.customer.id) : null;
    await send(
      phone,
      fill(tpl, name: c.customer.name, store: s.storeName, amount: balancesText(f, c.balances), link: link),
    );
  }
}
