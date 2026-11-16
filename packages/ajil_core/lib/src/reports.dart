import 'package:decimal/decimal.dart';

import 'ledger.dart';
import 'models.dart';
import 'tx_kind.dart';

/// نوع فترة التقرير
enum PeriodKind { day, month, year, range }

DateTime _d(DateTime t) => DateTime(t.year, t.month, t.day);
int _monthLen(int y, int m) => DateTime(y, m + 1, 0).day;

/// فترة تقرير: من بداية يوم [start] حتى نهاية يوم [end] (شاملة)
class ReportPeriod {
  final PeriodKind kind;
  final DateTime start;
  final DateTime end;

  const ReportPeriod._(this.kind, this.start, this.end);

  factory ReportPeriod.day(DateTime d) => ReportPeriod._(PeriodKind.day, _d(d), _d(d));
  factory ReportPeriod.month(int year, int month) {
    final s = DateTime(year, month);
    return ReportPeriod._(PeriodKind.month, s, DateTime(s.year, s.month, _monthLen(s.year, s.month)));
  }
  factory ReportPeriod.year(int year) => ReportPeriod._(PeriodKind.year, DateTime(year), DateTime(year, 12, 31));
  factory ReportPeriod.range(DateTime a, DateTime b) {
    final x = _d(a), y = _d(b);
    return x.isAfter(y) ? ReportPeriod._(PeriodKind.range, y, x) : ReportPeriod._(PeriodKind.range, x, y);
  }

  /// الافتراضي عند فتح التقارير: الشهر الحالي
  factory ReportPeriod.currentMonth(DateTime today) => ReportPeriod.month(today.year, today.month);

  /// نفس الفترة بنوع آخر حول تاريخ مرجعي (عند تبديل التبويب)
  factory ReportPeriod.of(PeriodKind kind, DateTime ref) => switch (kind) {
        PeriodKind.day => ReportPeriod.day(ref),
        PeriodKind.month => ReportPeriod.month(ref.year, ref.month),
        PeriodKind.year => ReportPeriod.year(ref.year),
        PeriodKind.range => ReportPeriod.range(DateTime(ref.year, ref.month), ref),
      };

  /// عدد أيام الفترة كاملة
  int get days => end.difference(start).inDays + 1;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(DateTime(end.year, end.month, end.day + 1));

  /// الفترة تحوي اليوم ولم تكتمل بعد
  bool isPartial(DateTime today) => contains(today) && end.isAfter(_d(today));

  /// آخر يوم يُحسب: اليوم إن كانت الفترة جارية، وإلا نهايتها
  DateTime effectiveEnd(DateTime today) => isPartial(today) ? _d(today) : end;

  /// بدأت الفترة؟ (الفترات المستقبلية لا تُعرض)
  bool isFuture(DateTime today) => start.isAfter(_d(today));

  ReportPeriod prev() => switch (kind) {
        PeriodKind.day => ReportPeriod.day(start.subtract(const Duration(days: 1))),
        PeriodKind.month => ReportPeriod.month(start.year, start.month - 1),
        PeriodKind.year => ReportPeriod.year(start.year - 1),
        PeriodKind.range => ReportPeriod.range(start.subtract(Duration(days: days)), start.subtract(const Duration(days: 1))),
      };

  ReportPeriod next() => switch (kind) {
        PeriodKind.day => ReportPeriod.day(DateTime(start.year, start.month, start.day + 1)),
        PeriodKind.month => ReportPeriod.month(start.year, start.month + 1),
        PeriodKind.year => ReportPeriod.year(start.year + 1),
        PeriodKind.range => ReportPeriod.range(end.add(const Duration(days: 1)), end.add(Duration(days: days))),
      };

  /// التالي معطّل إذا كانت الفترة الحالية (أو التالية في المستقبل)
  bool hasNext(DateTime today) => !next().isFuture(today);

  /// فترة المقارنة: السابقة، ولنفس عدد الأيام إن كانت الحالية جزئية (1–17 نوفمبر ← 1–17 أكتوبر)
  ReportPeriod comparison(DateTime today) {
    final eff = effectiveEnd(today);
    switch (kind) {
      case PeriodKind.day:
        return prev();
      case PeriodKind.month:
        final p = prev();
        if (!isPartial(today)) return p;
        final day = eff.day.clamp(1, _monthLen(p.start.year, p.start.month));
        return ReportPeriod._(PeriodKind.month, p.start, DateTime(p.start.year, p.start.month, day));
      case PeriodKind.year:
        final p = prev();
        if (!isPartial(today)) return p;
        final y = p.start.year;
        final day = eff.day.clamp(1, _monthLen(y, eff.month));
        return ReportPeriod._(PeriodKind.year, p.start, DateTime(y, eff.month, day));
      case PeriodKind.range:
        final len = eff.difference(start).inDays + 1;
        return ReportPeriod.range(start.subtract(Duration(days: len)), start.subtract(const Duration(days: 1)));
    }
  }

  @override
  bool operator ==(Object o) => o is ReportPeriod && o.kind == kind && o.start == start && o.end == end;
  @override
  int get hashCode => Object.hash(kind, start, end);
  @override
  String toString() => 'ReportPeriod($kind, $start – $end)';
}

/// مجموع ومبلغ لنوع حركة في الفترة (السداد يشمل السداد بعملة أخرى)
class KindSummary {
  final TxKind kind;
  final int count;
  final Decimal amount;
  const KindSummary(this.kind, this.count, this.amount);
}

/// تحصيل وديون يوم واحد (أو ساعة / شهر)
class Bucket {
  final DateTime at;
  final Decimal collected;
  final Decimal debt;
  final int count;
  const Bucket(this.at, this.collected, this.debt, this.count);
  bool get isEmpty => count == 0;
}

class CustomerStat {
  final String customerId;
  final Customer? customer;
  final Decimal amount;
  final int count;
  final Decimal balance;
  final DateTime? lastPaymentAt;
  const CustomerStat(this.customerId, this.customer, this.amount, this.count, this.balance, this.lastPaymentAt);
}

class UserStat {
  final String userId;
  final Decimal collected;
  final Decimal debt;
  final int ops;
  const UserStat(this.userId, this.collected, this.debt, this.ops);
}

class PromiseStats {
  final int kept;
  final int overdue;
  final int upcoming;
  const PromiseStats(this.kept, this.overdue, this.upcoming);
  int get total => kept + overdue + upcoming;
}

/// تقرير فترة كامل — يُحسب من القاعدة المحلية فقط (أوفلاين)، للفرع الحالي وبعملة واحدة.
/// القواعد: الحركات المرفوضة من الخادم لا تُحسب، والحركة الملغاة لا تدخل في التحصيل/الديون
/// (تظهر في سطر «إلغاء» بمبلغ أصلها).
class PeriodReport {
  final ReportPeriod period;
  final ReportPeriod comparisonPeriod;
  final String currency;
  final DateTime today;

  final Decimal openingDebt;
  final Decimal closingDebt;
  final Decimal collected;
  final int collectedCount;
  final Decimal newDebt;
  final int debtCount;
  final Decimal prevCollected;
  final Decimal prevNewDebt;

  /// يومي (لعرض الشهر والفترة المخصصة: كل أيام الفترة)، فارغ للسنة
  final List<Bucket> daily;

  /// شهري (12 شهراً) لعرض السنة
  final List<Bucket> monthly;

  /// 24 ساعة لعرض اليوم
  final List<Bucket> hourly;

  final List<KindSummary> kinds;
  final PromiseStats promises;
  final List<CustomerStat> topPayers;
  final List<CustomerStat> topDebtors;
  final List<CustomerStat> noPayment;
  final List<UserStat> users;
  final AgingBuckets aging;

  /// حركات الفترة بالعملة (الأحدث أولاً)
  final List<LedgerTx> txs;
  final int newCustomers;

  /// متوسط الأيام من الدين حتى سداده (FIFO) للديون التي اكتمل سدادها في الفترة
  final int? avgPayDays;

  const PeriodReport._({
    required this.period,
    required this.comparisonPeriod,
    required this.currency,
    required this.today,
    required this.openingDebt,
    required this.closingDebt,
    required this.collected,
    required this.collectedCount,
    required this.newDebt,
    required this.debtCount,
    required this.prevCollected,
    required this.prevNewDebt,
    required this.daily,
    required this.monthly,
    required this.hourly,
    required this.kinds,
    required this.promises,
    required this.topPayers,
    required this.topDebtors,
    required this.noPayment,
    required this.users,
    required this.aging,
    required this.txs,
    required this.newCustomers,
    required this.avgPayDays,
  });

  DateTime get effectiveEnd => period.effectiveEnd(today);

  /// نسبة التحصيل إلى الديون الجديدة (٪)، null إن لم توجد ديون جديدة
  int? get collectionRatio => newDebt == Decimal.zero ? null : _pct(collected, newDebt);

  /// التغيّر عن فترة المقارنة (٪)، null إن كانت السابقة صفراً
  int? get collectedChange => prevCollected == Decimal.zero ? null : _pct(collected - prevCollected, prevCollected);
  int? get debtChange => prevNewDebt == Decimal.zero ? null : _pct(newDebt - prevNewDebt, prevNewDebt);

  Decimal get net => collected - newDebt;

  Bucket? get bestDay => _best(daily);
  Bucket? get bestMonth => _best(monthly);

  DateTime? get lastTxAt => txs.isEmpty ? null : txs.first.createdAt;

  static Bucket? _best(List<Bucket> l) {
    Bucket? b;
    for (final x in l) {
      if (x.collected > Decimal.zero && (b == null || x.collected > b.collected)) b = x;
    }
    return b;
  }

  static int _pct(Decimal a, Decimal b) => ((a.toDouble() / b.toDouble()) * 100).round();

  static bool _isPayment(TxKind k) => k == TxKind.payment || k == TxKind.paymentFx;

  /// يبني التقرير. [txs] كل حركات الفرع (كل العملات)، و[customers] للأسماء.
  static PeriodReport build({
    required ReportPeriod period,
    required DateTime today,
    required String currency,
    required List<Customer> customers,
    required List<LedgerTx> txs,
    List<PaymentPromise> promises = const [],
  }) {
    final valid = txs.where((t) => t.sync != SyncState.failed).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final byId = {for (final t in valid) t.id: t};
    final voided = Ledger.voidedIds(valid);
    String curOf(LedgerTx t) => t.kind == TxKind.voided ? (byId[t.voidedId]?.currency ?? t.currency) : t.currency;
    final inCur = valid.where((t) => curOf(t) == currency).toList();
    final custById = {for (final c in customers) c.id: c};

    final cmp = period.comparison(today);
    final eff = period.effectiveEnd(today);
    final effPeriod = ReportPeriod.range(period.start, eff);

    // حركات «فعّالة»: غير ملغاة وليست قيود إلغاء
    bool live(LedgerTx t) => t.kind != TxKind.voided && !voided.contains(t.id);

    final inPeriod = inCur.where((t) => effPeriod.contains(t.createdAt)).toList();
    final liveInPeriod = inPeriod.where(live).toList();

    Decimal sum(Iterable<LedgerTx> l) => l.fold(Decimal.zero, (a, t) => a + t.amount);
    final payments = liveInPeriod.where((t) => _isPayment(t.kind)).toList();
    final debts = liveInPeriod.where((t) => t.kind == TxKind.debt).toList();
    final cmpLive = inCur.where((t) => cmp.contains(t.createdAt) && live(t));

    // الأرصدة في بداية الفترة ونهايتها (مجموع الديون الموجبة لكل زبون)
    final byCustomer = <String, List<LedgerTx>>{};
    for (final t in valid) {
      (byCustomer[t.customerId] ??= []).add(t);
    }
    final dayBefore = period.start.subtract(const Duration(days: 1));
    var opening = Decimal.zero, closing = Decimal.zero;
    final closingBal = <String, Decimal>{};
    var aging = AgingBuckets.zero;
    final endExclusive = DateTime(eff.year, eff.month, eff.day + 1);
    for (final e in byCustomer.entries) {
      final o = Ledger.balancesAsOf(e.value, dayBefore)[currency]?.balance ?? Decimal.zero;
      final c = Ledger.balancesAsOf(e.value, eff)[currency]?.balance ?? Decimal.zero;
      if (o > Decimal.zero) opening += o;
      if (c > Decimal.zero) closing += c;
      closingBal[e.key] = c;
      aging = aging + AgingBuckets.of(e.value.where((t) => t.createdAt.isBefore(endExclusive)), currency, eff);
    }

    // الأيام / الساعات / الأشهر
    Bucket bucketOf(DateTime at, Iterable<LedgerTx> l) {
      var c = Decimal.zero, d = Decimal.zero;
      var n = 0;
      for (final t in l) {
        n++;
        if (_isPayment(t.kind)) c += t.amount;
        if (t.kind == TxKind.debt) d += t.amount;
      }
      return Bucket(at, c, d, n);
    }

    final daily = <Bucket>[];
    if (period.kind != PeriodKind.year && period.days <= 92) {
      final byDay = <DateTime, List<LedgerTx>>{};
      for (final t in liveInPeriod) {
        (byDay[_d(t.createdAt)] ??= []).add(t);
      }
      for (var i = 0; i < period.days; i++) {
        final day = DateTime(period.start.year, period.start.month, period.start.day + i);
        daily.add(bucketOf(day, byDay[day] ?? const []));
      }
    }
    final monthly = <Bucket>[];
    if (period.kind == PeriodKind.year) {
      for (var m = 1; m <= 12; m++) {
        monthly.add(bucketOf(DateTime(period.start.year, m),
            liveInPeriod.where((t) => t.createdAt.month == m && t.createdAt.year == period.start.year)));
      }
    }
    final hourly = <Bucket>[];
    if (period.kind == PeriodKind.day) {
      for (var h = 0; h < 24; h++) {
        hourly.add(bucketOf(DateTime(period.start.year, period.start.month, period.start.day, h),
            liveInPeriod.where((t) => t.createdAt.hour == h)));
      }
    }

    // ملخص الحركات
    final kinds = <KindSummary>[
      KindSummary(TxKind.payment, payments.length, sum(payments)),
      KindSummary(TxKind.debt, debts.length, sum(debts)),
      for (final k in [TxKind.returned, TxKind.discount, TxKind.opening])
        () {
          final l = liveInPeriod.where((t) => t.kind == k);
          return KindSummary(k, l.length, sum(l));
        }(),
      () {
        final l = inPeriod.where((t) => t.kind == TxKind.voided).toList();
        return KindSummary(TxKind.voided, l.length, l.fold(Decimal.zero, (a, t) => a + (byId[t.voidedId]?.amount ?? t.amount)));
      }(),
    ];

    // الزبائن
    final paidBy = <String, (Decimal, int)>{};
    final debtBy = <String, (Decimal, int)>{};
    for (final t in payments) {
      final p = paidBy[t.customerId] ?? (Decimal.zero, 0);
      paidBy[t.customerId] = (p.$1 + t.amount, p.$2 + 1);
    }
    for (final t in debts) {
      final p = debtBy[t.customerId] ?? (Decimal.zero, 0);
      debtBy[t.customerId] = (p.$1 + t.amount, p.$2 + 1);
    }
    DateTime? lastPayment(String cid) {
      DateTime? last;
      for (final t in byCustomer[cid] ?? const <LedgerTx>[]) {
        if (_isPayment(t.kind) && live(t) && curOf(t) == currency && t.createdAt.isBefore(endExclusive)) last = t.createdAt;
      }
      return last;
    }

    List<CustomerStat> ranked(Map<String, (Decimal, int)> m) => (m.entries
            .map((e) => CustomerStat(e.key, custById[e.key], e.value.$1, e.value.$2, closingBal[e.key] ?? Decimal.zero, null))
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount)));
    final noPayment = closingBal.entries
        .where((e) => e.value > Decimal.zero && !paidBy.containsKey(e.key))
        .map((e) => CustomerStat(e.key, custById[e.key], e.value, 0, e.value, lastPayment(e.key)))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // المستخدمون
    final userMap = <String, (Decimal, Decimal, int)>{};
    for (final t in inPeriod) {
      final u = userMap[t.createdBy] ?? (Decimal.zero, Decimal.zero, 0);
      final isLive = live(t);
      userMap[t.createdBy] = (
        u.$1 + (isLive && _isPayment(t.kind) ? t.amount : Decimal.zero),
        u.$2 + (isLive && t.kind == TxKind.debt ? t.amount : Decimal.zero),
        u.$3 + 1,
      );
    }
    final users = userMap.entries.map((e) => UserStat(e.key, e.value.$1, e.value.$2, e.value.$3)).toList()
      ..sort((a, b) => b.ops.compareTo(a.ops));

    // الوعود التي تاريخها داخل الفترة
    var kept = 0, overdue = 0, upcoming = 0;
    for (final p in promises) {
      if (p.status == PromiseStatus.cancelled || !period.contains(p.promisedDate)) continue;
      if (p.status == PromiseStatus.kept) {
        kept++;
      } else if (p.isOverdue(today)) {
        overdue++;
      } else {
        upcoming++;
      }
    }

    // زبائن جدد: أول حركة لهم (بأي عملة) داخل الفترة
    var newCustomers = 0;
    for (final l in byCustomer.values) {
      if (effPeriod.contains(l.first.createdAt)) newCustomers++;
    }

    return PeriodReport._(
      period: period,
      comparisonPeriod: cmp,
      currency: currency,
      today: today,
      openingDebt: opening,
      closingDebt: closing,
      collected: sum(payments),
      collectedCount: payments.length,
      newDebt: sum(debts),
      debtCount: debts.length,
      prevCollected: sum(cmpLive.where((t) => _isPayment(t.kind))),
      prevNewDebt: sum(cmpLive.where((t) => t.kind == TxKind.debt)),
      daily: daily,
      monthly: monthly,
      hourly: hourly,
      kinds: kinds,
      promises: PromiseStats(kept, overdue, upcoming),
      topPayers: ranked(paidBy),
      topDebtors: ranked(debtBy),
      noPayment: noPayment,
      users: users,
      aging: aging,
      txs: inPeriod.reversed.toList(),
      newCustomers: newCustomers,
      avgPayDays: _avgPayDays(byCustomer.values, currency, effPeriod, byId),
    );
  }

  /// FIFO: كل سداد يغطي أقدم دين؛ متى اكتمل سداد دين داخل الفترة نسجل مدته (موزونة بالمبلغ)
  static int? _avgPayDays(Iterable<List<LedgerTx>> groups, String currency, ReportPeriod p, Map<String, LedgerTx> byId) {
    var weighted = 0.0, total = 0.0;
    for (final l in groups) {
      final queue = <(DateTime, Decimal)>[];
      for (final t in l) {
        final cur = t.kind == TxKind.voided ? (byId[t.voidedId]?.currency ?? t.currency) : t.currency;
        if (cur != currency) continue;
        var s = Ledger.signedAmount(t, byId);
        if (s > Decimal.zero) {
          queue.add((t.createdAt, s));
          continue;
        }
        var credit = -s;
        while (credit > Decimal.zero && queue.isNotEmpty) {
          final (date, rem) = queue.first;
          if (credit >= rem) {
            credit -= rem;
            queue.removeAt(0);
            if (p.contains(t.createdAt)) {
              final amt = rem.toDouble();
              weighted += t.createdAt.difference(date).inDays * amt;
              total += amt;
            }
          } else {
            queue[0] = (date, rem - credit);
            credit = Decimal.zero;
          }
        }
      }
    }
    return total == 0 ? null : (weighted / total).round();
  }

  /// السنوات المتاحة: من أول حركة في الفرع حتى السنة الحالية
  static List<int> years(List<LedgerTx> txs, DateTime today) {
    var first = today.year;
    for (final t in txs) {
      if (t.createdAt.year < first) first = t.createdAt.year;
    }
    return [for (var y = first; y <= today.year; y++) y];
  }

  /// تحصيل كل شهر في سنة (لنافذة الاختيار): 12 قيمة
  static List<Decimal> monthlyCollected(List<LedgerTx> txs, int year, String currency) {
    final valid = txs.where((t) => t.sync != SyncState.failed).toList();
    final voided = Ledger.voidedIds(valid);
    final out = List<Decimal>.filled(12, Decimal.zero);
    for (final t in valid) {
      if (t.createdAt.year != year || t.currency != currency || !_isPayment(t.kind) || voided.contains(t.id)) continue;
      out[t.createdAt.month - 1] += t.amount;
    }
    return out;
  }

  /// الأيام التي فيها حركات (لنقاط شريط الأسبوع)
  static Set<DateTime> activeDays(List<LedgerTx> txs, DateTime from, DateTime to) {
    final a = _d(from), b = DateTime(to.year, to.month, to.day + 1);
    return {
      for (final t in txs)
        if (t.sync != SyncState.failed && !t.createdAt.isBefore(a) && t.createdAt.isBefore(b)) _d(t.createdAt)
    };
  }
}
