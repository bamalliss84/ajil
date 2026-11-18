import 'dart:async';

import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:test/test.dart';

Decimal d(String s) => Decimal.parse(s);

final _cust = Customer(
  id: 'c1', storeId: 's', branchId: 'b', name: 'محمد سالم', defaultCurrency: 'YER', updatedAt: DateTime(2026),
  creditLimit: d('50000'),
);

LedgerTx tx(String id, TxKind k, String amount,
        {String cur = 'YER', String? voided, DateTime? at, String by = 'u1', SyncState sync = SyncState.pending}) =>
    LedgerTx(
      id: id, storeId: 's', branchId: 'b', customerId: 'c1', kind: k, amount: d(amount), currency: cur,
      voidedId: voided, voidReason: voided == null ? null : 'خطأ', createdBy: by,
      createdAt: at ?? DateTime(2026, 11, 1), sync: sync,
    );

void main() {
  group('الأرصدة (مطابقة لاختبارات الخادم)', () {
    final txs = [
      tx('1', TxKind.opening, '44500', at: DateTime(2026, 11, 1)),
      tx('2', TxKind.debt, '3000', at: DateTime(2026, 11, 2)),
      tx('3', TxKind.payment, '20000', at: DateTime(2026, 11, 3)),
      tx('4', TxKind.debt, '120', cur: 'SAR', at: DateTime(2026, 11, 4)),
      tx('5', TxKind.voided, '1', voided: '2', at: DateTime(2026, 11, 5)),
    ];

    test('رصيد اليمني بعد إلغاء دين 3,000 = 24,500', () {
      final b = Ledger.balances(txs);
      expect(b['YER']!.balance, d('24500'));
      expect(b['SAR']!.balance, d('120'));
    });

    test('الإلغاء يأخذ مبلغ الأصل وعملته، لا ما أرسله الجوال', () {
      final byId = {for (final t in txs) t.id: t};
      expect(Ledger.signedAmount(txs[4], byId), d('-3000'));
    });

    test('الحركة المرفوضة من الخادم لا تُحسب', () {
      final b = Ledger.balances([...txs, tx('6', TxKind.debt, '999', sync: SyncState.failed)]);
      expect(b['YER']!.balance, d('24500'));
    });

    test('قيمة الخادم تُعتمد بعد المزامنة', () {
      final synced = tx('7', TxKind.debt, '100', sync: SyncState.synced).withSync(SyncState.synced, serverSigned: d('100'));
      expect(Ledger.balances([synced])['YER']!.balance, d('100'));
    });
  });

  group('صلاحية الإلغاء', () {
    final t = tx('1', TxKind.debt, '100', by: 'emp', at: DateTime(2026, 11, 1, 10));
    test('المالك يلغي أي حركة', () {
      expect(Ledger.canVoid(t, isOwner: true, userId: 'owner', alreadyVoided: {}), isNull);
    });
    test('الموظف لا يلغي حركة غيره', () {
      expect(Ledger.canVoid(t, isOwner: false, userId: 'other', alreadyVoided: {}), isNotNull);
    });
    test('الموظف يلغي حركته خلال 24 ساعة فقط', () {
      expect(Ledger.canVoid(t, isOwner: false, userId: 'emp', alreadyVoided: {}, now: DateTime(2026, 11, 1, 20)), isNull);
      expect(Ledger.canVoid(t, isOwner: false, userId: 'emp', alreadyVoided: {}, now: DateTime(2026, 11, 3)), isNotNull);
    });
    test('لا إلغاء مرتين ولا إلغاء للإلغاء', () {
      expect(Ledger.canVoid(t, isOwner: true, userId: 'o', alreadyVoided: {'1'}), isNotNull);
      expect(Ledger.canVoid(tx('9', TxKind.voided, '1', voided: '1'), isOwner: true, userId: 'o', alreadyVoided: {}), isNotNull);
    });
  });

  group('كشف الحساب', () {
    final txs = [
      tx('1', TxKind.opening, '44500', at: DateTime(2026, 11, 1)),
      tx('2', TxKind.debt, '3000', at: DateTime(2026, 11, 10)),
      tx('3', TxKind.payment, '20000', at: DateTime(2026, 11, 12)),
    ];
    test('التحليلي: الأحدث أولاً مع رصيد تراكمي', () {
      final s = Statement.build(_cust, txs).byCurrency['YER']!;
      expect(s.lines.first.tx.id, '3');
      expect(s.lines.first.runningBalance, d('27500'));
      expect(s.lines.last.runningBalance, d('44500'));
      expect(s.closingBalance, d('27500'));
    });
    test('فترة: الرصيد قبل بداية الفترة يظهر كرصيد افتتاحي', () {
      final s = Statement.build(_cust, txs, from: DateTime(2026, 11, 5)).byCurrency['YER']!;
      expect(s.openingBalance, d('44500'));
      expect(s.lines.length, 2);
      expect(s.closingBalance, d('27500'));
    });
  });

  group('سقف الدين', () {
    test('يتجاوز السقف', () {
      final b = Ledger.balances([tx('1', TxKind.debt, '45000')]);
      expect(Ledger.exceedsLimit(_cust, b, d('6000'), 'YER'), isTrue);
      expect(Ledger.exceedsLimit(_cust, b, d('5000'), 'YER'), isFalse);
      expect(Ledger.exceedsLimit(_cust, b, d('999999'), 'SAR'), isFalse);
    });
  });

  group('المبالغ', () {
    const f = MoneyFormat();
    test('تنسيق', () {
      expect(f.amount(d('45250'), 'YER'), '45,250');
      expect(f.amount(d('120.5'), 'SAR'), '120.50');
      expect(f.amount(d('120'), 'SAR'), '120');
      expect(f.amount(d('-3000'), 'YER', signed: true), '− 3,000');
      expect(const MoneyFormat(arabicIndicDigits: true).amount(d('1250'), 'YER'), '١٬٢٥٠');
    });
    test('قراءة الإدخال', () {
      expect(MoneyFormat.parse('١٢٫٥'), d('12.5'));
      expect(MoneyFormat.parse('12,500'), d('12500'));
      expect(MoneyFormat.parse('abc'), isNull);
    });
  });

  group('الهوية والأخطاء', () {
    test('توحيد الرقم والبريد الداخلي', () {
      expect(Identity.normalizePhone('+967 777 123 456'), '777123456');
      expect(Identity.normalizePhone('٠٧٧٧١٢٣٤٥٦'), '777123456');
      expect(Identity.derivedEmail('777123456', 2), 'u2.777123456@users.ajil.app');
    });
    test('قراءة خطأ الخادم', () {
      final e = AjilError.parse('PostgrestException(message: plan_customer_limit: وصلت لحد الباقة (200 زبون), code: P0001)');
      expect(e.code, 'plan_customer_limit');
      expect(AjilError.parse({'code': 'otp_wrong', 'message': 'الرمز غير صحيح'}).message, 'الرمز غير صحيح');
      expect(AjilError.parse('SocketException: Failed host lookup').code, 'offline');
      expect(AjilError.parse('offline: x').isPermanent, isFalse);
    });
    test('النص الموقَّع مطابق للخادم', () {
      final s = canonicalString(method: 'post', path: '/p', deviceId: 'd', timestamp: '1', nonce: 'n', body: 'x');
      // sha256("x") — نفس القيمة في shared.test.ts
      expect(s, 'POST\n/p\nd\n1\nn\n2d711642b726b04401627ca9fbac32f5c8530fb1903cc4db02258717921a4881');
    });
  });

  group('أعمار الديون (FIFO)', () {
    final today = DateTime(2026, 12, 31);
    final txs = [
      tx('1', TxKind.debt, '1000', at: DateTime(2026, 9, 1)), // 121 يوماً
      tx('2', TxKind.debt, '500', at: DateTime(2026, 11, 20)), // 41 يوماً
      tx('3', TxKind.debt, '200', at: DateTime(2026, 12, 25)), // 6 أيام
      tx('4', TxKind.payment, '1200', at: DateTime(2026, 12, 26)),
    ];
    test('السداد يغطي أقدم دين أولاً', () {
      final a = AgingBuckets.of(txs, 'YER', today);
      expect(a.over90, d('0'));
      expect(a.d30to60, d('300'));
      expect(a.under30, d('200'));
      expect(a.total, d('500'));
      expect(AgingBuckets.oldestDays(txs, 'YER', today), 41);
    });
    test('لا دين = لا عمر', () {
      expect(AgingBuckets.oldestDays([tx('1', TxKind.debt, '5'), tx('2', TxKind.payment, '5')], 'YER', today), isNull);
    });
  });

  group('التفقيط', () {
    test('أعداد', () {
      expect(ArabicWords.integer(30000), 'ثلاثون ألف');
      expect(ArabicWords.integer(1000), 'ألف');
      expect(ArabicWords.integer(2000), 'ألفان');
      expect(ArabicWords.integer(5000), 'خمسة آلاف');
      expect(ArabicWords.integer(45250), 'خمسة وأربعون ألف ومائتان وخمسون');
      expect(ArabicWords.integer(1250000), 'مليون ومائتان وخمسون ألف');
      expect(ArabicWords.integer(311), 'ثلاثمائة وأحد عشر');
    });
    test('مبلغ بالعملة', () {
      expect(ArabicWords.amount(d('30000'), 'YER'), 'ثلاثون ألف ريال يمني فقط لا غير');
      expect(ArabicWords.amount(d('120.50'), 'SAR'), 'مائة وعشرون ريال سعودي وخمسون هللة فقط لا غير');
    });
  });

  group('إرسال الأرصدة حتى تاريخ', () {
    Customer cust(String id, {String? phone = '777000000', CustomerStatus st = CustomerStatus.active}) => Customer(
        id: id, storeId: 's', branchId: 'b', name: 'زبون $id', phone: phone, defaultCurrency: 'YER',
        updatedAt: DateTime(2026), status: st);
    LedgerTx t(String id, String c, TxKind k, String amount, DateTime at, {String cur = 'YER', String? voided}) => LedgerTx(
        id: id, storeId: 's', branchId: 'b', customerId: c, kind: k, amount: d(amount), currency: cur,
        voidedId: voided, createdBy: 'u', createdAt: at);
    const f = MoneyFormat();

    final txs = {
      'a': [
        t('a1', 'a', TxKind.debt, '30000', DateTime(2026, 11, 10, 9)),
        t('a2', 'a', TxKind.payment, '10000', DateTime(2026, 11, 30, 23, 59)), // آخر اليوم: يُحسب
        t('a3', 'a', TxKind.payment, '5000', DateTime(2026, 12, 1, 0, 1)), // بعد التاريخ: لا يُحسب
      ],
      'b': [t('b1', 'b', TxKind.debt, '500', DateTime(2026, 11, 2)), t('b2', 'b', TxKind.debt, '120', DateTime(2026, 11, 2), cur: 'SAR')],
      'c': [t('c1', 'c', TxKind.debt, '9000', DateTime(2026, 11, 2))],
      'd': [t('d1', 'd', TxKind.payment, '700', DateTime(2026, 11, 2))], // له رصيد
      'e': [t('e1', 'e', TxKind.debt, '4000', DateTime(2026, 11, 2)), t('e2', 'e', TxKind.voided, '4000', DateTime(2026, 12, 3), voided: 'e1')],
      'g': [t('g1', 'g', TxKind.debt, '8000', DateTime(2026, 11, 2))],
    };
    final customers = [cust('a'), cust('b'), cust('c', phone: null), cust('d'), cust('e'), cust('f'), cust('g', st: CustomerStatus.archived)];
    final asOf = DateTime(2026, 11, 30);

    test('الرصيد حتى نهاية اليوم المحدد فقط', () {
      expect(Ledger.balancesAsOf(txs['a']!, asOf)['YER']!.balance, d('20000'));
      // إلغاء بعد التاريخ: الدين كان قائماً في ذلك اليوم
      expect(Ledger.balancesAsOf(txs['e']!, asOf)['YER']!.balance, d('4000'));
      expect(Ledger.balancesAsOf(txs['e']!, DateTime(2026, 12, 3))['YER']!.balance, d('0'));
    });

    test('الفرز: المدينون فقط، بلا رقم يُعرضون منفصلين، المؤرشف لا يدخل، الأكبر أولاً', () {
      final sel = BalanceNotices.select(customers: customers, txsByCustomer: txs, asOf: asOf, now: DateTime(2026, 12, 1));
      expect(sel.recipients.map((r) => r.customer.id), ['a', 'e', 'b']);
      expect(sel.noPhone.map((c) => c.id), ['c']);
      expect(sel.totals['YER'], d('24500'));
      expect(sel.totals['SAR'], d('120'));
    });

    test('شروط: أقل مبلغ، عملة واحدة، من لهم رصيد، المرسَل لهم مؤخراً', () {
      final now = DateTime(2026, 12, 1);
      var sel = BalanceNotices.select(customers: customers, txsByCustomer: txs, asOf: asOf, now: now,
          filter: NoticeFilter(minAmount: d('5000')));
      expect(sel.recipients.map((r) => r.customer.id), ['a']);
      sel = BalanceNotices.select(customers: customers, txsByCustomer: txs, asOf: asOf, now: now,
          filter: const NoticeFilter(currency: 'SAR'));
      expect(sel.recipients.single.balances, {'SAR': d('120')});
      sel = BalanceNotices.select(customers: customers, txsByCustomer: txs, asOf: asOf, now: now,
          filter: const NoticeFilter(debtorsOnly: false));
      expect(sel.recipients.map((r) => r.customer.id), contains('d'));
      sel = BalanceNotices.select(customers: customers, txsByCustomer: txs, asOf: asOf, now: now,
          lastSent: {'a': DateTime(2026, 11, 28)});
      expect(sel.recipients.map((r) => r.customer.id), isNot(contains('a')));
      expect(sel.recentlySent, 1);
    });

    test('نص الرسالة: عدة عملات، عليكم/لكم، وحذف سطر الرابط إن لم يوجد', () {
      final r = NoticeRecipient(cust('b'), {'YER': d('500'), 'SAR': d('-20')});
      final msg = BalanceNotices.render('السلام عليكم {الاسم}\nرصيدكم حتى {التاريخ}: {الرصيد}\nكشفكم: {الرابط}',
          r: r, store: 'بقالة', asOf: asOf, f: f);
      expect(msg, 'السلام عليكم زبون b\nرصيدكم حتى 2026/11/30: ${f.amount(d('500'), 'YER', withSymbol: true)} عليكم و '
          '${f.amount(d('20'), 'SAR', withSymbol: true)} لكم');
    });

    test('الدفعة تُحفظ وتُستأنف', () {
      final b = NoticeBatch(id: 'x', asOf: asOf, template: 'T', filter: const NoticeFilter(), queue: ['a', 'b', 'c'])
        ..sent.add('a')
        ..skipped.add('b');
      final back = NoticeBatch.fromJson(b.toJson());
      expect(back.next, 'c');
      expect(back.done, 2);
      expect(back.asOf, asOf);
      back.sent.add('c');
      expect(back.finished, isTrue);
    });
  });

  group('الفتح بدون نت', () {
    test('الجلسة تُحفظ وتُستعاد كما هي', () {
      const w = WorkSession(
        storeId: 's1', storeName: 'بقالة', storePhone: '777000111', appUserId: 'u1', userNo: 2,
        displayName: 'خالد', isOwner: false, branch: Branch('b1', 'B1', 'الرئيسي'), deviceId: 'd1',
        deviceLetter: 'B', enabledCurrencies: ['YER', 'SAR'], defaultCurrency: 'YER',
      );
      final back = WorkSession.fromJson(Map<String, dynamic>.from(w.toJson()));
      expect(back.toJson(), w.toJson());
      expect(back.invoicePrefix(), 'B1-B-');
    });

    test('أخطاء الوصول تُميَّز عن رفض الخادم', () {
      expect(AjilError.isConnectivity(TimeoutException('x')), isTrue);
      expect(
          AjilError.isConnectivity(
              'AuthRetryableFetchException(message: ClientException with SocketException: Connection refused)'),
          isTrue);
      expect(AjilError.isConnectivity('Failed host lookup: x.supabase.co'), isTrue);
      expect(AjilError.isConnectivity('device_invalid: الجهاز ملغى'), isFalse);
      expect(AjilError.isConnectivity('JWT expired'), isFalse);
    });
  });
}
