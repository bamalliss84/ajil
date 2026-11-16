/// أخطاء الخادم بصيغة «رمز: رسالة عربية»
class AjilError implements Exception {
  final String code;
  final String message;
  const AjilError(this.code, this.message);

  static final _re = RegExp(r'^([a-z_]+):\s*(.+)$', dotAll: true);

  /// من نص خطأ PostgreSQL/PostgREST أو من رد Edge Function {code, message}
  factory AjilError.parse(Object? e) {
    if (e is AjilError) return e;
    if (e is Map) {
      final code = e['code']?.toString();
      final msg = e['message']?.toString();
      if (code != null && msg != null && !code.contains(RegExp(r'^\d'))) return AjilError(code, msg);
      if (msg != null) return AjilError.parse(msg);
    }
    final s = e?.toString() ?? '';
    final m = _re.firstMatch(s.trim());
    if (m != null) return AjilError(m.group(1)!, m.group(2)!.trim());
    // رسالة PostgREST: «... message: plan_customer_limit: ...»
    for (final inner in RegExp(r'([a-z_]{4,}):\s*([^\n,}]+)').allMatches(s)) {
      if (_known.contains(inner.group(1))) return AjilError(inner.group(1)!, inner.group(2)!.trim());
    }
    if (s.contains('SocketException') || s.contains('Failed host lookup') || s.contains('ClientException')) {
      return const AjilError('offline', 'لا يوجد اتصال بالإنترنت');
    }
    if (s.contains('Invalid login credentials')) {
      return const AjilError('login_failed', 'رقم البقالة أو رقم المستخدم أو كلمة المرور غير صحيحة');
    }
    return const AjilError('server_error', 'حدث خطأ غير متوقع — حاول مرة أخرى');
  }

  /// أخطاء تعني أن الحركة لن تُقبل أبداً (لا تُعاد محاولتها تلقائياً)
  bool get isPermanent => !{'offline', 'server_error', 'timestamp_skew', 'not_authenticated'}.contains(code);

  static const _known = {
    'ledger_immutable', 'customer_mismatch', 'customer_archived', 'currency_not_enabled',
    'subscription_expired', 'void_invalid', 'void_of_void', 'void_reason_required', 'void_not_owner',
    'void_too_late', 'plan_customer_limit', 'plan_device_limit', 'plan_user_limit', 'device_bound_elsewhere',
    'device_invalid', 'device_key_mismatch', 'replay_detected', 'store_suspended', 'phone_taken',
    'otp_expired', 'otp_locked', 'otp_rate_limited', 'otp_daily_limit', 'code_invalid', 'code_used',
    'owner_only', 'platform_admin_only', 'delete_forbidden', 'customer_move_forbidden',
  };

  @override
  String toString() => '$code: $message';
}
