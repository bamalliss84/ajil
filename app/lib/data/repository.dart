import 'dart:convert';

import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'local/db.dart';
import 'local/mappers.dart';
import 'remote/remote_api.dart';

/// زبون مع أرصدته — لعرض القوائم
class CustomerWithBalance {
  final Customer customer;
  final Map<String, CurrencyBalance> balances;
  final bool hasPending;
  final DateTime? lastTxAt;
  const CustomerWithBalance(this.customer, this.balances, this.hasPending, this.lastTxAt);

  Decimal balanceIn(String currency) => balances[currency]?.balance ?? Decimal.zero;
  bool get hasDebt => balances.values.any((b) => b.balance > Decimal.zero);
}

/// كل الكتابة تمر من هنا: تُحفظ محلياً فوراً (تعمل بدون نت) ثم يرفعها محرك المزامنة
class LedgerRepository {
  LedgerRepository(this.db, this.session);
  final AppDatabase db;
  final WorkSession session;
  static const _uuid = Uuid();

  String get _branch => session.branch.id;

  // ---------------- قراءة (Streams تتحدث تلقائياً) ----------------
  /// الزبائن مع أرصدتهم — يتحدث عند أي تغيير في الزبائن أو الحركات
  Stream<List<CustomerWithBalance>> watchCustomers({bool includeArchived = false}) async* {
    yield await _loadCustomers(includeArchived);
    await for (final _ in db.tableUpdates(TableUpdateQuery.onAllTables([db.localCustomers, db.localTxs]))) {
      yield await _loadCustomers(includeArchived);
    }
  }

  Future<List<CustomerWithBalance>> _loadCustomers(bool includeArchived) async {
    final customers = await (db.select(db.localCustomers)..where((c) => c.branchId.equals(_branch))).get();
    final txs = (await (db.select(db.localTxs)..where((t) => t.branchId.equals(_branch))).get())
        .map((r) => r.toModel())
        .toList();
    final byCustomer = <String, List<LedgerTx>>{};
    for (final t in txs) {
      (byCustomer[t.customerId] ??= []).add(t);
    }
    return customers
        .map((r) => r.toModel())
        .where((c) => includeArchived || c.status != CustomerStatus.archived)
        .map((c) {
      final list = byCustomer[c.id] ?? const <LedgerTx>[];
      DateTime? last;
      for (final t in list) {
        if (last == null || t.createdAt.isAfter(last)) last = t.createdAt;
      }
      return CustomerWithBalance(c, Ledger.balances(list), list.any((t) => t.sync == SyncState.pending), last);
    }).toList()
      ..sort((a, b) => (b.lastTxAt ?? DateTime(2000)).compareTo(a.lastTxAt ?? DateTime(2000)));
  }

  Stream<Customer?> watchCustomer(String id) =>
      (db.select(db.localCustomers)..where((c) => c.id.equals(id))).watchSingleOrNull().map((r) => r?.toModel());

  Stream<List<LedgerTx>> watchTxs(String customerId) =>
      (db.select(db.localTxs)
            ..where((t) => t.customerId.equals(customerId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch()
          .map((rows) => rows.map((r) => r.toModel()).toList());

  Stream<List<LedgerTx>> watchBranchTxs() =>
      (db.select(db.localTxs)..where((t) => t.branchId.equals(_branch))).watch().map((r) => r.map((x) => x.toModel()).toList());

  Stream<List<LedgerTx>> watchUnsynced() =>
      (db.select(db.localTxs)
            ..where((t) => t.branchId.equals(_branch) & t.sync.isIn(const ['pending', 'failed']))
            ..orderBy([(t) => OrderingTerm.asc(t.deviceSeq)]))
          .watch()
          .map((r) => r.map((x) => x.toModel()).toList());

  Stream<List<PaymentPromise>> watchPromises({String? customerId, bool openOnly = true}) {
    final q = db.select(db.localPromises)..where((p) => p.branchId.equals(_branch));
    if (customerId != null) q.where((p) => p.customerId.equals(customerId));
    if (openOnly) q.where((p) => p.status.equals('open'));
    q.orderBy([(p) => OrderingTerm.asc(p.promisedDate)]);
    return q.watch().map((r) => r.map((x) => x.toModel()).toList());
  }

  // ---------------- كتابة ----------------
  Future<Customer> addCustomer({
    required String name,
    String? phone,
    String? address,
    String? notes,
    required String currency,
    Decimal? creditLimit,
    Decimal? openingBalance,
    DateTime? openingDate,
    String? openingNote,
  }) async {
    final c = Customer(
      id: _uuid.v4(),
      storeId: session.storeId,
      branchId: _branch,
      name: name.trim(),
      phone: phone?.trim().isEmpty ?? true ? null : phone!.trim(),
      address: address?.trim().isEmpty ?? true ? null : address!.trim(),
      notes: notes?.trim().isEmpty ?? true ? null : notes!.trim(),
      defaultCurrency: currency,
      creditLimit: creditLimit,
      creditLimitCurrency: creditLimit == null ? null : currency,
      updatedAt: DateTime.now(),
    );
    await db.transaction(() async {
      await db.into(db.localCustomers).insert(c.toCompanion(dirty: true));
      if (openingBalance != null && openingBalance > Decimal.zero) {
        await _insertTx(
          customerId: c.id,
          kind: TxKind.opening,
          amount: openingBalance,
          currency: currency,
          description: openingNote ?? 'رصيد من الدفتر الورقي',
          createdAt: openingDate,
        );
      }
    });
    return c;
  }

  Future<void> updateCustomer(Customer c) =>
      (db.update(db.localCustomers)..where((t) => t.id.equals(c.id))).write(c.toCompanion(dirty: true));

  Future<LedgerTx> addTx({
    required String customerId,
    required TxKind kind,
    required Decimal amount,
    required String currency,
    String? description,
    String? invoiceNo,
    DateTime? dueDate,
    Decimal? fxPaidAmount,
    String? fxPaidCurrency,
    Decimal? fxRate,
  }) async {
    if (amount <= Decimal.zero) throw const AjilError('amount_invalid', 'المبلغ يجب أن يكون أكبر من صفر');
    if (!session.enabledCurrencies.contains(currency)) {
      throw const AjilError('currency_not_enabled', 'العملة غير مفعلة في البقالة');
    }
    final inv = invoiceNo ?? (kind == TxKind.debt ? await nextInvoiceNo() : null);
    return db.transaction(() => _insertTx(
          customerId: customerId,
          kind: kind,
          amount: amount,
          currency: currency,
          description: description,
          invoiceNo: inv,
          dueDate: dueDate,
          fxPaidAmount: fxPaidAmount,
          fxPaidCurrency: fxPaidCurrency,
          fxRate: fxRate,
        ));
  }

  /// الإلغاء: قيد عكسي بسبب إلزامي — نفس قواعد الخادم
  Future<LedgerTx> voidTx(LedgerTx original, String reason, {required Set<String> alreadyVoided}) async {
    final why = Ledger.canVoid(original,
        isOwner: session.isOwner, userId: session.appUserId, alreadyVoided: alreadyVoided);
    if (why != null) throw AjilError('void_denied', why);
    if (reason.trim().isEmpty) throw const AjilError('void_reason_required', 'سبب الإلغاء مطلوب');
    return db.transaction(() => _insertTx(
          customerId: original.customerId,
          kind: TxKind.voided,
          amount: original.amount,
          currency: original.currency,
          voidedId: original.id,
          voidReason: reason.trim(),
          description: 'إلغاء ${original.kind.labelAr}${original.invoiceNo == null ? '' : ' ${original.invoiceNo}'}',
        ));
  }

  Future<PaymentPromise> addPromise({
    required String customerId,
    required DateTime date,
    Decimal? amount,
    String? currency,
    String? note,
    bool remindDayBefore = false,
    bool remindCustomer = false,
  }) async {
    final p = PaymentPromise(
      id: _uuid.v4(),
      storeId: session.storeId,
      branchId: _branch,
      customerId: customerId,
      promisedDate: DateTime(date.year, date.month, date.day),
      amount: amount,
      currency: amount == null ? null : currency,
      note: note,
      remindDayBefore: remindDayBefore,
      remindCustomer: remindCustomer,
    );
    await db.into(db.localPromises).insert(p.toCompanion(dirty: true));
    return p;
  }

  Future<void> setPromiseStatus(String id, PromiseStatus s) => (db.update(db.localPromises)..where((p) => p.id.equals(id)))
      .write(LocalPromisesCompanion(status: Value(s.name), dirty: const Value(true)));

  Future<String> nextInvoiceNo() async {
    final n = await db.nextCounter('invoice:${session.branch.id}:${session.deviceLetter}');
    return '${session.invoicePrefix()}${n.toString().padLeft(4, '0')}';
  }

  /// إعادة محاولة حركة رفضها الخادم بخطأ مؤقت
  Future<void> retry(String txId) => (db.update(db.localTxs)..where((t) => t.id.equals(txId)))
      .write(const LocalTxsCompanion(sync: Value('pending'), syncError: Value(null)));

  Future<LedgerTx> _insertTx({
    required String customerId,
    required TxKind kind,
    required Decimal amount,
    required String currency,
    String? description,
    String? invoiceNo,
    DateTime? dueDate,
    Decimal? fxPaidAmount,
    String? fxPaidCurrency,
    Decimal? fxRate,
    String? voidedId,
    String? voidReason,
    DateTime? createdAt,
  }) async {
    final seq = await db.nextCounter('device_seq:${session.deviceId}');
    final t = LedgerTx(
      id: _uuid.v4(),
      storeId: session.storeId,
      branchId: _branch,
      customerId: customerId,
      kind: kind,
      amount: amount,
      currency: currency,
      fxPaidAmount: fxPaidAmount,
      fxPaidCurrency: fxPaidCurrency,
      fxRate: fxRate,
      voidedId: voidedId,
      voidReason: voidReason,
      description: description,
      invoiceNo: invoiceNo,
      dueDate: dueDate,
      createdBy: session.appUserId,
      deviceId: session.deviceId,
      deviceSeq: seq,
      createdAt: createdAt ?? DateTime.now(),
      sync: SyncState.pending,
    );
    await db.into(db.localTxs).insert(t.toCompanion());
    return t;
  }

  // ---------------- إرسال الأرصدة حتى تاريخ ----------------
  static const _batchKey = 'notice_batch';

  /// آخر رسالة رصيد لكل زبون في الفرع (من هذا الجهاز أو غيره بعد الجلب)
  Future<Map<String, DateTime>> lastNoticeByCustomer() async {
    final rows = await (db.select(db.localNotices)..where((n) => n.branchId.equals(_branch))).get();
    final m = <String, DateTime>{};
    for (final r in rows) {
      final cur = m[r.customerId];
      if (cur == null || r.sentAt.isAfter(cur)) m[r.customerId] = r.sentAt;
    }
    return m;
  }

  /// يجلب ما أرسلته الأجهزة الأخرى خلال 60 يوماً (إن وُجد نت) — لمنع إرسال مكرر للزبون
  Future<void> refreshNotices(RemoteApi api) async {
    try {
      final rows = await api.recentNotices(_branch, DateTime.now().subtract(const Duration(days: 60)));
      await db.batch((b) {
        for (final r in rows) {
          b.insert(db.localNotices, noticeFromServer(r), mode: InsertMode.insertOrIgnore);
        }
      });
    } on AjilError {
      // بدون نت: نكمل بالسجل المحلي
    }
  }

  Future<(List<Customer>, Map<String, List<LedgerTx>>)> _branchData() async {
    final customers = (await (db.select(db.localCustomers)..where((c) => c.branchId.equals(_branch))).get())
        .map((r) => r.toModel())
        .toList();
    final byCustomer = <String, List<LedgerTx>>{};
    for (final r in await (db.select(db.localTxs)..where((t) => t.branchId.equals(_branch))).get()) {
      byCustomer.putIfAbsent(r.customerId, () => []).add(r.toModel());
    }
    return (customers, byCustomer);
  }

  /// من سيستلم رسالة الرصيد حتى [asOf] حسب الشروط
  Future<NoticeSelection> selectForNotices(DateTime asOf, NoticeFilter filter) async {
    final (customers, txs) = await _branchData();
    return BalanceNotices.select(
      customers: customers,
      txsByCustomer: txs,
      asOf: asOf,
      filter: filter,
      lastSent: await lastNoticeByCustomer(),
    );
  }

  /// مستلمو دفعة محفوظة (يُعاد حساب الرصيد حتى تاريخ الدفعة نفسه)
  Future<Map<String, NoticeRecipient>> recipientsOf(NoticeBatch b) async {
    final (customers, txs) = await _branchData();
    final queued = b.queue.toSet();
    final f = b.filter;
    final sel = BalanceNotices.select(
      customers: customers.where((c) => queued.contains(c.id)),
      txsByCustomer: txs,
      asOf: b.asOf,
      filter: NoticeFilter(debtorsOnly: f.debtorsOnly, minAmount: f.minAmount, currency: f.currency, skipSentWithinDays: null),
    );
    return {for (final r in sel.recipients) r.customer.id: r};
  }

  Future<NoticeBatch> startNoticeBatch(DateTime asOf, NoticeFilter filter, String template, NoticeSelection sel) async {
    final b = NoticeBatch(
      id: _uuid.v4(),
      asOf: asOf,
      template: template,
      filter: filter,
      queue: sel.recipients.map((r) => r.customer.id).toList(),
    );
    await saveNoticeBatch(b);
    return b;
  }

  Future<NoticeBatch?> loadNoticeBatch() async {
    final raw = await db.kvGet('$_batchKey:$_branch');
    if (raw == null) return null;
    try {
      return NoticeBatch.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveNoticeBatch(NoticeBatch b) => db.kvSet('$_batchKey:$_branch', jsonEncode(b.toJson()));

  Future<void> clearNoticeBatch() =>
      (db.delete(db.keyValues)..where((k) => k.key.equals('$_batchKey:$_branch'))).go();

  /// صاحب البقالة أكّد الإرسال: يُسجل في السجل (يُرفع عند المزامنة) ويتقدم الدور
  Future<void> markNoticeSent(NoticeBatch b, NoticeRecipient r) async {
    await db.transaction(() async {
      await db.into(db.localNotices).insert(LocalNoticesCompanion.insert(
            id: _uuid.v4(),
            branchId: _branch,
            customerId: r.customer.id,
            batchId: b.id,
            asOf: b.asOf,
            balances: jsonEncode(r.balances.map((k, v) => MapEntry(k, v.toString()))),
            sentBy: session.appUserId,
            sentAt: DateTime.now(),
          ));
      b.skipped.remove(r.customer.id);
      b.sent.add(r.customer.id);
      await saveNoticeBatch(b);
    });
  }

  Future<void> markNoticeSkipped(NoticeBatch b, String customerId) async {
    b.skipped.add(customerId);
    await saveNoticeBatch(b);
  }

  /// سجل رسائل زبون واحد (لصفحة الزبون عند الخلاف)
  Future<List<NoticeRow>> noticesOf(String customerId) => (db.select(db.localNotices)
        ..where((n) => n.customerId.equals(customerId))
        ..orderBy([(n) => OrderingTerm.desc(n.sentAt)]))
      .get();
}
