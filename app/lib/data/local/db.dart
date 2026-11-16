import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'db.g.dart';

/// القاعدة المحلية: نسخة من بيانات الفرع + الحركات غير المتزامنة.
/// المبالغ نصوص (Decimal) — ممنوع REAL للمال.
/// بعد أي تعديل: dart run build_runner build --delete-conflicting-outputs

@DataClassName('CustomerRow')
class LocalCustomers extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get branchId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get defaultCurrency => text()();
  TextColumn get creditLimit => text().nullable()();
  TextColumn get creditLimitCurrency => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get serverSeq => integer().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TxRow')
class LocalTxs extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get branchId => text()();
  TextColumn get customerId => text()();
  TextColumn get kind => text()();
  TextColumn get amount => text()();
  TextColumn get currency => text()();
  TextColumn get fxPaidAmount => text().nullable()();
  TextColumn get fxPaidCurrency => text().nullable()();
  TextColumn get fxRate => text().nullable()();
  TextColumn get voidedId => text().nullable()();
  TextColumn get voidReason => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get invoiceNo => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get createdBy => text()();
  TextColumn get deviceId => text().nullable()();
  IntColumn get deviceSeq => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get serverSeq => integer().nullable()();
  TextColumn get signedAmount => text().nullable()();

  /// synced | pending | failed
  TextColumn get sync => text().withDefault(const Constant('pending'))();
  TextColumn get syncError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PromiseRow')
class LocalPromises extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text()();
  TextColumn get branchId => text()();
  TextColumn get customerId => text()();
  DateTimeColumn get promisedDate => dateTime()();
  TextColumn get amount => text().nullable()();
  TextColumn get currency => text().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get remindDayBefore => boolean().withDefault(const Constant(false))();
  BoolColumn get remindCustomer => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('open'))();
  IntColumn get serverSeq => integer().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// قيم متفرقة: مؤشر المزامنة، عدّاد device_seq، عدّاد الفواتير، الإعدادات المخزنة
@DataClassName('KvRow')
class KeyValues extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// سجل رسائل الأرصدة المرسلة (يُرفع للخادم لمنع التكرار بين الأجهزة)
@DataClassName('NoticeRow')
class LocalNotices extends Table {
  TextColumn get id => text()();
  TextColumn get branchId => text()();
  TextColumn get customerId => text()();
  TextColumn get batchId => text()();
  DateTimeColumn get asOf => dateTime()();
  TextColumn get balances => text()(); // JSON {"YER":"20000"}
  TextColumn get sentBy => text()();
  DateTimeColumn get sentAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [LocalCustomers, LocalTxs, LocalPromises, KeyValues, LocalNotices])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// قاعدة واحدة لكل بقالة على الجهاز؛ كل الاستعلامات تُفلتر بالفرع الحالي.
  /// عدّاد device_seq واحد للجهاز كله لأن الخادم يتحقق من التسلسل لكل جهاز.
  factory AppDatabase.forStore(String storeId) =>
      AppDatabase(driftDatabase(
        name: 'ajil_${storeId.replaceAll('-', '').substring(0, 12)}',
        web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
      ));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX IF NOT EXISTS tx_customer ON local_txs (customer_id, created_at)');
          await customStatement('CREATE INDEX IF NOT EXISTS tx_sync ON local_txs (sync, device_seq)');
          await customStatement('CREATE INDEX IF NOT EXISTS notice_customer ON local_notices (customer_id, sent_at)');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(localNotices);
            await customStatement('CREATE INDEX IF NOT EXISTS notice_customer ON local_notices (customer_id, sent_at)');
          }
        },
      );

  // ---------------- قيم متفرقة ----------------
  Future<String?> kvGet(String key) async =>
      (await (select(keyValues)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  Future<void> kvSet(String key, String value) =>
      into(keyValues).insertOnConflictUpdate(KeyValuesCompanion.insert(key: key, value: value));

  /// يحجز الرقم التالي في عدّاد (device_seq أو رقم الفاتورة) داخل معاملة واحدة
  Future<int> nextCounter(String key) => transaction(() async {
        final cur = int.tryParse(await kvGet(key) ?? '0') ?? 0;
        final next = cur + 1;
        await kvSet(key, '$next');
        return next;
      });
}
