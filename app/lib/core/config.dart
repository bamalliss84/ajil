/// الإعدادات تأتي من --dart-define عند التشغيل:
/// flutter run --dart-define=SUPABASE_URL=http://10.0.2.2:54321 --dart-define=SUPABASE_ANON_KEY=...
/// (10.0.2.2 = جهاز الكمبيوتر من داخل محاكي Android)
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://10.0.2.2:54321');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const countryCode = String.fromEnvironment('PHONE_COUNTRY_CODE', defaultValue: '967');
  static const supportWhatsapp = String.fromEnvironment('SUPPORT_WHATSAPP', defaultValue: '');
  static const statementBaseUrl = String.fromEnvironment('STATEMENT_BASE_URL', defaultValue: '');

  /// القفل التلقائي
  static const idleLock = Duration(minutes: 5);
  static const backgroundLock = Duration(seconds: 30);

  /// المزامنة الاحتياطية الدورية
  static const syncInterval = Duration(minutes: 1);

  /// أقصى مدة عمل بدون اتصال قبل طلب التحقق من الاشتراك
  static const maxOffline = Duration(days: 7);
}
