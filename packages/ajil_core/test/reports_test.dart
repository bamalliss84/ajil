import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';

Decimal d(String s) => Decimal.parse(s);

Customer cust(String id, String name) =>
    Customer(id: id, storeId: 's', branchId: 'b', name: name, defaultCurrency: 'YER', updatedAt: DateTime(2026));

LedgerTx tx(String id, String c, TxKind k, String amount, DateTime at,
        {String cur = 'YER', String? voided, String by = 'u1', SyncState sync = SyncState.pending}) =>
    LedgerTx(
      id: id, storeId: 's', branchId: 'b', customerId: c, kind: k, amount: d(amount), currency: cur,
      voidedId: voided, voidReason: voided == null ? null : 'خطأ', createdBy: by, createdAt: at, sync: sync,
    );

PaymentPromise promise(String id, DateTime date, {PromiseStatus status = PromiseStatus.open}) =>
    PaymentPromise(id: id, storeId: 's', branchId: 'b', customerId: 'a', promisedDate: date, status: status);

void main() {
  final today = DateTime(2026, 11, 17, 21, 40);

  group('الفترة', () {
    test('الافتراضي الشهر الحالي، وهو جزئي حتى اليوم', () {
      final p = ReportPeriod.currentMonth(today);
      expect(p.kind, PeriodKind.month);
      expect(p.start, DateTime(2026, 11, 1));
      expect(p.end, DateTime(2026, 11, 30));
      expect(p.isPartial(today), isTrue);
      expect(p.effectiveEnd(today), DateTime(2026, 11, 17));
      expect(p.hasNext(today), isFalse);
      expect(p.prev().hasNext(today), isTrue);
    });

    test('مقارنة الشهر الجزئي بنفس عدد الأيام من السابق (1–17 أكتوبر)', () {
      final c = ReportPeriod.currentMonth(today).comparison(today);
      expect(c.start, DateTime(2026, 10, 1));
      expect(c.end, DateTime(2026, 10, 17));
    });

    test('مقارنة شهر مكتمل بالشهر السابق كاملاً، مع قص الأيام (31 مارس ← فبراير)', () {
      final c = ReportPeriod.month(2026, 3).comparison(today);
      expect(c.start, DateTime(2026, 2, 1));
      expect(c.end, DateTime(2026, 2, 28));
      final partial = ReportPeriod.month(2026, 3).comparison(DateTime(2026, 3, 31));
      expect(partial.end, DateTime(2026, 2, 28));
    });

    test('السنة الجارية تُقارن بالسابقة حتى نفس اليوم', () {
      final c = ReportPeriod.year(2026).comparison(today);
      expect(c.start, DateTime(2025, 1, 1));
      expect(c.end, DateTime(2025, 11, 17));
    });

    test('التنقل: يوم/شهر/سنة يعبر حدود السنة', () {
      expect(ReportPeriod.month(2026, 1).prev(), ReportPeriod.month(2025, 12));
      expect(ReportPeriod.day(DateTime(2026, 3, 1)).prev(), ReportPeriod.day(DateTime(2026, 2, 28)));
      expect(ReportPeriod.year(2026).next(), ReportPeriod.year(2027));
      expect(ReportPeriod.day(today).hasNext(today), isFalse);
    });

    test('من–إلى: يرتب التاريخين، والسابق بنفس الطول', () {
      final r = ReportPeriod.range(DateTime(2026, 11, 10), DateTime(2026, 11, 1));
      expect(r.start, DateTime(2026, 11, 1));
      expect(r.days, 10);
      expect(r.prev().start, DateTime(2026, 10, 22));
      expect(r.prev().end, DateTime(2026, 10, 31));
    });
  });

  group('تقرير الشهر', () {
    final customers = [cust('a', 'عبدالله باوزير'), cust('b', 'محمد سالم'), cust('c', 'خالد')];
    final txs = [
      tx('o1', 'a', TxKind.opening, '10000', DateTime(2026, 9, 1)),
      tx('o2', 'b', TxKind.opening, '5000', DateTime(2026, 9, 1)),
      // أكتوبر (1–17 للمقارنة + بعدها)
      tx('x1', 'a', TxKind.payment, '1000', DateTime(2026, 10, 5)),
      tx('x2', 'a', TxKind.debt, '4000', DateTime(2026, 10, 10)),
      tx('x3', 'b', TxKind.payment, '9000', DateTime(2026, 10, 25)), // بعد 17 أكتوبر — خارج المقارنة
      // نوفمبر
      tx('n1', 'a', TxKind.debt, '3000', DateTime(2026, 11, 2, 10), by: 'u1'),
      tx('n2', 'a', TxKind.payment, '2000', DateTime(2026, 11, 3, 19), by: 'u2'),
      tx('n3', 'b', TxKind.paymentFx, '1500', DateTime(2026, 11, 12, 20), by: 'u2'),
      tx('n4', 'b', TxKind.debt, '700', DateTime(2026, 11, 12, 9), by: 'u1'),
      tx('n5', 'a', TxKind.debt, '999', DateTime(2026, 11, 13), by: 'u1'),
      tx('n6', 'a', TxKind.voided, '1', DateTime(2026, 11, 14), voided: 'n5', by: 'u1'),
      tx('n7', 'b', TxKind.returned, '200', DateTime(2026, 11, 15)),
      tx('n8', 'c', TxKind.opening, '800', DateTime(2026, 11, 16)),
      tx('n9', 'a', TxKind.debt, '50', DateTime(2026, 11, 16), cur: 'SAR'), // عملة أخرى
      tx('f1', 'a', TxKind.payment, '7777', DateTime(2026, 11, 16), sync: SyncState.failed), // مرفوضة
    ];
    final promises = [
      promise('p1', DateTime(2026, 11, 5), status: PromiseStatus.kept),
      promise('p2', DateTime(2026, 11, 10)), // متأخر
      promise('p3', DateTime(2026, 11, 20)), // قادم
      promise('p4', DateTime(2026, 11, 21), status: PromiseStatus.cancelled),
      promise('p5', DateTime(2026, 12, 1)), // خارج الفترة
    ];
    final r = PeriodReport.build(
      period: ReportPeriod.currentMonth(today),
      today: today,
      currency: 'YER',
      customers: customers,
      txs: txs,
      promises: promises,
    );

    test('التحصيل يشمل السداد بعملة أخرى ويستبعد المرفوضة', () {
      expect(r.collected, d('3500'));
      expect(r.collectedCount, 2);
    });

    test('الديون الجديدة تستبعد الملغاة والعملات الأخرى', () {
      expect(r.newDebt, d('3700'));
      expect(r.debtCount, 2);
    });

    test('الديون بداية الفترة ونهايتها', () {
      // بداية نوفمبر: a = 10000-1000+4000 = 13000، b = 5000-9000 = −4000 (له) ← لا يُجمع
      expect(r.openingDebt, d('13000'));
      // نهاية: a = 13000+3000-2000 = 14000، b = -4000-1500+700-200 = −5000، c = 800
      expect(r.closingDebt, d('14800'));
    });

    test('المقارنة بـ 1–17 أكتوبر فقط', () {
      expect(r.prevCollected, d('1000'));
      expect(r.prevNewDebt, d('4000'));
      expect(r.collectedChange, 250);
      expect(r.debtChange, -8);
      expect(r.collectionRatio, 95);
    });

    test('الحركة اليومية: كل أيام الشهر وأفضل يوم', () {
      expect(r.daily.length, 30);
      expect(r.daily[1].debt, d('3000'));
      expect(r.daily[11].collected, d('1500'));
      expect(r.daily[11].debt, d('700'));
      expect(r.bestDay!.at, DateTime(2026, 11, 3));
      expect(r.monthly, isEmpty);
    });

    test('ملخص الحركات: الإلغاء بمبلغ الأصل', () {
      KindSummary k(TxKind kind) => r.kinds.firstWhere((x) => x.kind == kind);
      expect(k(TxKind.payment).count, 2);
      expect(k(TxKind.returned).amount, d('200'));
      expect(k(TxKind.opening).count, 1);
      expect(k(TxKind.voided).count, 1);
      expect(k(TxKind.voided).amount, d('999'));
    });

    test('الوعود: وُفي / متأخر / قادم ويُستبعد الملغى وما خارج الفترة', () {
      expect(r.promises.kept, 1);
      expect(r.promises.overdue, 1);
      expect(r.promises.upcoming, 1);
      expect(r.promises.total, 3);
    });

    test('الزبائن: الأكثر سداداً، الأكثر ديناً، وبلا سداد', () {
      expect(r.topPayers.map((c) => c.customerId), ['a', 'b']);
      expect(r.topPayers.first.customer!.name, 'عبدالله باوزير');
      expect(r.topDebtors.first.customerId, 'a');
      expect(r.noPayment.map((c) => c.customerId), ['c']);
      expect(r.noPayment.first.lastPaymentAt, isNull);
    });

    test('حسب المستخدم', () {
      final u1 = r.users.firstWhere((u) => u.userId == 'u1');
      final u2 = r.users.firstWhere((u) => u.userId == 'u2');
      expect(u1.debt, d('3700'));
      expect(u1.ops, 6); // n1 n4 n5 n6 n7 n8 (عملة اليمني فقط)
      expect(u2.collected, d('3500'));
    });

    test('أعمار الديون كما في نهاية الفترة، وزبائن جدد', () {
      expect(r.aging.total, d('14800'));
      expect(r.newCustomers, 1);
    });
  });

  group('اليوم والسنة', () {
    final txs = [
      tx('1', 'a', TxKind.debt, '10000', DateTime(2025, 3, 1)),
      tx('2', 'a', TxKind.payment, '10000', DateTime(2025, 3, 31)),
      tx('3', 'a', TxKind.debt, '6000', DateTime(2026, 2, 1)),
      tx('4', 'a', TxKind.payment, '6000', DateTime(2026, 2, 11)),
      tx('5', 'a', TxKind.debt, '500', DateTime(2026, 11, 17, 9, 5)),
      tx('6', 'a', TxKind.payment, '300', DateTime(2026, 11, 17, 20, 30)),
    ];

    test('عرض اليوم: حسب الساعة وآخر حركة والصافي', () {
      final r = PeriodReport.build(
          period: ReportPeriod.day(today), today: today, currency: 'YER', customers: const [], txs: txs);
      expect(r.hourly.length, 24);
      expect(r.hourly[9].debt, d('500'));
      expect(r.hourly[20].collected, d('300'));
      expect(r.lastTxAt, DateTime(2026, 11, 17, 20, 30));
      expect(r.txs.first.id, '6');
      expect(r.net, d('-200'));
      expect(r.comparisonPeriod, ReportPeriod.day(DateTime(2026, 11, 16)));
    });

    test('عرض السنة: 12 شهراً، أفضل شهر، متوسط مدة السداد', () {
      final r = PeriodReport.build(
          period: ReportPeriod.year(2026), today: today, currency: 'YER', customers: const [], txs: txs);
      expect(r.monthly.length, 12);
      expect(r.monthly[1].collected, d('6000'));
      expect(r.bestMonth!.at, DateTime(2026, 2));
      expect(r.daily, isEmpty);
      expect(r.avgPayDays, 10); // دين 1 فبراير سُدد 11 فبراير (دين 2025 خارج الفترة)
      expect(r.prevCollected, d('10000'));
    });

    test('السنوات المتاحة وتحصيل الأشهر للنافذة والأيام النشطة', () {
      expect(PeriodReport.years(txs, today), [2025, 2026]);
      final m = PeriodReport.monthlyCollected(txs, 2026, 'YER');
      expect(m[1], d('6000'));
      expect(m[10], d('300'));
      final days = PeriodReport.activeDays(txs, DateTime(2026, 11, 14), DateTime(2026, 11, 20));
      expect(days, {DateTime(2026, 11, 17)});
    });
  });
}
