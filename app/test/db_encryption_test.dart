import 'dart:io';
import 'dart:math';

import 'package:ajil/data/local/connection/connection_native.dart';
import 'package:ajil/data/local/db_key.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// مكتبة sqlite على جهاز الاختبار: SQLCipher أم sqlite عادي؟
bool _hostHasCipher() {
  final db = sqlite3.openInMemory();
  try {
    final r = db.select('PRAGMA cipher_version');
    return r.isNotEmpty && '${r.first.values.first}'.isNotEmpty;
  } finally {
    db.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('ajil_db_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  File plainDb(String name) {
    final f = File('${tmp.path}/$name.sqlite');
    final db = sqlite3.open(f.path);
    db.execute('CREATE TABLE t (id TEXT PRIMARY KEY, amount TEXT)');
    db.execute("INSERT INTO t VALUES ('a', '20000')");
    db.execute('PRAGMA user_version = 2');
    db.dispose();
    return f;
  }

  group('مفتاح القاعدة', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('256 بت hex، يُحفظ ويبقى ثابتاً للجهاز', () async {
      final a = DbKey(const FlutterSecureStorage());
      final k = await a.obtain();
      expect(k, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(await DbKey(const FlutterSecureStorage()).obtain(), k);
    });

    test('مفتاح تالف في التخزين يُستبدل', () async {
      FlutterSecureStorage.setMockInitialValues({'ajil.db_key': 'short'});
      expect(await DbKey(const FlutterSecureStorage()).obtain(), matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('مفتاحان مختلفان من مولّدين مختلفين', () {
      expect(DbKey.generate(Random(1)), isNot(DbKey.generate(Random(2))));
    });
  });

  test('كشف الملف غير المشفّر من ترويسته', () {
    final f = plainDb('plain');
    expect(isPlainSqlite(f), isTrue);
    final rnd = File('${tmp.path}/random.sqlite')..writeAsBytesSync(List.generate(4096, (i) => (i * 37 + 11) % 256));
    expect(isPlainSqlite(rnd), isFalse);
    expect(isPlainSqlite(File('${tmp.path}/missing.sqlite')), isFalse);
  });

  test('مفتاح بصيغة خاطئة يُرفض قبل أي شيء', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.dispose);
    expect(() => applyKey(db, "abc'; DROP TABLE t; --"), throwsArgumentError);
  });

  final cipher = _hostHasCipher();

  test('بدون SQLCipher: يرفض الفتح ولا يحوّل الملف (لا تخزين بلا تشفير بصمت)', () {
    final f = plainDb('legacy');
    final k = DbKey.generate();
    expect(() => prepareEncryptedFile(f, k), throwsA(isA<StateError>()));
    expect(isPlainSqlite(f), isTrue, reason: 'الملف الأصلي يبقى كما هو');
    expect(File('${f.path}.enc').existsSync(), isFalse, reason: 'لا نسخة جانبية غير مشفّرة');
  }, skip: cipher ? 'مكتبة الاختبار SQLCipher' : false);

  group('مع SQLCipher', () {
    test('تحويل قاعدة قديمة غير مشفّرة في مكانها مع بقاء البيانات و user_version', () {
      final f = plainDb('legacy');
      final k = DbKey.generate();
      prepareEncryptedFile(f, k);
      expect(isPlainSqlite(f), isFalse);
      final db = sqlite3.open(f.path);
      addTearDown(db.dispose);
      applyKey(db, k);
      expect(db.select('SELECT amount FROM t').first['amount'], '20000');
      expect(db.select('PRAGMA user_version').first.values.first, 2);
    });

    test('مفتاح آخر لا يفتحها، والملف يُعزل بدل حذفه', () {
      final f = plainDb('legacy');
      prepareEncryptedFile(f, DbKey.generate());
      prepareEncryptedFile(f, DbKey.generate());
      expect(f.existsSync(), isFalse);
      expect(tmp.listSync().any((e) => e.path.contains('.unreadable-')), isTrue);
    });
  }, skip: cipher ? false : 'مكتبة sqlite على جهاز الاختبار ليست SQLCipher — يُختبر على الجوال');
}
