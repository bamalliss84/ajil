// اختبارات محرك المزامنة بخادم وهمي يحاكي قواعد app.push_transactions و pull_changes
// التشغيل: cd app && flutter test
import 'package:ajil/data/local/db.dart';
import 'package:ajil/data/remote/remote_api.dart';
import 'package:ajil/data/repository.dart';
import 'package:ajil/data/sync_engine.dart';
import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Decimal d(String s) => Decimal.parse(s);

/// خادم وهمي: يحفظ الصفوف، يعطي server_seq، يحسب الإشارة، يكشف التكرار والفجوات
class FakeServer {
  final notices = <String, Map<String, dynamic>>{};
  int seq = 0;
  final customers = <String, Customer>{};
  final txs = <String, LedgerTx>{};
  final promises = <String, PaymentPromise>{};
  final rejectIds = <String>{};
  bool dropNextResponse = false; // يقبل الدفعة ثم «يضيع» الرد
  bool offline = false;

  Decimal signed(LedgerTx t) {
    if (t.kind == TxKind.voided) return -signed(txs[t.voidedId]!);
    return t.kind.isDebit ? t.amount : -t.amount;
  }
}

class FakeApi implements RemoteApi {
  FakeApi(this.server);
  final FakeServer server;

  void _net() {
    if (server.offline) throw const AjilError('offline', 'لا يوجد اتصال بالإنترنت');
  }

  @override
  Future<PushResponse> pushTransactions(String deviceId, List<Map<String, dynamic>> rows) async {
    _net();
    final results = <PushResult>[];
    for (final r in rows) {
      final id = r['id'] as String;
      if (server.txs.containsKey(id)) {
        results.add(PushResult(id, 'duplicate', server.txs[id]!.serverSeq, null));
        continue;
      }
      if (server.rejectIds.contains(id)) {
        results.add(PushResult(id, 'rejected', null, 'plan_customer_limit: وصلت لحد الباقة'));
        continue;
      }
      final tx = LedgerTx(
        id: id, storeId: 's', branchId: r['branch_id'], customerId: r['customer_id'], kind: TxKind.fromWire(r['kind']),
        amount: d(r['amount']), currency: r['currency'], voidedId: r['voided_id'], voidReason: r['void_reason'],
        createdBy: 'u', deviceId: deviceId, deviceSeq: r['device_seq'], createdAt: DateTime.parse(r['created_at']),
        serverSeq: ++server.seq, sync: SyncState.synced,
      );
      server.txs[id] = tx.withSync(SyncState.synced, serverSigned: server.signed(tx));
      results.add(PushResult(id, 'accepted', tx.serverSeq, null));
    }
    if (server.dropNextResponse) {
      server.dropNextResponse = false;
      throw const AjilError('offline', 'انقطع الاتصال');
    }
    final mine = server.txs.values.where((t) => t.deviceId == deviceId).map((t) => t.deviceSeq!).toSet();
    final maxSeq = mine.isEmpty ? 0 : mine.reduce((a, b) => a > b ? a : b);
    final gaps = [for (var i = 1; i <= maxSeq; i++) if (!mine.contains(i)) i];
    return PushResponse(results, gaps);
  }

  @override
  Future<void> saveCustomer(Customer c, {required bool isNew}) async {
    _net();
    server.customers[c.id] = Customer(
      id: c.id, storeId: c.storeId, branchId: c.branchId, name: c.name, phone: c.phone, defaultCurrency: c.defaultCurrency,
      status: c.status, updatedAt: DateTime.now(), serverSeq: ++server.seq,
    );
  }

  @override
  Future<void> savePromise(PaymentPromise p, {required bool isNew}) async {
    _net();
    server.promises[p.id] = PaymentPromise(
      id: p.id, storeId: p.storeId, branchId: p.branchId, customerId: p.customerId, promisedDate: p.promisedDate,
      amount: p.amount, currency: p.currency, status: p.status, serverSeq: ++server.seq,
    );
  }

  @override
  Future<PullPage> pull(String branchId, int since, {int limit = 500}) async {
    _net();
    final all = <(int, Object)>[
      ...server.customers.values.where((c) => c.serverSeq! > since).map((c) => (c.serverSeq!, c as Object)),
      ...server.txs.values.where((t) => t.serverSeq! > since).map((t) => (t.serverSeq!, t as Object)),
      ...server.promises.values.where((p) => p.serverSeq! > since).map((p) => (p.serverSeq!, p as Object)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final page = all.take(limit).toList();
    return PullPage(
      page.map((e) => e.$2).whereType<Customer>().toList(),
      page.map((e) => e.$2).whereType<LedgerTx>().toList(),
      page.map((e) => e.$2).whereType<PaymentPromise>().toList(),
      page.isEmpty ? since : page.last.$1,
    );
  }

  @override
  Future<void> saveNotice(Map<String, dynamic> row) async {
    _net();
    server.notices[row['id'] as String] = row;
  }

  @override
  Future<List<Map<String, dynamic>>> recentNotices(String branchId, DateTime since) async {
    _net();
    return server.notices.values.where((n) => n['branch_id'] == branchId).toList();
  }

  @override
  Future<List<Fingerprint>> fingerprints(String branchId) async {
    final m = <String, (int, Decimal)>{};
    for (final t in server.txs.values) {
      final k = '${t.customerId}|${t.currency}';
      final (n, s) = m[k] ?? (0, Decimal.zero);
      m[k] = (n + 1, s + t.serverSignedAmount!);
    }
    return m.entries.map((e) {
      final p = e.key.split('|');
      return Fingerprint(p[0], p[1], e.value.$1, e.value.$2.toString());
    }).toList();
  }
}

WorkSession session(String device, String letter) => WorkSession(
      storeId: 's0000000-0000-0000-0000-000000000000', storeName: 'بقالة', storePhone: '777', appUserId: 'u', userNo: 1,
      displayName: 'أحمد', isOwner: true, branch: const Branch('b', 'B1', 'الرئيسي'), deviceId: device, deviceLetter: letter,
      enabledCurrencies: const ['YER', 'SAR'], defaultCurrency: 'YER',
    );

class Phone {
  Phone(FakeServer server, String device, String letter)
      : db = AppDatabase(NativeDatabase.memory()),
        w = session(device, letter) {
    repo = LedgerRepository(db, w);
    api = FakeApi(server);
    sync = SyncEngine(db: db, api: api, branchId: 'b', deviceId: device, storeId: w.storeId);
  }
  final AppDatabase db;
  final WorkSession w;
  late final LedgerRepository repo;
  late final SyncEngine sync;
  late final FakeApi api;

  Future<Map<String, CurrencyBalance>> balancesOf(String customerId) async =>
      Ledger.balances(await repo.watchTxs(customerId).first);
}

void main() {
  late FakeServer server;
  setUp(() => server = FakeServer());

  test('العمل بدون نت ثم المزامنة: الحركات تُحفظ محلياً وتُرفع بالترتيب', () async {
    final a = Phone(server, 'devA', 'A');
    server.offline = true;
    final c = await a.repo.addCustomer(name: 'محمد', currency: 'YER', openingBalance: d('44500'));
    await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('3000'), currency: 'YER');
    final r1 = await a.sync.syncNow();
    expect(r1.error?.code, 'offline');
    expect(await a.sync.pendingCount(), 2);
    expect((await a.balancesOf(c.id))['YER']!.balance, d('47500'));

    server.offline = false;
    final r2 = await a.sync.syncNow();
    expect(r2.ok, isTrue);
    expect(await a.sync.pendingCount(), 0);
    expect(server.txs.length, 2);
    expect(server.txs.values.map((t) => t.deviceSeq).toSet(), {1, 2});
  });

  test('ضياع رد الخادم لا يكرر الحركة (التكرار يُكشف بالـ UUID)', () async {
    final a = Phone(server, 'devA', 'A');
    final c = await a.repo.addCustomer(name: 'علي', currency: 'YER');
    await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('100'), currency: 'YER');
    server.dropNextResponse = true;
    await a.sync.syncNow();
    expect(await a.sync.pendingCount(), 1); // الجوال لا يعرف أنها وصلت
    await a.sync.syncNow();
    expect(await a.sync.pendingCount(), 0);
    expect(server.txs.length, 1);
  });

  test('جوالان أوفلاين لنفس الزبون: الحركتان تُضافان والرصيد واحد في الجهتين', () async {
    final a = Phone(server, 'devA', 'A');
    final b = Phone(server, 'devB', 'B');
    final c = await a.repo.addCustomer(name: 'حسن', currency: 'YER');
    await a.sync.syncNow();
    await b.sync.syncNow(); // الجوال الثاني يستلم الزبون
    await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('1000'), currency: 'YER');
    await b.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('500'), currency: 'YER');
    await b.repo.addTx(customerId: c.id, kind: TxKind.payment, amount: d('200'), currency: 'YER');
    await a.sync.syncNow();
    await b.sync.syncNow();
    await a.sync.syncNow();
    expect((await a.balancesOf(c.id))['YER']!.balance, d('1300'));
    expect((await b.balancesOf(c.id))['YER']!.balance, d('1300'));
  });

  test('الرفض النهائي: الحركة «مرفوضة» ولا تدخل في الرصيد، والباقي يُقبل', () async {
    final a = Phone(server, 'devA', 'A');
    final c = await a.repo.addCustomer(name: 'سعيد', currency: 'YER');
    final bad = await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('999'), currency: 'YER');
    await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('50'), currency: 'YER');
    server.rejectIds.add(bad.id);
    await a.sync.syncNow();
    final txs = await a.repo.watchTxs(c.id).first;
    expect(txs.firstWhere((t) => t.id == bad.id).sync, SyncState.failed);
    expect(txs.firstWhere((t) => t.id == bad.id).syncError, contains('حد الباقة'));
    expect((await a.balancesOf(c.id))['YER']!.balance, d('50'));
  });

  test('فجوة في التسلسل: حركة ضاعت من الخادم تُعاد تلقائياً', () async {
    final a = Phone(server, 'devA', 'A');
    final c = await a.repo.addCustomer(name: 'خالد', currency: 'YER');
    final t1 = await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('10'), currency: 'YER');
    await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('20'), currency: 'YER');
    await a.sync.syncNow();
    server.txs.remove(t1.id); // محاكاة فقدان على الخادم (استرجاع نسخة قديمة مثلاً)
    await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('30'), currency: 'YER');
    await a.sync.syncNow(); // الخادم يبلغ عن الرقم 1 ناقصاً
    await a.sync.syncNow(); // يُعاد إرساله
    expect(server.txs.containsKey(t1.id), isTrue);
    expect(server.txs.length, 3);
  });

  test('الإلغاء: قيد عكسي بنفس مبلغ الأصل، ولا يُلغى مرتين', () async {
    final a = Phone(server, 'devA', 'A');
    final c = await a.repo.addCustomer(name: 'فاطمة', currency: 'YER');
    final t = await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('3000'), currency: 'YER');
    final txs = await a.repo.watchTxs(c.id).first;
    await a.repo.voidTx(t, 'خطأ في المبلغ', alreadyVoided: Ledger.voidedIds(txs));
    expect((await a.balancesOf(c.id))['YER']!.balance, d('0'));
    final after = await a.repo.watchTxs(c.id).first;
    expect(() => a.repo.voidTx(t, 'مرة ثانية', alreadyVoided: Ledger.voidedIds(after)), throwsA(isA<AjilError>()));
    await a.sync.syncNow();
    expect(server.txs.values.where((x) => x.kind == TxKind.voided).single.serverSignedAmount, d('-3000'));
  });

  test('مطابقة البصمات: اختلاف مع الخادم يؤدي لسحب كامل يصحح النسخة المحلية', () async {
    final a = Phone(server, 'devA', 'A');
    final c = await a.repo.addCustomer(name: 'ياسر', currency: 'YER');
    await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('100'), currency: 'YER');
    await a.sync.syncNow();
    // حركة على الخادم لم تصل لهذا الجوال (مؤشر متقدم خطأً)
    final b = Phone(server, 'devB', 'B');
    await b.sync.syncNow();
    await b.repo.addTx(customerId: c.id, kind: TxKind.payment, amount: d('40'), currency: 'YER');
    await b.sync.syncNow();
    await a.db.kvSet('cursor:b', '999999');
    final r = await a.sync.syncNow(verify: true);
    expect(r.fingerprintMismatch, isTrue);
    expect((await a.balancesOf(c.id))['YER']!.balance, d('60'));
  });

  test('أرقام الفواتير: بادئة الفرع والجهاز وتسلسل لكل جهاز', () async {
    final a = Phone(server, 'devA', 'A');
    final c = await a.repo.addCustomer(name: 'عمر', currency: 'YER');
    final t1 = await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('1'), currency: 'YER');
    final t2 = await a.repo.addTx(customerId: c.id, kind: TxKind.debt, amount: d('1'), currency: 'YER');
    expect(t1.invoiceNo, 'B1-A-0001');
    expect(t2.invoiceNo, 'B1-A-0002');
  });

  test('إرسال الأرصدة: الرصيد حتى التاريخ، السجل يُرفع، والجوال الثاني لا يكرر الإرسال', () async {
    final a = Phone(server, 'devA', 'A');
    final b = Phone(server, 'devB', 'B');
    final c1 = await a.repo.addCustomer(name: 'سالم', phone: '777111222', currency: 'YER');
    final c2 = await a.repo.addCustomer(name: 'فهد', phone: '777333444', currency: 'YER');
    await a.repo.addTx(customerId: c1.id, kind: TxKind.debt, amount: d('30000'), currency: 'YER');
    await a.repo.addTx(customerId: c2.id, kind: TxKind.debt, amount: d('5000'), currency: 'YER');
    final today = DateTime.now();

    final sel = await a.repo.selectForNotices(today, const NoticeFilter());
    expect(sel.recipients.map((r) => r.customer.name), ['سالم', 'فهد']);
    final batch = await a.repo.startNoticeBatch(today, const NoticeFilter(), BalanceNotices.defaultTemplate, sel);

    // أُغلق التطبيق بعد أول زبون ثم فُتح: الدفعة تُستأنف من الثاني
    await a.repo.markNoticeSent(batch, sel.recipients.first);
    final resumed = (await a.repo.loadNoticeBatch())!;
    expect(resumed.next, c2.id);
    expect((await a.repo.recipientsOf(resumed))[c2.id]!.balances['YER'], d('5000'));

    await a.sync.syncNow();
    expect(server.notices.length, 1);

    await b.sync.syncNow();
    await b.repo.refreshNotices(b.api);
    final selB = await b.repo.selectForNotices(today, const NoticeFilter());
    expect(selB.recipients.map((r) => r.customer.name), ['فهد']);
    expect(selB.recentlySent, 1);
  });
}
