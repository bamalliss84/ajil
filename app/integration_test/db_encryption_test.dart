// على جوال/محاكي Android حقيقي (SQLCipher الفعلي):
//   flutter test integration_test/db_encryption_test.dart -d <device>
import 'dart:io';

import 'package:ajil/data/local/connection/connection_native.dart';
import 'package:ajil/data/local/db.dart';
import 'package:ajil/data/local/db_key.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String docs;
  setUpAll(() async {
    docs = (await getApplicationDocumentsDirectory()).path;
    // تهيئة المكتبة (SQLCipher) في هذا العزل عبر أول فتح
    final warm = AppDatabase(openStoreDatabase('ajil_warmup', key: () async => DbKey.generate()));
    await warm.customSelect('SELECT 1').get();
    await warm.close();
  });

  File fileOf(String name) => File(p.join(docs, '$name.sqlite'));

  void clean(String name) {
    for (final e in Directory(docs).listSync()) {
      if (p.basename(e.path).startsWith(name)) e.deleteSync();
    }
  }

  test('المكتبة المحمّلة SQLCipher', () {
    final db = sqlite3.openInMemory();
    final v = db.select('PRAGMA cipher_version').first.values.first;
    db.dispose();
    expect('$v', isNotEmpty);
  });

  test('قاعدة جديدة: الملف مشفّر، والبيانات تُقرأ بالمفتاح فقط', () async {
    const name = 'ajil_enc_new';
    clean(name);
    final key = DbKey.generate();
    final db = AppDatabase(openStoreDatabase(name, key: () async => key));
    await db.customStatement('CREATE TABLE secret (v TEXT)');
    await db.customStatement("INSERT INTO secret VALUES ('عليه 20000')");
    await db.close();

    final f = fileOf(name);
    expect(isPlainSqlite(f), isFalse);
    expect(String.fromCharCodes(f.readAsBytesSync()).contains('secret'), isFalse, reason: 'أسماء الجداول غير مقروءة');

    final noKey = sqlite3.open(f.path);
    expect(() => noKey.select('SELECT * FROM secret'), throwsA(isA<SqliteException>()));
    noKey.dispose();

    final again = AppDatabase(openStoreDatabase(name, key: () async => key));
    final rows = await again.customSelect('SELECT v FROM secret').get();
    expect(rows.single.read<String>('v'), 'عليه 20000');
    await again.close();
  });

  test('قاعدة قديمة غير مشفّرة (قبل التحديث) تُحوَّل في مكانها وتبقى بياناتها', () async {
    const name = 'ajil_enc_legacy';
    clean(name);
    final f = fileOf(name);
    final plain = sqlite3.open(f.path); // بلا مفتاح = ملف عادي كما كان drift_flutter يكتبه
    plain.execute('CREATE TABLE t (id TEXT PRIMARY KEY, amount TEXT)');
    plain.execute("INSERT INTO t VALUES ('a', '15000')");
    plain.execute('PRAGMA user_version = 2');
    plain.dispose();
    expect(isPlainSqlite(f), isTrue);

    final key = DbKey.generate();
    final db = AppDatabase(openStoreDatabase(name, key: () async => key));
    final rows = await db.customSelect('SELECT amount FROM t').get();
    expect(rows.single.read<String>('amount'), '15000');
    await db.close();
    expect(isPlainSqlite(f), isFalse);
    expect(File('${f.path}.enc').existsSync(), isFalse);
  });

  test('مفتاح مختلف: الملف يُعزل ولا يُحذف، وتُنشأ قاعدة جديدة', () async {
    const name = 'ajil_enc_wrong';
    clean(name);
    final a = AppDatabase(openStoreDatabase(name, key: () async => DbKey.generate()));
    await a.customStatement('CREATE TABLE x (v TEXT)');
    await a.close();

    final b = AppDatabase(openStoreDatabase(name, key: () async => DbKey.generate()));
    final tables = await b.customSelect("SELECT name FROM sqlite_master WHERE name = 'x'").get();
    expect(tables, isEmpty);
    await b.close();
    expect(Directory(docs).listSync().any((e) => p.basename(e.path).startsWith('$name.sqlite.unreadable-')), isTrue);
  });

  test('مخطط التطبيق الحقيقي يعمل فوق القاعدة المشفّرة', () async {
    const name = 'ajil_enc_app';
    clean(name);
    final db = AppDatabase(openStoreDatabase(name, key: () async => DbKey.generate()));
    await db.into(db.keyValues).insert(KeyValuesCompanion.insert(key: 'k', value: 'v'));
    expect((await db.select(db.keyValues).get()).single.value, 'v');
    await db.close();
  });
}
