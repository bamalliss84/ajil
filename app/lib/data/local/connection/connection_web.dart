import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// الويب: صفحة المشترك تعمل متصلة فقط، وتُمسح بياناتها المحلية عند الخروج (SessionController.logout).
/// لا يوجد SQLCipher لـ wasm، فالتشفير هنا غير ممكن ولا يُطلب.
QueryExecutor openStoreDatabase(String name, {required Future<String> Function() key}) =>
    DatabaseConnection.delayed(Future(() async {
      final result = await WasmDatabase.open(
        databaseName: name,
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return result.resolvedExecutor;
    }));
