import 'dart:async';

import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';

import 'local/db.dart';
import 'local/mappers.dart';
import 'remote/remote_api.dart';

class SyncReport {
  final int pushed;
  final int rejected;
  final int pulled;
  final bool fingerprintMismatch;
  final AjilError? error;
  const SyncReport({this.pushed = 0, this.rejected = 0, this.pulled = 0, this.fingerprintMismatch = false, this.error});
  bool get ok => error == null;
}

/// محرك المزامنة:
///  1) رفع الزبائن الجدد/المعدّلين (الحركات تعتمد عليهم)
///  2) رفع الحركات المعلقة بترتيب device_seq عبر البوابة الموقّعة
///  3) إعادة إرسال أي رقم ناقص يبلغ عنه الخادم (device_gaps)
///  4) رفع الوعود
///  5) سحب كل ما تغيّر بعد آخر مؤشر (server_seq)
///  6) أحياناً: مطابقة بصمة كل زبون (عدد ومجموع) — أي اختلاف ← سحب كامل
class SyncEngine {
  SyncEngine({required this.db, required this.api, required this.branchId, required this.deviceId, this.storeId = ''});

  final AppDatabase db;
  final String storeId;
  final RemoteApi api;
  final String branchId;
  final String deviceId;

  static const _batch = 200;
  bool _running = false;
  int _runs = 0;
  final _status = StreamController<SyncReport>.broadcast();
  Stream<SyncReport> get reports => _status.stream;

  String get _cursorKey => 'cursor:$branchId';

  Future<SyncReport> syncNow({bool verify = false}) async {
    if (_running) return const SyncReport();
    _running = true;
    try {
      await _pushCustomers();
      final (pushed, rejected) = await _pushTransactions();
      await _pushPromises();
      await _pushNotices();
      final pulled = await _pull();
      var mismatch = false;
      if (verify || ++_runs % 20 == 0) mismatch = await _verifyFingerprints();
      await db.kvSet('last_sync_ok', DateTime.now().toIso8601String());
      final r = SyncReport(pushed: pushed, rejected: rejected, pulled: pulled, fingerprintMismatch: mismatch);
      _status.add(r);
      return r;
    } catch (e) {
      final r = SyncReport(error: AjilError.parse(e));
      _status.add(r);
      return r;
    } finally {
      _running = false;
    }
  }

  Future<void> _pushCustomers() async {
    final dirty = await (db.select(db.localCustomers)
          ..where((c) => c.dirty.equals(true) & c.branchId.equals(branchId)))
        .get();
    for (final row in dirty) {
      await api.saveCustomer(row.toModel(), isNew: row.serverSeq == null);
      await (db.update(db.localCustomers)..where((c) => c.id.equals(row.id)))
          .write(const LocalCustomersCompanion(dirty: Value(false)));
    }
  }

  Future<(int, int)> _pushTransactions() async {
    var pushed = 0;
    var rejected = 0;
    while (true) {
      final pending = await (db.select(db.localTxs)
            ..where((t) => t.sync.equals('pending') & t.deviceId.equals(deviceId) & t.branchId.equals(branchId))
            ..orderBy([(t) => OrderingTerm.asc(t.deviceSeq)])
            ..limit(_batch))
          .get();
      if (pending.isEmpty) break;

      final res = await api.pushTransactions(deviceId, pending.map((r) => r.toModel().toPushRow()).toList());
      await db.transaction(() async {
        for (final r in res.results) {
          if (r.status == 'accepted' || r.status == 'duplicate') {
            pushed++;
            await (db.update(db.localTxs)..where((t) => t.id.equals(r.id))).write(
                LocalTxsCompanion(sync: const Value('synced'), serverSeq: Value(r.serverSeq), syncError: const Value(null)));
          } else {
            final err = AjilError.parse(r.error);
            if (err.isPermanent) {
              rejected++;
              await (db.update(db.localTxs)..where((t) => t.id.equals(r.id)))
                  .write(LocalTxsCompanion(sync: const Value('failed'), syncError: Value(err.message)));
            }
          }
        }
        // أرقام يقول الخادم إنها ناقصة: إن كانت عندنا كمتزامنة، نعيدها للإرسال
        if (res.gaps.isNotEmpty) {
          await (db.update(db.localTxs)
                ..where((t) => t.deviceId.equals(deviceId) & t.deviceSeq.isIn(res.gaps) & t.sync.equals('synced')))
              .write(const LocalTxsCompanion(sync: Value('pending')));
        }
      });
      // دفعة لم يُقبل منها شيء ولم يُرفض نهائياً = خطأ مؤقت؛ نتوقف ونعيد لاحقاً
      final progressed = res.results.any((r) => r.status != 'rejected') ||
          res.results.any((r) => AjilError.parse(r.error).isPermanent);
      if (!progressed || pending.length < _batch) break;
    }
    return (pushed, rejected);
  }

  Future<void> _pushPromises() async {
    final dirty = await (db.select(db.localPromises)
          ..where((p) => p.dirty.equals(true) & p.branchId.equals(branchId)))
        .get();
    for (final row in dirty) {
      await api.savePromise(row.toModel(), isNew: row.serverSeq == null);
      await (db.update(db.localPromises)..where((p) => p.id.equals(row.id)))
          .write(const LocalPromisesCompanion(dirty: Value(false)));
    }
  }

  /// سجل رسائل الأرصدة (لا يؤثر على الأرصدة؛ فشله لا يوقف المزامنة)
  Future<void> _pushNotices() async {
    final dirty = await (db.select(db.localNotices)
          ..where((n) => n.dirty.equals(true) & n.branchId.equals(branchId)))
        .get();
    for (final row in dirty) {
      try {
        await api.saveNotice(row.toServer(storeId: storeId));
        await (db.update(db.localNotices)..where((n) => n.id.equals(row.id)))
            .write(const LocalNoticesCompanion(dirty: Value(false)));
      } on AjilError catch (e) {
        if (e.code == 'offline') rethrow;
        // صلاحية سُحبت أو زبون غير موجود: نبقيه محلياً ولا نكرر كل مرة
        await (db.update(db.localNotices)..where((n) => n.id.equals(row.id)))
            .write(const LocalNoticesCompanion(dirty: Value(false)));
      }
    }
  }

  Future<int> _pull() async {
    var since = int.tryParse(await db.kvGet(_cursorKey) ?? '0') ?? 0;
    var total = 0;
    while (true) {
      final page = await api.pull(branchId, since);
      if (page.isEmpty) break;
      await db.transaction(() async {
        for (final c in page.customers) {
          final local = await (db.select(db.localCustomers)..where((t) => t.id.equals(c.id))).getSingleOrNull();
          // تعديل محلي لم يُرفع بعد يبقى (الأحدث يفوز عند رفعه)
          if (local != null && local.dirty && local.updatedAt.isAfter(c.updatedAt)) continue;
          await db.into(db.localCustomers).insertOnConflictUpdate(c.toCompanion(dirty: false));
        }
        for (final t in page.transactions) {
          await db.into(db.localTxs).insertOnConflictUpdate(t.toCompanion());
        }
        for (final p in page.promises) {
          final local = await (db.select(db.localPromises)..where((t) => t.id.equals(p.id))).getSingleOrNull();
          if (local != null && local.dirty) continue;
          await db.into(db.localPromises).insertOnConflictUpdate(p.toCompanion(dirty: false));
        }
      });
      total += page.customers.length + page.transactions.length + page.promises.length;
      if (page.maxSeq <= since) break;
      since = page.maxSeq;
      await db.kvSet(_cursorKey, '$since');
    }
    return total;
  }

  /// يقارن عدد ومجموع الحركات المتزامنة لكل (زبون، عملة) مع الخادم
  Future<bool> _verifyFingerprints() async {
    final remote = await api.fingerprints(branchId);
    final rows = await (db.select(db.localTxs)
          ..where((t) => t.branchId.equals(branchId) & t.sync.equals('synced')))
        .get();
    final local = <String, (int, Decimal)>{};
    for (final r in rows) {
      final k = '${r.customerId}|${r.currency}';
      final (n, s) = local[k] ?? (0, Decimal.zero);
      local[k] = (n + 1, s + Decimal.parse(r.signedAmount ?? '0'));
    }
    var mismatch = remote.length != local.length;
    for (final f in remote) {
      final l = local['${f.customerId}|${f.currency}'];
      if (l == null || l.$1 != f.count || l.$2 != Decimal.parse(f.sum)) mismatch = true;
    }
    if (mismatch) {
      // سحب كامل من الصفر: الخادم هو المرجع
      await db.kvSet(_cursorKey, '0');
      await _pull();
    }
    return mismatch;
  }

  Future<int> pendingCount() async {
    final c = db.localTxs.id.count();
    final q = db.selectOnly(db.localTxs)
      ..addColumns([c])
      ..where(db.localTxs.sync.equals('pending') & db.localTxs.branchId.equals(branchId));
    return (await q.getSingle()).read(c) ?? 0;
  }

  Future<void> dispose() => _status.close();
}
