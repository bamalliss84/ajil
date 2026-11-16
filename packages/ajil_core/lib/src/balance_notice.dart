import 'package:decimal/decimal.dart';

import 'ledger.dart';
import 'models.dart';
import 'money.dart';

/// إرسال الأرصدة الجماعي: من يستلم، وماذا يُكتب له.
/// الإرسال نفسه يتم من واتساب صاحب البقالة بضغطة لكل زبون (مجاني ولا يعرّض رقمه للحظر).

/// شروط اختيار الزبائن
class NoticeFilter {
  /// الزبائن الذين عليهم فقط (بدون من لهم رصيد دائن)
  final bool debtorsOnly;

  /// أقل مبلغ يستحق الإرسال (بعملة [currency] أو بأي عملة إن لم تُحدد)
  final Decimal? minAmount;

  /// عملة واحدة فقط، أو null لكل العملات
  final String? currency;

  /// تخطَّ من أُرسل له خلال هذه الأيام (null = لا تتخطَّ)
  final int? skipSentWithinDays;

  const NoticeFilter({this.debtorsOnly = true, this.minAmount, this.currency, this.skipSentWithinDays = 7});

  Map<String, dynamic> toJson() => {
        'debtors_only': debtorsOnly,
        if (minAmount != null) 'min_amount': minAmount.toString(),
        if (currency != null) 'currency': currency,
        if (skipSentWithinDays != null) 'skip_days': skipSentWithinDays,
      };

  factory NoticeFilter.fromJson(Map<String, dynamic> j) => NoticeFilter(
        debtorsOnly: j['debtors_only'] as bool? ?? true,
        minAmount: j['min_amount'] == null ? null : Decimal.parse(j['min_amount'] as String),
        currency: j['currency'] as String?,
        skipSentWithinDays: j['skip_days'] as int?,
      );
}

/// زبون سيستلم رسالة، مع أرصدته غير الصفرية حتى التاريخ
class NoticeRecipient {
  final Customer customer;
  final Map<String, Decimal> balances; // موجب = عليه، سالب = له
  const NoticeRecipient(this.customer, this.balances);

  bool get owes => balances.values.any((b) => b > Decimal.zero);
}

/// نتيجة الفرز: المستلمون + من استُبعدوا ولماذا (للعرض قبل البدء)
class NoticeSelection {
  final List<NoticeRecipient> recipients;
  final List<Customer> noPhone; // عليهم رصيد لكن بلا رقم
  final int recentlySent; // تُخطّوا لأنهم استلموا مؤخراً
  const NoticeSelection(this.recipients, this.noPhone, this.recentlySent);

  /// إجمالي المطلوب لكل عملة (للملخص أعلى الشاشة)
  Map<String, Decimal> get totals {
    final m = <String, Decimal>{};
    for (final r in recipients) {
      for (final e in r.balances.entries) {
        if (e.value > Decimal.zero) m[e.key] = (m[e.key] ?? Decimal.zero) + e.value;
      }
    }
    return m;
  }
}

class BalanceNotices {
  BalanceNotices._();

  static const defaultTemplate =
      'السلام عليكم {الاسم}،\nرصيدكم لدى {البقالة} حتى تاريخ {التاريخ}: {الرصيد}.\n'
      'إذا سددتم بعد هذا التاريخ فتجاهلوا هذه الرسالة. شكراً لتعاملكم معنا.';

  static const placeholders = ['{الاسم}', '{البقالة}', '{التاريخ}', '{الرصيد}', '{الرابط}'];

  /// يفرز الزبائن حسب الشروط. [txsByCustomer] كل حركات الفرع مجمعة بالزبون.
  /// [lastSent] آخر إرسال لكل زبون (من سجل الإرسال).
  static NoticeSelection select({
    required Iterable<Customer> customers,
    required Map<String, List<LedgerTx>> txsByCustomer,
    required DateTime asOf,
    NoticeFilter filter = const NoticeFilter(),
    Map<String, DateTime> lastSent = const {},
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final recipients = <NoticeRecipient>[];
    final noPhone = <Customer>[];
    var recent = 0;

    for (final c in customers) {
      if (c.status != CustomerStatus.active) continue;
      final all = Ledger.balancesAsOf(txsByCustomer[c.id] ?? const [], asOf);
      final bal = <String, Decimal>{
        for (final b in all.values)
          if (b.balance != Decimal.zero && (filter.currency == null || b.currency == filter.currency)) b.currency: b.balance,
      };
      if (bal.isEmpty) continue;
      if (filter.debtorsOnly) bal.removeWhere((_, v) => v < Decimal.zero);
      if (bal.isEmpty) continue;
      if (filter.minAmount != null && !bal.values.any((v) => v.abs() >= filter.minAmount!)) continue;

      final last = lastSent[c.id];
      if (filter.skipSentWithinDays != null && last != null &&
          today.difference(last).inDays < filter.skipSentWithinDays!) {
        recent++;
        continue;
      }
      if (c.phone == null || c.phone!.trim().isEmpty) {
        noPhone.add(c);
        continue;
      }
      recipients.add(NoticeRecipient(c, bal));
    }
    // الأكبر ديناً أولاً: لو توقف في المنتصف يكون أهم الزبائن قد استلموا
    recipients.sort((a, b) => _weight(b).compareTo(_weight(a)));
    return NoticeSelection(recipients, noPhone, recent);
  }

  static Decimal _weight(NoticeRecipient r) =>
      r.balances.values.fold(Decimal.zero, (s, v) => v > Decimal.zero ? s + v : s);

  /// "30,000 ر.ي عليكم و 150 ر.س لكم"
  static String balancesText(Map<String, Decimal> balances, MoneyFormat f) => balances.entries
      .map((e) => '${f.amount(e.value.abs(), e.key, withSymbol: true)} ${e.value > Decimal.zero ? 'عليكم' : 'لكم'}')
      .join(' و ');

  static String date(DateTime d, MoneyFormat f) =>
      f.digits('${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}');

  /// يملأ القالب. سطر الرابط يُحذف إن لم يوجد رابط.
  static String render(
    String template, {
    required NoticeRecipient r,
    required String store,
    required DateTime asOf,
    required MoneyFormat f,
    String? link,
  }) {
    var t = template;
    if (link == null || link.isEmpty) {
      t = t.split('\n').where((line) => !line.contains('{الرابط}')).join('\n');
    }
    return t
        .replaceAll('{الاسم}', r.customer.name)
        .replaceAll('{البقالة}', store)
        .replaceAll('{التاريخ}', date(asOf, f))
        .replaceAll('{الرصيد}', balancesText(r.balances, f))
        .replaceAll('{الرابط}', link ?? '')
        .trim();
  }
}

/// دفعة إرسال محفوظة على الجوال — تُستأنف لو أُغلق التطبيق في المنتصف
class NoticeBatch {
  final String id;
  final DateTime asOf;
  final String template;
  final NoticeFilter filter;
  final List<String> queue; // معرّفات الزبائن بالترتيب
  final Set<String> sent;
  final Set<String> skipped;
  final DateTime startedAt;

  NoticeBatch({
    required this.id,
    required this.asOf,
    required this.template,
    required this.filter,
    required this.queue,
    Set<String>? sent,
    Set<String>? skipped,
    DateTime? startedAt,
  })  : sent = sent ?? {},
        skipped = skipped ?? {},
        startedAt = startedAt ?? DateTime.now();

  /// أول زبون لم يُرسل له ولم يُتخطَّ
  String? get next => queue.where((id) => !sent.contains(id) && !skipped.contains(id)).firstOrNull;
  int get done => sent.length + skipped.length;
  bool get finished => next == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'as_of': asOf.toIso8601String().substring(0, 10),
        'template': template,
        'filter': filter.toJson(),
        'queue': queue,
        'sent': sent.toList(),
        'skipped': skipped.toList(),
        'started_at': startedAt.toIso8601String(),
      };

  factory NoticeBatch.fromJson(Map<String, dynamic> j) => NoticeBatch(
        id: j['id'] as String,
        asOf: DateTime.parse(j['as_of'] as String),
        template: j['template'] as String,
        filter: NoticeFilter.fromJson(Map<String, dynamic>.from(j['filter'] as Map)),
        queue: List<String>.from(j['queue'] as List),
        sent: Set<String>.from(j['sent'] as List),
        skipped: Set<String>.from(j['skipped'] as List),
        startedAt: DateTime.parse(j['started_at'] as String),
      );
}
