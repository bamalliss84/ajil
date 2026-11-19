import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/theme.dart';

/// مظهر التطبيق لكل مستخدم (وليس لكل بقالة):
/// - يُحفظ محلياً مربوطاً بـ app_user_id فيُطبَّق فور الفتح بدون نت
/// - التغيير بدون اتصال يُعلَّم «غير مرفوع» ويُرفع عبر app.set_my_theme عند أول اتصال
/// - قيمة الخادم تُعتمد فقط إن لم يكن هناك تغيير محلي لم يُرفع
class ThemeController extends ChangeNotifier {
  ThemeController(this.storage, {this.push});

  final FlutterSecureStorage storage;

  /// يرفع الاختيار للخادم (set_my_theme) — يُضبط من SessionController
  Future<void> Function(String theme)? push;

  AjilTheme theme = AjilTheme.classic;
  String? _userId;
  Future<void>? _inflight;
  bool _again = false;

  static const _kLastUser = 'ajil.theme.last_user';
  static String _kTheme(String userId) => 'ajil.theme.$userId';
  static String _kDirty(String userId) => 'ajil.theme.$userId.dirty';

  String? get userId => _userId;

  /// عند فتح التطبيق: مظهر آخر مستخدم (حتى شاشة الدخول والقفل تظهر بمظهره)
  Future<void> init() async {
    try {
      final last = await storage.read(key: _kLastUser);
      if (last != null) await attach(last);
    } catch (_) {}
  }

  /// بعد فتح جلسة مستخدم (من الخادم أو من النسخة المحفوظة)
  Future<void> attach(String userId) async {
    _userId = userId;
    String? id;
    try {
      await storage.write(key: _kLastUser, value: userId);
      id = await storage.read(key: _kTheme(userId));
    } catch (_) {}
    _apply(AjilTheme.byId(id));
  }

  /// قيمة app_users.theme القادمة من الخادم
  Future<void> adoptServer(String userId, String? serverTheme) async {
    if (serverTheme == null) return;
    try {
      if (await storage.read(key: _kDirty(userId)) == '1') {
        unawaited(flush());
        return;
      }
      await storage.write(key: _kTheme(userId), value: serverTheme);
    } catch (_) {}
    if (userId == _userId) _apply(AjilTheme.byId(serverTheme));
  }

  /// اختيار المستخدم من شاشة «مظهر التطبيق»: فوري، ويعمل بدون إنترنت
  Future<void> select(String id) async {
    final t = AjilTheme.byId(id);
    _apply(t);
    final u = _userId;
    if (u == null) return;
    try {
      await storage.write(key: _kTheme(u), value: t.id);
      await storage.write(key: _kDirty(u), value: '1');
    } catch (_) {}
    unawaited(flush());
  }

  /// يرفع التغيير المعلّق إن وُجد (يُستدعى بعد كل مزامنة ناجحة).
  /// طلب أثناء رفع جارٍ ينتظره ويعيد المحاولة بعده، فلا يضيع اختيار تغيّر في الأثناء.
  Future<void> flush() {
    if (_inflight != null) {
      _again = true;
      return _inflight!;
    }
    return _inflight = () async {
      try {
        do {
          _again = false;
          await _pushOnce();
        } while (_again);
      } finally {
        _inflight = null;
      }
    }();
  }

  Future<void> _pushOnce() async {
    final u = _userId;
    final p = push;
    if (u == null || p == null) return;
    try {
      if (await storage.read(key: _kDirty(u)) != '1') return;
      final id = await storage.read(key: _kTheme(u)) ?? AjilTheme.classic.id;
      await p(id);
      // لم يتغيّر الاختيار أثناء الرفع؟ نزيل العلامة
      if (await storage.read(key: _kTheme(u)) == id) await storage.delete(key: _kDirty(u));
    } catch (_) {
      // بدون اتصال: يبقى معلّقاً حتى المزامنة القادمة
    }
  }

  void _apply(AjilTheme t) {
    if (identical(t, theme)) return;
    theme = t;
    notifyListeners();
  }
}
