import 'dart:convert';

import 'package:ajil_core/ajil_core.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../device_identity.dart';

/// نتيجة رفع حركة واحدة
class PushResult {
  final String id;
  final String status; // accepted | duplicate | rejected
  final int? serverSeq;
  final String? error;
  const PushResult(this.id, this.status, this.serverSeq, this.error);
}

class PushResponse {
  final List<PushResult> results;
  final List<int> gaps;
  const PushResponse(this.results, this.gaps);
}

class PullPage {
  final List<Customer> customers;
  final List<LedgerTx> transactions;
  final List<PaymentPromise> promises;
  final int maxSeq;
  const PullPage(this.customers, this.transactions, this.promises, this.maxSeq);
  bool get isEmpty => customers.isEmpty && transactions.isEmpty && promises.isEmpty;
}

class Fingerprint {
  final String customerId;
  final String currency;
  final int count;
  final String sum;
  const Fingerprint(this.customerId, this.currency, this.count, this.sum);
}

/// واجهة الخادم — مجردة حتى يُختبر محرك المزامنة بخادم وهمي
abstract class RemoteApi {
  Future<PushResponse> pushTransactions(String deviceId, List<Map<String, dynamic>> rows);
  Future<void> saveCustomer(Customer c, {required bool isNew});
  Future<void> savePromise(PaymentPromise p, {required bool isNew});
  Future<PullPage> pull(String branchId, int since, {int limit = 500});
  Future<List<Fingerprint>> fingerprints(String branchId);

  /// سجل رسائل الأرصدة: رفع رسالة (آمن عند التكرار) وجلب ما أرسلته الأجهزة الأخرى
  Future<void> saveNotice(Map<String, dynamic> row);
  Future<List<Map<String, dynamic>>> recentNotices(String branchId, DateTime since);
}

/// التنفيذ الحقيقي على Supabase
class SupabaseRemoteApi implements RemoteApi {
  SupabaseRemoteApi(this.client, this.identity);
  final SupabaseClient client;
  final DeviceIdentity identity;

  SupabaseQueryBuilder _t(String table) => client.schema('app').from(table);
  PostgrestFilterBuilder<T> _rpc<T>(String fn, [Map<String, dynamic>? params]) =>
      client.schema('app').rpc<T>(fn, params: params);

  Never _rethrow(Object e) => throw AjilError.parse(e is PostgrestException ? e.message : e);

  // ---------------- الدخول والسياق ----------------
  Future<void> signIn(String storePhone, int userNo, String password) async {
    try {
      await client.auth.signInWithPassword(email: Identity.derivedEmail(storePhone, userNo), password: password);
    } catch (e) {
      _rethrow(e);
    }
  }

  Future<Map<String, dynamic>> claims() async {
    final token = client.auth.currentSession?.accessToken;
    if (token == null) throw const AjilError('not_authenticated', 'سجّل الدخول أولاً');
    final part = token.split('.')[1];
    return jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(part))));
  }

  Future<Map<String, dynamic>> myStore() async =>
      await _t('stores').select('id, name, owner_phone, default_currency, enabled_currencies, status').single();

  Future<List<Branch>> myBranches() async {
    final rows = await _t('branches').select('id, code, name').eq('is_active', true).order('code');
    return rows.map(Branch.fromJson).toList();
  }

  Future<Map<String, dynamic>> me(String appUserId) async =>
      await _t('app_users').select('id, user_no, display_name, role').eq('id', appUserId).single();

  Future<Map<String, dynamic>?> currentSubscription(String storeId) async {
    final rows = await _t('subscriptions')
        .select('plan_code, expires_at, plans(name_ar, customers_limit)')
        .eq('store_id', storeId)
        .lte('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('expires_at', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<Map<String, dynamic>> registerDevice(String label) async {
    try {
      final r = await _rpc<Map<String, dynamic>>('register_device_v2', {
        'p_device_key': identity.deviceKey,
        'p_public_key': identity.publicKeySpkiB64,
        'p_label': label,
      });
      return r;
    } catch (e) {
      _rethrow(e);
    }
  }

  // ---------------- Edge Functions (بدون جلسة) ----------------
  Future<Map<String, dynamic>> _fn(String name, Map<String, dynamic> body, {bool auth = false}) async {
    final res = await http.post(
      Uri.parse('${AppConfig.supabaseUrl}/functions/v1/$name'),
      headers: {
        'content-type': 'application/json',
        'apikey': AppConfig.supabaseAnonKey,
        'authorization': 'Bearer ${auth ? client.auth.currentSession?.accessToken : AppConfig.supabaseAnonKey}',
      },
      body: jsonEncode(body),
    );
    final data = res.body.isEmpty ? <String, dynamic>{} : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode >= 400) throw AjilError.parse(data);
    return data;
  }

  Future<String?> sendOtp(String phone, String purpose) async =>
      (await _fn('send-otp', {'phone': phone, 'purpose': purpose}))['dev_code'] as String?;

  Future<void> registerStore({
    required String phone,
    required String code,
    required String storeName,
    required String ownerName,
    required String password,
    String currency = 'YER',
  }) async {
    final r = await _fn('register-store', {
      'phone': phone,
      'code': code,
      'store_name': storeName,
      'owner_name': ownerName,
      'password': password,
      'device_key': identity.deviceKey,
      'currency': currency,
    });
    final refresh = (r['session'] as Map?)?['refresh_token'] as String?;
    if (refresh != null) await client.auth.setSession(refresh);
  }

  Future<void> resetOwnerPassword(String phone, String code, String newPassword) =>
      _fn('reset-password', {'mode': 'owner', 'phone': phone, 'code': code, 'new_password': newPassword});

  Future<void> changeMyPassword(String newPassword) async {
    await _fn('reset-password', {'mode': 'self', 'new_password': newPassword}, auth: true);
    await client.auth.refreshSession(); // تحديث must_change_password في الجلسة
  }

  Future<String> resetEmployeePassword(String userId) async =>
      (await _fn('reset-password', {'mode': 'employee', 'user_id': userId}, auth: true))['temp_password'];

  Future<({int userNo, String tempPassword})> addEmployee(String name, List<String> branchIds) async {
    final r = await _fn('add-employee', {'name': name, 'branches': branchIds}, auth: true);
    return (userNo: r['user_no'] as int, tempPassword: r['temp_password'] as String);
  }

  // ---------------- المزامنة ----------------
  @override
  Future<PushResponse> pushTransactions(String deviceId, List<Map<String, dynamic>> rows) async {
    final body = jsonEncode({'rows': rows});
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = DeviceIdentity.nonce();
    final sig = await identity.sign(canonicalString(
        method: 'POST', path: 'sync-push', deviceId: deviceId, timestamp: ts, nonce: nonce, body: body));
    final res = await http.post(
      Uri.parse('${AppConfig.supabaseUrl}/functions/v1/sync-push'),
      headers: {
        'content-type': 'application/json',
        'apikey': AppConfig.supabaseAnonKey,
        'authorization': 'Bearer ${client.auth.currentSession?.accessToken}',
        'x-ajil-device': deviceId,
        'x-ajil-ts': ts,
        'x-ajil-nonce': nonce,
        'x-ajil-sig': sig,
      },
      body: body,
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode >= 400) throw AjilError.parse(data);
    return PushResponse(
      (data['results'] as List)
          .map((r) => PushResult(r['id'], r['status'], r['server_seq'], r['error']))
          .toList(),
      (data['gaps'] as List).cast<num>().map((n) => n.toInt()).toList(),
    );
  }

  @override
  Future<void> saveCustomer(Customer c, {required bool isNew}) async {
    try {
      if (isNew) {
        try {
          await _t('customers').insert(c.toServer());
          return;
        } on PostgrestException catch (e) {
          if (e.code != '23505') rethrow; // أُدخل سابقاً وضاع الرد — نكمل بالتعديل
        }
      }
      final row = c.toServer()..removeWhere((k, _) => const {'id', 'store_id', 'branch_id'}.contains(k));
      await _t('customers').update(row).eq('id', c.id);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<void> savePromise(PaymentPromise p, {required bool isNew}) async {
    try {
      if (isNew) {
        try {
          await _t('promises').insert(p.toServer());
          return;
        } on PostgrestException catch (e) {
          if (e.code != '23505') rethrow;
        }
      }
      final row = p.toServer()
        ..removeWhere((k, _) => const {'id', 'store_id', 'branch_id', 'customer_id'}.contains(k));
      await _t('promises').update(row).eq('id', p.id);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<PullPage> pull(String branchId, int since, {int limit = 500}) async {
    try {
      final r = await _rpc<Map<String, dynamic>>(
          'pull_changes', {'p_branch': branchId, 'p_since': since, 'p_limit': limit});
      return PullPage(
        (r['customers'] as List).map((j) => Customer.fromJson(j)).toList(),
        (r['transactions'] as List).map((j) => LedgerTx.fromJson(j)).toList(),
        (r['promises'] as List).map((j) => PaymentPromise.fromJson(j)).toList(),
        (r['max_seq'] as num).toInt(),
      );
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<void> saveNotice(Map<String, dynamic> row) async {
    try {
      await _t('balance_notices').insert(row);
    } on PostgrestException catch (e) {
      if (e.code == '23505') return; // رُفعت سابقاً وضاع الرد
      _rethrow(e);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> recentNotices(String branchId, DateTime since) async {
    try {
      final r = await _t('balance_notices')
          .select('id, branch_id, customer_id, batch_id, as_of, balances, sent_by, sent_at')
          .eq('branch_id', branchId)
          .gte('sent_at', since.toUtc().toIso8601String())
          .order('sent_at')
          .limit(5000);
      return List<Map<String, dynamic>>.from(r);
    } catch (e) {
      _rethrow(e);
    }
  }

  @override
  Future<List<Fingerprint>> fingerprints(String branchId) async {
    final rows = await _rpc<List<dynamic>>('customer_fingerprints', {'p_branch': branchId});
    return rows
        .map((r) => Fingerprint(r['customer_id'], r['currency'], (r['tx_count'] as num).toInt(), r['tx_sum'].toString()))
        .toList();
  }

  // ---------------- التحصيل والإعدادات ----------------
  Future<List<Map<String, dynamic>>> dueToday(String branchId) async =>
      List<Map<String, dynamic>>.from(await _rpc<List<dynamic>>('due_today', {'p_branch': branchId}));

  Future<Map<String, dynamic>> settings(String storeId) async =>
      await _t('store_settings').select().eq('store_id', storeId).single();

  Future<void> updateSettings(String storeId, Map<String, dynamic> values) async {
    try {
      await _t('store_settings').update(values).eq('store_id', storeId);
    } catch (e) {
      _rethrow(e);
    }
  }

  Future<void> updateStore(String storeId, Map<String, dynamic> values) async {
    try {
      await _t('stores').update(values).eq('id', storeId);
    } catch (e) {
      _rethrow(e);
    }
  }

  Future<Map<String, dynamic>> redeemCode(String code) async {
    try {
      return await _rpc<Map<String, dynamic>>('redeem_code', {'p_code': code});
    } catch (e) {
      _rethrow(e);
    }
  }

  Future<List<Map<String, dynamic>>> devices() async =>
      List<Map<String, dynamic>>.from(await _t('devices').select().order('created_at'));

  Future<void> setDevice(String id, {bool approve = false, bool revoke = false}) async {
    try {
      await _rpc('set_device_state', {'p_device': id, 'p_approve': approve, 'p_revoke': revoke});
    } catch (e) {
      _rethrow(e);
    }
  }

  Future<List<Map<String, dynamic>>> users() async =>
      List<Map<String, dynamic>>.from(await _t('app_users').select('*, user_branches(branch_id)').order('user_no'));

  Future<void> setEmployee(String id, bool active, {List<String>? branches}) async {
    try {
      await _rpc('set_employee', {'p_user': id, 'p_active': active, 'p_branches': branches});
    } catch (e) {
      _rethrow(e);
    }
  }

  Future<Branch> addBranch(String name) async {
    try {
      return Branch.fromJson(await _rpc<Map<String, dynamic>>('add_branch', {'p_name': name}));
    } catch (e) {
      _rethrow(e);
    }
  }

  /// قناة Realtime: أي حركة جديدة في الفرع ← مزامنة فورية
  RealtimeChannel subscribeBranch(String branchId, void Function() onChange) {
    final ch = client.channel('branch:$branchId');
    for (final table in const ['transactions', 'customers', 'promises']) {
      ch.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'app',
        table: table,
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'branch_id', value: branchId),
        callback: (_) => onChange(),
      );
    }
    return ch..subscribe();
  }
}
