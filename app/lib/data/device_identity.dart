import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:webcrypto/webcrypto.dart';

/// هوية الجهاز: مفتاح ثابت + زوج مفاتيح ECDSA P-256 يوقّع طلبات المزامنة.
/// المفتاح الخاص لا يغادر الجوال (مخزن في التخزين الآمن المشفر بـ Android Keystore).
/// ترقية لاحقة ممكنة: توليد المفتاح داخل Keystore نفسه عبر قناة Kotlin.
class DeviceIdentity {
  DeviceIdentity(this._storage);
  final FlutterSecureStorage _storage;

  static const _kKey = 'ajil.device_key';
  static const _kPriv = 'ajil.device_priv_pkcs8';
  static const _kPub = 'ajil.device_pub_spki';

  String? _deviceKey;
  String? _publicKey;
  EcdsaPrivateKey? _private;

  /// يُستدعى مرة عند بدء التطبيق
  Future<void> ensure() async {
    _deviceKey = await _storage.read(key: _kKey);
    final priv = await _storage.read(key: _kPriv);
    final pub = await _storage.read(key: _kPub);
    if (_deviceKey == null || priv == null || pub == null) {
      final pair = await EcdsaPrivateKey.generateKey(EllipticCurve.p256);
      _deviceKey = const Uuid().v4();
      _publicKey = base64Encode(await pair.publicKey.exportSpkiKey());
      final pkcs8 = await pair.privateKey.exportPkcs8Key();
      await _storage.write(key: _kKey, value: _deviceKey);
      await _storage.write(key: _kPub, value: _publicKey);
      await _storage.write(key: _kPriv, value: base64Encode(pkcs8));
      _private = pair.privateKey;
    } else {
      _publicKey = pub;
      _private = await EcdsaPrivateKey.importPkcs8Key(base64Decode(priv), EllipticCurve.p256);
    }
  }

  String get deviceKey => _deviceKey!;
  String get publicKeySpkiB64 => _publicKey!;

  /// التوقيع بصيغة r||s (64 بايت) — الخادم يقبلها مباشرة
  Future<String> sign(String message) async {
    final sig = await _private!.signBytes(utf8.encode(message), Hash.sha256);
    return base64Encode(sig);
  }

  static String nonce() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(18, (_) => r.nextInt(256)));
  }
}
