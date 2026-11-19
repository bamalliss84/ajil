// فتح قاعدة البقالة المحلية: مشفّرة بـ SQLCipher على الجوال، و sqlite3.wasm على الويب
export 'connection_web.dart' if (dart.library.io) 'connection_native.dart';
