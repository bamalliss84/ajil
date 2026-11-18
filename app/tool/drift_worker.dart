// عامل drift للويب — يُترجم من حزم التطبيق نفسها حتى يطابق إصدار sqlite3.wasm:
//   dart compile js -O4 -o web/drift_worker.js tool/drift_worker.dart
// (ملف drift_worker.js الجاهز من إصدارات drift قد يُبنى بـ sqlite3 أقدم فيفشل: Import "dart" "localtime")
import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();
