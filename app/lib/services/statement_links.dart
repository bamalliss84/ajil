import 'package:ajil_core/ajil_core.dart';

import '../core/config.dart';
import '../state/session_controller.dart';

/// رابط كشف الحساب العام للزبون: STATEMENT_BASE_URL + '#' + token
/// الـ token يُنشأ على الخادم (أونلاين فقط) ويُحفظ محلياً بعد أول جلب،
/// فتعمل رسائل واتساب بالرابط حتى بدون نت. بدون رابط محفوظ وبدون نت ← الرسالة بلا رابط.
class StatementLinks {
  static String _key(String customerId) => 'statement_link:$customerId';

  static bool get configured => AppConfig.statementBaseUrl.isNotEmpty;

  static String url(String token) => '${AppConfig.statementBaseUrl}#$token';

  /// الـ token المحفوظ على الجوال (بدون اتصال)
  static Future<String?> cachedToken(SessionController s, String customerId) async =>
      s.db?.kvGet(_key(customerId));

  /// يجلب الـ token من الخادم (أو يجدده) ويحفظه محلياً
  static Future<String> fetch(SessionController s, String customerId, {bool regenerate = false}) async {
    if (!s.online) {
      throw const AjilError('offline', 'رابط الكشف يحتاج اتصالاً بالإنترنت');
    }
    final token = await s.api.statementLink(customerId, regenerate: regenerate);
    await s.db?.kvSet(_key(customerId), token);
    return token;
  }

  /// الرابط الكامل لرسالة واتساب: المحفوظ، وإلا يُجلب إن وُجد اتصال، وإلا null
  static Future<String?> linkFor(SessionController s, String customerId) async {
    if (!configured) return null;
    final cached = await cachedToken(s, customerId);
    if (cached != null) return url(cached);
    if (!s.online) return null;
    try {
      return url(await fetch(s, customerId).timeout(const Duration(seconds: 6)));
    } catch (_) {
      return null; // تُرسل الرسالة بدون رابط
    }
  }
}
