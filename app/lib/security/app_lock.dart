import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../core/config.dart';

/// قفل التطبيق: PIN خاص بكل مستخدم + بصمة اختيارية + قفل تلقائي
/// بعد 5 دقائق خمول أو 30 ثانية في الخلفية.
class AppLock extends ChangeNotifier with WidgetsBindingObserver {
  AppLock(this._storage);
  final FlutterSecureStorage _storage;
  final _auth = LocalAuthentication();

  bool _locked = true;
  String? _userId;
  Timer? _idle;
  DateTime? _pausedAt;
  int _failed = 0;

  bool get locked => _locked;
  int get failedAttempts => _failed;
  static const maxPinAttempts = 5;

  String _k(String what) => 'ajil.lock.$_userId.$what';

  void attach(String userId) {
    _userId = userId;
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    _idle?.cancel();
    _userId = null;
    _locked = true;
  }

  Future<bool> hasPin() async => (await _storage.read(key: _k('pin'))) != null;

  Future<void> setPin(String pin) async {
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) throw ArgumentError('PIN من 4 إلى 6 أرقام');
    final salt = base64Encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));
    await _storage.write(key: _k('salt'), value: salt);
    await _storage.write(key: _k('pin'), value: _hash(pin, salt));
    await _storage.write(key: _k('len'), value: '${pin.length}');
  }

  Future<int> pinLength() async => int.tryParse(await _storage.read(key: _k('len')) ?? '') ?? 4;

  /// PBKDF2 مبسط: 20,000 جولة SHA-256 — يكفي لأن PIN لا يغادر الجوال
  static String _hash(String pin, String salt) {
    var bytes = utf8.encode('$salt:$pin');
    for (var i = 0; i < 20000; i++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return base64Encode(bytes);
  }

  static bool _check(List<String> a) => _hash(a[0], a[1]) == a[2];

  /// يرجع false عند الخطأ؛ بعد 5 أخطاء يجب الدخول بكلمة المرور
  Future<bool> unlockWithPin(String pin) async {
    final salt = await _storage.read(key: _k('salt'));
    final stored = await _storage.read(key: _k('pin'));
    if (salt == null || stored == null) return false;
    final ok = await compute(_check, [pin, salt, stored]);
    if (ok) {
      _failed = 0;
      _unlock();
    } else {
      _failed++;
    }
    return ok;
  }

  bool get mustUsePassword => _failed >= maxPinAttempts;

  Future<bool> biometricEnabled() async => (await _storage.read(key: _k('bio'))) == '1';
  Future<void> setBiometric(bool on) => _storage.write(key: _k('bio'), value: on ? '1' : '0');

  Future<bool> biometricAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithBiometric() async {
    if (!await biometricEnabled()) return false;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'افتح آجِل',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (ok) _unlock();
      return ok;
    } catch (_) {
      return false;
    }
  }

  /// بعد الدخول بكلمة المرور
  void unlockAfterPassword() {
    _failed = 0;
    _unlock();
  }

  void lock() {
    if (_locked) return;
    _locked = true;
    _idle?.cancel();
    notifyListeners();
  }

  void _unlock() {
    _locked = false;
    touch();
    notifyListeners();
  }

  /// يُستدعى مع كل لمسة على الشاشة
  void touch() {
    _idle?.cancel();
    if (!_locked) _idle = Timer(AppConfig.idleLock, lock);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _pausedAt != null) {
      if (DateTime.now().difference(_pausedAt!) > AppConfig.backgroundLock) lock();
      _pausedAt = null;
    }
  }
}
