import 'package:decimal/decimal.dart';
import 'models.dart';
import 'tx_kind.dart';

/// رصيد زبون بعملة واحدة
class CurrencyBalance {
  final String currency;
  final Decimal debit; // كل ما زاد الدين
  final Decimal credit; // كل ما أنقص الدين
  const CurrencyBalance(this.currency, this.debit, this.credit);
  Decimal get balance => debit - credit;
}

/// قواعد الإشارة نفسها الموجودة في app.tx_before_insert — للعرض المحلي قبل المزامنة.
/// بعد المزامنة يُعتمد serverSignedAmount.
class Ledger {
  Ledger._();

  static Decimal signedAmount(LedgerTx tx, Map<String, LedgerTx> byId) {
    if (tx.serverSignedAmount != null && tx.sync == SyncState.synced) return tx.serverSignedAmount!;
    if (tx.kind == TxKind.voided) {
      final orig = byId[tx.voidedId];
      if (orig == null) return Decimal.zero; // الأصل لم يصل بعد — لا أثر حتى يصل
      return -signedAmount(orig, byId);
    }
    return tx.kind.isDebit ? tx.amount : -tx.amount;
  }

  /// الأرصدة لكل عملة (الحركات المرفوضة من الخادم لا تُحسب)
  static Map<String, CurrencyBalance> balances(Iterable<LedgerTx> txs) {
    final list = txs.where((t) => t.sync != SyncState.failed).toList();
    final byId = {for (final t in list) t.id: t};
    final debit = <String, Decimal>{};
    final credit = <String, Decimal>{};
    for (final t in list) {
      final s = signedAmount(t, byId);
      final cur = t.kind == TxKind.voided ? (byId[t.voidedId]?.currency ?? t.currency) : t.currency;
      if (s > Decimal.zero) {
        debit[cur] = (debit[cur] ?? Decimal.zero) + s;
      } else if (s < Decimal.zero) {
        credit[cur] = (credit[cur] ?? Decimal.zero) - s;
      }
      debit.putIfAbsent(cur, () => Decimal.zero);
      credit.putIfAbsent(cur, () => Decimal.zero);
    }
    return {for (final c in debit.keys) c: CurrencyBalance(c, debit[c]!, credit[c]!)};
  }

  /// الأرصدة كما كانت في نهاية يوم معيّن: تُحسب الحركات حتى آخر ذلك اليوم فقط.
  /// إلغاء بعد التاريخ لا يؤثر (الحركة كانت قائمة في ذلك اليوم)، وإلغاء قبله يُحسب.
  static Map<String, CurrencyBalance> balancesAsOf(Iterable<LedgerTx> txs, DateTime day) {
    final end = DateTime(day.year, day.month, day.day + 1);
    return balances(txs.where((t) => t.createdAt.isBefore(end)));
  }

  /// معرّفات الحركات الملغاة (لا يُعرض لها زر إلغاء ثانٍ)
  static Set<String> voidedIds(Iterable<LedgerTx> txs) =>
      txs.where((t) => t.kind == TxKind.voided && t.voidedId != null && t.sync != SyncState.failed)
          .map((t) => t.voidedId!)
          .toSet();

  /// هل يحق لهذا المستخدم إلغاء الحركة؟ (مطابق لقواعد الخادم)
  static String? canVoid(LedgerTx tx,
      {required bool isOwner, required String userId, required Set<String> alreadyVoided,
      Duration employeeWindow = const Duration(hours: 24), DateTime? now}) {
    if (tx.kind == TxKind.voided) return 'لا يمكن إلغاء الإلغاء';
    if (alreadyVoided.contains(tx.id)) return 'الحركة ملغاة مسبقاً';
    if (isOwner) return null;
    if (tx.createdBy != userId) return 'الموظف يلغي حركاته فقط';
    if ((now ?? DateTime.now()).difference(tx.createdAt) > employeeWindow) {
      return 'انتهت مهلة الإلغاء — اطلب من المالك';
    }
    return null;
  }

  /// تجاوز سقف الدين بعد إضافة مبلغ؟
  static bool exceedsLimit(Customer c, Map<String, CurrencyBalance> bal, Decimal addAmount, String currency) {
    if (c.creditLimit == null) return false;
    if ((c.creditLimitCurrency ?? c.defaultCurrency) != currency) return false;
    final current = bal[currency]?.balance ?? Decimal.zero;
    return current + addAmount > c.creditLimit!;
  }
}

/// أعمار الديون: نوزع السداد على أقدم الديون أولاً (FIFO)، والمتبقي يُصنف حسب عمره
class AgingBuckets {
  final Decimal under30;
  final Decimal d30to60;
  final Decimal d60to90;
  final Decimal over90;
  const AgingBuckets(this.under30, this.d30to60, this.d60to90, this.over90);
  static final zero = AgingBuckets(Decimal.zero, Decimal.zero, Decimal.zero, Decimal.zero);
  Decimal get total => under30 + d30to60 + d60to90 + over90;
  AgingBuckets operator +(AgingBuckets o) =>
      AgingBuckets(under30 + o.under30, d30to60 + o.d30to60, d60to90 + o.d60to90, over90 + o.over90);

  /// عمر أقدم دين غير مسدد بالأيام (null = لا دين)
  static int? oldestDays(Iterable<LedgerTx> txs, String currency, DateTime today) {
    final open = _openDebits(txs, currency);
    if (open.isEmpty) return null;
    return today.difference(open.first.$1).inDays;
  }

  static AgingBuckets of(Iterable<LedgerTx> txs, String currency, DateTime today) {
    var a = Decimal.zero, b = Decimal.zero, c = Decimal.zero, d = Decimal.zero;
    for (final (date, amount) in _openDebits(txs, currency)) {
      final days = today.difference(date).inDays;
      if (days < 30) {
        a += amount;
      } else if (days < 60) {
        b += amount;
      } else if (days < 90) {
        c += amount;
      } else {
        d += amount;
      }
    }
    return AgingBuckets(a, b, c, d);
  }

  static List<(DateTime, Decimal)> _openDebits(Iterable<LedgerTx> all, String currency) {
    final txs = all.where((t) => t.sync != SyncState.failed).toList()
      ..sort((x, y) => x.createdAt.compareTo(y.createdAt));
    final byId = {for (final t in txs) t.id: t};
    final queue = <(DateTime, Decimal)>[];
    var credit = Decimal.zero;
    for (final t in txs) {
      final cur = t.kind == TxKind.voided ? (byId[t.voidedId]?.currency ?? t.currency) : t.currency;
      if (cur != currency) continue;
      final s = Ledger.signedAmount(t, byId);
      if (s > Decimal.zero) {
        queue.add((t.createdAt, s));
      } else {
        credit -= s;
      }
    }
    // السداد يغطي الأقدم أولاً
    final open = <(DateTime, Decimal)>[];
    for (final (date, amount) in queue) {
      if (credit >= amount) {
        credit -= amount;
      } else {
        open.add((date, amount - credit));
        credit = Decimal.zero;
      }
    }
    return open;
  }
}
