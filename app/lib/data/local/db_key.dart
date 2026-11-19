import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// مفتاح تشفير القاعدة المحلية: 256 بت عشوائية (Random.secure) تُولَّد مرة للجهاز
/// وتُحفظ في التخزين الآمن (Android Keystore عبر EncryptedSharedPreferences). لا تُرسل لأي مكان.
class DbKey {
  DbKey(this.storage);
  final FlutterSecureStorage storage;

  static const _k = 'ajil.db_key';
  String? _cached;

  Future<String> obtain() async {
    if (_cached != null) return _cached!;
    var hex = await storage.read(key: _k);
    if (hex == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(hex)) {
      hex = generate();
      await storage.write(key: _k, value: hex);
    }
    return _cached = hex;
  }

  static String generate([Random? rnd]) {
    final r = rnd ?? Random.secure();
    return List.generate(32, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
}
