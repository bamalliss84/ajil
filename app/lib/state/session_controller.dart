import 'dart:async';
import 'dart:convert';

import 'package:ajil_core/ajil_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config.dart';
import '../data/device_identity.dart';
import '../data/local/db.dart';
import '../data/local/db_key.dart';
import '../data/remote/remote_api.dart';
import '../data/repository.dart';
import '../data/sync_engine.dart';
import '../security/app_lock.dart';
import '../services/notifications.dart';
import '../data/local/mappers.dart';
import 'theme_controller.dart';

/// ما يحفظه الجوال لشاشة الدخول: رقم البقالة، رقم المستخدم، الفروع، آخر فرع
class LoginMemory {
  final String storePhone;
  final int userNo;
  final List<Branch> branches;
  final String? lastBranchId;
  const LoginMemory(this.storePhone, this.userNo, this.branches, this.lastBranchId);

  Map<String, dynamic> toJson() => {
        'phone': storePhone,
        'user_no': userNo,
        'branches': branches.map((b) => b.toJson()).toList(),
        'last': lastBranchId,
      };
  factory LoginMemory.fromJson(Map<String, dynamic> j) => LoginMemory(
        j['phone'],
        j['user_no'],
        (j['branches'] as List).map((b) => Branch.fromJson(Map<String, dynamic>.from(b))).toList(),
        j['last'],
      );
}

enum SessionStage { loggedOut, needsPin, locked, ready, pendingDeviceApproval }

/// يدير: الدخول، اختيار الفرع، تسجيل الجهاز، القاعدة المحلية، المزامنة الدورية، القفل
class SessionController extends ChangeNotifier {
  SessionController({required this.supabase, required this.storage, required this.identity, required this.lock, this.notifications, this.theme}) {
    lock.addListener(_onLock);
    theme?.push = (t) => api.setMyTheme(t);
  }

  final SupabaseClient supabase;
  final FlutterSecureStorage storage;
  final DeviceIdentity identity;
  final AppLock lock;
  final Notifications? notifications;
  final ThemeController? theme;
  Map<String, dynamic>? settings;

  late final SupabaseRemoteApi api = SupabaseRemoteApi(supabase, identity);
  late final DbKey _dbKey = DbKey(storage);

  WorkSession? session;
  AppDatabase? db;
  LedgerRepository? repo;
  SyncEngine? sync;
  LoginMemory? memory;
  SessionStage stage = SessionStage.loggedOut;
  bool online = true;
  int pending = 0;
  DateTime? lastSync;
  AjilError? lastSyncError;
  Map<String, dynamic>? subscription;

  /// فُتح من النسخة المحفوظة لأن الخادم لم يُوصل إليه — تُحدَّث البيانات بعد أول مزامنة ناجحة
  bool openedOffline = false;

  Timer? _timer;
  RealtimeChannel? _channel;
  StreamSubscription? _conn;
  StreamSubscription? _syncSub;

  static const _kMemory = 'ajil.login_memory';
  static const _kSession = 'ajil.session_cache';

  void _onLock() {
    if (stage == SessionStage.ready && lock.locked) {
      stage = SessionStage.locked;
      notifyListeners();
    } else if (stage == SessionStage.locked && !lock.locked) {
      stage = SessionStage.ready;
      notifyListeners();
    }
  }

  /// عند فتح التطبيق: إن كانت هناك جلسة محفوظة نذهب لشاشة القفل مباشرة
  Future<void> restore() async {
    final raw = await storage.read(key: _kMemory);
    if (raw != null) memory = LoginMemory.fromJson(jsonDecode(raw));
    if (supabase.auth.currentSession != null && memory?.lastBranchId != null) {
      try {
        // الجوال يعمل بدون نت: إن لم يُوصل للخادم نفتح من آخر جلسة محفوظة
        await _openSession(memory!.lastBranchId!, allowCache: !kIsWeb);
        lock.attach(session!.appUserId);
        stage = await lock.hasPin() ? SessionStage.locked : SessionStage.needsPin;
      } catch (_) {
        stage = SessionStage.loggedOut;
      }
    }
    notifyListeners();
  }

  /// الفروع المسموحة لرقم البقالة + المستخدم المحفوظين (لشاشة الدخول)
  List<Branch> rememberedBranches(String phone, int userNo) =>
      (memory != null && memory!.storePhone == phone && memory!.userNo == userNo) ? memory!.branches : const [];

  Future<void> login({required String storePhone, required int userNo, required String password, String? branchId}) async {
    final phone = Identity.normalizePhone(storePhone, countryCode: AppConfig.countryCode);
    await api.signIn(phone, userNo, password);
    final branches = await api.myBranches();
    if (branches.isEmpty) throw const AjilError('no_branch', 'لا يوجد فرع مسموح لك — راجع المالك');
    final chosen = branches.firstWhere((b) => b.id == branchId, orElse: () => branches.first);
    memory = LoginMemory(phone, userNo, branches, chosen.id);
    await storage.write(key: _kMemory, value: jsonEncode(memory!.toJson()));
    await _openSession(chosen.id);
    lock.attach(session!.appUserId);
    lock.unlockAfterPassword();
    stage = await lock.hasPin() ? SessionStage.ready : SessionStage.needsPin;
    if (stage == SessionStage.ready && session!.deviceId.isEmpty) stage = SessionStage.pendingDeviceApproval;
    notifyListeners();
  }

  Future<void> _openSession(String branchId, {bool allowCache = false}) async {
    ({WorkSession session, Map<String, dynamic>? subscription, Map<String, dynamic>? settings}) o;
    try {
      final f = _fetchSession(branchId);
      o = await (allowCache ? f.timeout(AppConfig.openTimeout) : f);
      openedOffline = false;
      if (!kIsWeb) await _writeCachedSession(o);
    } catch (e) {
      if (!allowCache || !AjilError.isConnectivity(e)) rethrow;
      final cached = await _readCachedSession(branchId);
      if (cached == null) rethrow;
      o = cached;
      openedOffline = true;
      online = false;
    }
    session = o.session;
    subscription = o.subscription;
    settings = o.settings;
    await theme?.attach(o.session.appUserId);
    await db?.close();
    db = AppDatabase.forStore(o.session.storeId, key: _dbKey.obtain);
    repo = LedgerRepository(db!, o.session);
    await _startSync();
  }

  /// يجلب بيانات الجلسة من الخادم بلا أي أثر محلي (حتى لا يتداخل طلب انتهت مهلته مع الفتح من النسخة المحفوظة)
  Future<({WorkSession session, Map<String, dynamic>? subscription, Map<String, dynamic>? settings})> _fetchSession(
      String branchId) async {
    final claims = await api.claims();
    final storeId = claims['store_id'] as String?;
    final userId = claims['app_user_id'] as String?;
    if (storeId == null || userId == null) {
      throw const AjilError('no_store', 'هذا الحساب غير مرتبط ببقالة');
    }
    final store = await api.myStore();
    final me = await api.me(userId);
    await theme?.adoptServer(userId, me['theme'] as String?);
    final branches = await api.myBranches();
    final branch = branches.firstWhere((b) => b.id == branchId, orElse: () => branches.first);
    final device = await api.registerDevice(kIsWeb ? 'متصفح' : 'جوال ${me['display_name']}');
    final sub = await api.currentSubscription(storeId);
    Map<String, dynamic>? st;
    try {
      st = await api.settings(storeId);
    } catch (_) {}

    return (
      session: WorkSession(
        storeId: storeId,
        storeName: store['name'],
        storePhone: store['owner_phone'],
        appUserId: userId,
        userNo: me['user_no'],
        displayName: me['display_name'],
        isOwner: me['role'] == 'owner',
        branch: branch,
        deviceId: device['approved'] == true ? device['id'] : '',
        deviceLetter: device['device_letter'] ?? 'A',
        enabledCurrencies: List<String>.from(store['enabled_currencies'] ?? const ['YER']),
        defaultCurrency: store['default_currency'] ?? 'YER',
      ),
      subscription: sub,
      settings: st,
    );
  }

  Future<void> _writeCachedSession(
          ({WorkSession session, Map<String, dynamic>? subscription, Map<String, dynamic>? settings}) o) =>
      storage.write(
        key: _kSession,
        value: jsonEncode({'session': o.session.toJson(), 'subscription': o.subscription, 'settings': o.settings}),
      );

  /// آخر جلسة ناجحة لنفس المستخدم والفرع (تُمسح عند الخروج)
  Future<({WorkSession session, Map<String, dynamic>? subscription, Map<String, dynamic>? settings})?>
      _readCachedSession(String branchId) async {
    try {
      final raw = await storage.read(key: _kSession);
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final w = WorkSession.fromJson(Map<String, dynamic>.from(j['session']));
      final claims = await api.claims();
      if (w.branch.id != branchId || w.appUserId != claims['app_user_id'] || w.deviceId.isEmpty) return null;
      Map<String, dynamic>? m(Object? v) => v == null ? null : Map<String, dynamic>.from(v as Map);
      return (session: w, subscription: m(j['subscription']), settings: m(j['settings']));
    } catch (_) {
      return null;
    }
  }

  /// بعد فتح بدون نت: أول مزامنة ناجحة تعني عودة الاتصال، فنحدّث الاشتراك والإعدادات
  Future<void> _refreshAfterOffline() async {
    final w = session;
    if (w == null) return;
    try {
      final o = await _fetchSession(w.branch.id);
      if (session?.appUserId != w.appUserId) return;
      subscription = o.subscription;
      settings = o.settings;
      openedOffline = false;
      await _writeCachedSession(o);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _startSync() async {
    _timer?.cancel();
    await _syncSub?.cancel();
    await _conn?.cancel();
    if (_channel != null) await supabase.removeChannel(_channel!);
    if (session == null || session!.deviceId.isEmpty) return;

    sync = SyncEngine(db: db!, api: api, branchId: session!.branch.id, deviceId: session!.deviceId, storeId: session!.storeId);
    _syncSub = sync!.reports.listen((r) async {
      lastSyncError = r.error;
      // الجهاز أُلغي من المالك: نمسح البيانات المحلية ونخرج
      if (r.error?.code == 'device_invalid') {
        await logout(wipeLocal: true);
        return;
      }
      if (r.ok) {
        lastSync = DateTime.now();
        unawaited(_reschedule());
        if (openedOffline) unawaited(_refreshAfterOffline());
        unawaited(theme?.flush());
      }
      online = r.error?.code != 'offline';
      pending = await sync!.pendingCount();
      notifyListeners();
    });
    _timer = Timer.periodic(AppConfig.syncInterval, (_) => sync!.syncNow());
    _conn = Connectivity().onConnectivityChanged.listen((r) {
      final up = !r.contains(ConnectivityResult.none);
      if (up && !online) sync!.syncNow();
      online = up;
      notifyListeners();
    });
    _channel = api.subscribeBranch(session!.branch.id, () => sync!.syncNow());
    unawaited(sync!.syncNow(verify: true));
  }

  /// إعادة جدولة التنبيهات من البيانات المحلية
  Future<void> _reschedule() async {
    final n = notifications;
    final d = db;
    final w = session;
    if (n == null || d == null || w == null) return;
    final promises = (await (d.select(d.localPromises)
              ..where((p) => p.branchId.equals(w.branch.id) & p.status.equals('open')))
            .get())
        .map((r) => r.toModel())
        .toList();
    final names = {
      for (final c in await (d.select(d.localCustomers)..where((c) => c.branchId.equals(w.branch.id))).get()) c.id: c.name
    };
    final today = DateTime.now();
    final due = (await (d.select(d.localTxs)
              ..where((t) => t.branchId.equals(w.branch.id) & t.kind.equals('debt') & t.dueDate.isBiggerOrEqualValue(DateTime(today.year, today.month, today.day))))
            .get())
        .map((r) => r.toModel())
        .toList();
    final time = (settings?['monthly_claim_time'] as String? ?? '09:00').split(':');
    await n.reschedule(
      promises: promises,
      customerNames: names,
      dueDebts: due,
      monthlyEnabled: settings?['monthly_claim_enabled'] != false && w.isOwner,
      monthlyDay: settings?['monthly_claim_day'] as int? ?? 1,
      hour: int.tryParse(time[0]) ?? 9,
      minute: int.tryParse(time.length > 1 ? time[1] : '0') ?? 0,
    );
  }

  /// الموظف بكلمة مرور مؤقتة يُطلب منه تغييرها
  bool get mustChangePassword => supabase.auth.currentUser?.userMetadata?['must_change_password'] == true;

  /// بعد كل كتابة: نحاول الرفع فوراً إن كان هناك اتصال
  void kick() {
    if (sync != null) unawaited(sync!.syncNow());
    sync?.pendingCount().then((n) {
      pending = n;
      notifyListeners();
    });
  }

  Future<void> setPin(String pin, {bool biometric = false}) async {
    await lock.setPin(pin);
    await lock.setBiometric(biometric);
    stage = session!.deviceId.isEmpty ? SessionStage.pendingDeviceApproval : SessionStage.ready;
    notifyListeners();
  }

  /// إعادة فحص اعتماد جهاز الموظف
  Future<void> recheckDevice() async {
    if (memory?.lastBranchId == null) return;
    await _openSession(memory!.lastBranchId!);
    if (session!.deviceId.isNotEmpty) stage = SessionStage.ready;
    notifyListeners();
  }

  /// الخروج: الانتقال لفرع آخر يكون بالخروج ثم الدخول
  Future<void> logout({bool wipeLocal = false}) async {
    _timer?.cancel();
    await _syncSub?.cancel();
    await _conn?.cancel();
    if (_channel != null) await supabase.removeChannel(_channel!);
    // على الويب: لا نترك بيانات مالية في المتصفح
    if (kIsWeb || wipeLocal) {
      await db?.transaction(() async {
        for (final t in db!.allTables) {
          await db!.delete(t).go();
        }
      });
    }
    await db?.close();
    db = null;
    repo = null;
    sync = null;
    session = null;
    openedOffline = false;
    await storage.delete(key: _kSession);
    lock.detach();
    await supabase.auth.signOut();
    stage = SessionStage.loggedOut;
    notifyListeners();
  }

  /// الويب يعمل متصلاً فقط: الكتابة ممنوعة بدون اتصال
  bool get canWrite => (!kIsWeb || online) && !subscriptionExpired;

  /// سبب منع الكتابة (بصيغة رسالة الخطأ) — يُعرض إن حاول المستخدم الحفظ
  String get writeBlockedError => subscriptionExpired
      ? 'subscription_expired: الاشتراك منتهٍ — البيانات للقراءة فقط'
      : 'offline: لا يوجد اتصال — التسجيل من صفحة الويب يحتاج إنترنت';

  bool get subscriptionExpired {
    final exp = subscription?['expires_at'];
    if (exp == null) return false;
    return DateTime.parse(exp).add(const Duration(days: 7)).isBefore(DateTime.now());
  }
}
