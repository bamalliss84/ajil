import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

/// الجوال: قاعدة البقالة مشفّرة بالكامل بـ SQLCipher (AES-256) بمفتاح عشوائي 256 بت من التخزين الآمن.
/// - نفس مسار drift_flutter السابق (Documents/<name>.sqlite) فلا تضيع بيانات من سبقوا التحديث
/// - قاعدة قديمة غير مشفّرة تُحوَّل في مكانها (sqlcipher_export) قبل أول فتح
/// - يرفض العمل إن لم تكن المكتبة المحمّلة SQLCipher (لا نخزّن بيانات مالية بلا تشفير بصمت)
QueryExecutor openStoreDatabase(String name, {required Future<String> Function() key}) =>
    DatabaseConnection.delayed(Future(() async {
      await _configure();
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, '$name.sqlite'));
      final hex = await key();
      prepareEncryptedFile(file, hex);
      return DatabaseConnection(NativeDatabase.createInBackground(
        file,
        isolateSetup: _useSqlCipher,
        setup: _keySetup(hex),
      ));
    }));

/// الإغلاق يُرسل لعزل القاعدة: يجب ألا يلتقط إلا نص المفتاح (لا storage ولا كائنات FFI)
void Function(Database) _keySetup(String hex) => (db) => applyKey(db, hex);

bool _configured = false;

Future<void> _configure() async {
  if (_configured) return;
  if (Platform.isAndroid) await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  _useSqlCipher();
  // Android لا يسمح بـ /tmp الذي يستخدمه sqlite افتراضياً
  sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
  _configured = true;
}

/// يُستدعى في العزل الرئيسي وفي عزل القاعدة الخلفي
void _useSqlCipher() {
  if (Platform.isAndroid) open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
}

/// المفتاح خام (64 حرف hex) فلا يمرّ بـ PBKDF2 في كل فتح
void applyKey(Database db, String hex) {
  _checkHex(hex);
  requireCipher(db);
  db.execute("PRAGMA key = \"x'$hex'\"");
  // يتحقق فوراً أن المفتاح صحيح (وإلا: file is not a database)
  db.select('SELECT count(*) FROM sqlite_master');
}

void _checkHex(String hex) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hex)) throw ArgumentError('db_key: مفتاح القاعدة غير صالح');
}

/// sqlite العادي يتجاهل PRAGMA key و ATTACH … KEY بصمت ويكتب ملفاً غير مشفّر — فنتحقق أولاً
void requireCipher(Database db) {
  final v = db.select('PRAGMA cipher_version');
  if (v.isEmpty || '${v.first.values.first}'.isEmpty) {
    throw StateError('sqlcipher_missing: مكتبة التشفير غير محمّلة — لن تُفتح القاعدة بدون تشفير');
  }
}

const _plainHeader = 'SQLite format 3\u0000';

/// ملف بترويسة SQLite المقروءة = غير مشفّر (المشفّر يبدأ بملح عشوائي)
bool isPlainSqlite(File f) {
  if (!f.existsSync() || f.lengthSync() < 16) return false;
  final raf = f.openSync();
  try {
    return String.fromCharCodes(raf.readSync(16)) == _plainHeader;
  } finally {
    raf.closeSync();
  }
}

/// قبل الفتح: يحوّل القاعدة القديمة غير المشفّرة، ويعزل ملفاً لا يفتحه المفتاح الحالي
/// (مثلاً مُسح التخزين الآمن) بدل حذفه — ثم تُنشأ قاعدة جديدة وتُسحب البيانات من الخادم.
void prepareEncryptedFile(File file, String hex) {
  if (!file.existsSync()) return;
  if (isPlainSqlite(file)) {
    encryptPlainDatabase(file, hex);
    return;
  }
  final db = sqlite3.open(file.path);
  try {
    applyKey(db, hex);
  } on SqliteException {
    db.dispose();
    final aside = '${file.path}.unreadable-${DateTime.now().millisecondsSinceEpoch}';
    file.renameSync(aside);
    for (final s in const ['-wal', '-shm', '-journal']) {
      final f = File('${file.path}$s');
      if (f.existsSync()) f.renameSync('$aside$s');
    }
    return;
  }
  db.dispose();
}

/// تحويل في المكان: نسخة مشفّرة كاملة بـ sqlcipher_export ثم استبدال الملف (rename ذري)
void encryptPlainDatabase(File file, String hex) {
  _checkHex(hex);
  final enc = File('${file.path}.enc');
  if (enc.existsSync()) enc.deleteSync();
  final db = sqlite3.open(file.path);
  try {
    requireCipher(db);
    final version = db.select('PRAGMA user_version').first.values.first as int;
    db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    final path = enc.path.replaceAll("'", "''");
    db.execute("ATTACH DATABASE '$path' AS enc KEY \"x'$hex'\"");
    db.select("SELECT sqlcipher_export('enc')");
    db.execute('PRAGMA enc.user_version = $version');
    db.execute('DETACH DATABASE enc');
  } finally {
    db.dispose();
  }
  // تحقق قبل الاستبدال: النسخة تُفتح بالمفتاح ولم تعد مقروءة بدونه
  final check = sqlite3.open(enc.path);
  try {
    applyKey(check, hex);
  } finally {
    check.dispose();
  }
  if (isPlainSqlite(enc)) throw StateError('db_encrypt_failed: النسخة المشفّرة غير مشفّرة');
  for (final s in const ['-wal', '-shm', '-journal']) {
    final f = File('${file.path}$s');
    if (f.existsSync()) f.deleteSync();
  }
  enc.renameSync(file.path);
}
