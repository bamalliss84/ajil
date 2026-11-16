// لوحة إدارة منصة آجِل — للمالك فقط (مستخدم Auth مسجل في app.platform_admins)
// التشغيل: flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' as intl;
import 'package:supabase_flutter/supabase_flutter.dart';

const _url = String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://127.0.0.1:54321');
const _anon = String.fromEnvironment('SUPABASE_ANON_KEY');
const _green = Color(0xFF0F6E56);
const _red = Color(0xFFB03224);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  await Supabase.initialize(url: _url, anonKey: _anon);
  runApp(const AdminApp());
}

SupabaseClient get _sb => Supabase.instance.client;
PostgrestFilterBuilder<T> _rpc<T>(String fn, [Map<String, dynamic>? p]) => _sb.schema('app').rpc<T>(fn, params: p);

void _err(BuildContext context, Object e) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(backgroundColor: _red, content: Text(AjilError.parse(e is PostgrestException ? e.message : e).message)));

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'آجِل — إدارة المنصة',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: _green, primary: _green),
          textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(),
          scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        ),
        home: StreamBuilder<AuthState>(
          stream: _sb.auth.onAuthStateChange,
          builder: (_, __) => _sb.auth.currentSession == null ? const LoginPage() : const Shell(),
        ),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SizedBox(
            width: 380,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('آجِل — إدارة المنصة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(controller: _email, decoration: const InputDecoration(labelText: 'البريد')),
                  TextField(controller: _pw, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await _sb.auth.signInWithPassword(email: _email.text.trim(), password: _pw.text);
                      } catch (e) {
                        if (context.mounted) _err(context, e);
                      }
                    },
                    child: const Text('دخول'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: _i,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (i) => setState(() => _i = i),
            trailing: IconButton(onPressed: () => _sb.auth.signOut(), icon: const Icon(Icons.logout), tooltip: 'خروج'),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('الملخص')),
              NavigationRailDestination(icon: Icon(Icons.store_outlined), label: Text('البقالات')),
              NavigationRailDestination(icon: Icon(Icons.qr_code_2), label: Text('الأكواد')),
              NavigationRailDestination(icon: Icon(Icons.health_and_safety_outlined), label: Text('السلامة')),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: [const SummaryPage(), const StoresPage(), const CodesPage(), const AlertsPage()][_i]),
        ]),
      );
}

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _rpc<Map<String, dynamic>>('admin_summary'),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(AjilError.parse(snap.error).message));
          final s = snap.data;
          if (s == null) return const Center(child: CircularProgressIndicator());
          final f = const MoneyFormat();
          final cards = [
            ('البقالات', '${s['stores']}'),
            ('مشتركون يدفعون', '${s['paying']}'),
            ('في التجربة', '${s['trial']}'),
            ('منتهية', '${s['expired']}'),
            ('تنتهي خلال 7 أيام', '${s['expiring_7d']}'),
            ('الدخل الشهري المتوقع', '${f.amount(Decimal.parse('${s['mrr']}'), 'YER')} ر.ي'),
            ('حركات اليوم', '${s['tx_today']}'),
            ('تنبيهات سلامة مفتوحة', '${s['open_alerts']}'),
          ];
          return GridView.count(
            padding: const EdgeInsets.all(24),
            crossAxisCount: MediaQuery.sizeOf(context).width > 1100 ? 4 : 2,
            childAspectRatio: 2.4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              for (final (k, v) in cards)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(k, style: const TextStyle(color: Color(0xFF5B6B70))),
                      Text(v, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
            ],
          );
        },
      );
}

class StoresPage extends StatefulWidget {
  const StoresPage({super.key});
  @override
  State<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends State<StoresPage> {
  List<Map<String, dynamic>>? _rows;
  String _q = '';
  final _dt = intl.DateFormat('yyyy/MM/dd');

  Future<void> _load() async {
    try {
      final r = await _rpc<List<dynamic>>('admin_stores_overview');
      setState(() => _rows = List<Map<String, dynamic>>.from(r));
    } catch (e) {
      if (mounted) _err(context, e);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _activate(Map<String, dynamic> s) async {
    String plan = 'basic';
    int months = 1;
    final ref = TextEditingController();
    final extra = TextEditingController(text: '0');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text('تفعيل / تجديد: ${s['name']}'),
          content: SizedBox(
            width: 360,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField(
                value: plan,
                decoration: const InputDecoration(labelText: 'الباقة'),
                items: const [
                  DropdownMenuItem(value: 'basic', child: Text('أساسية — 200 زبون')),
                  DropdownMenuItem(value: 'advanced', child: Text('متقدمة — 500 زبون')),
                  DropdownMenuItem(value: 'premium', child: Text('مميزة — غير محدود')),
                ],
                onChanged: (v) => set(() => plan = v!),
              ),
              DropdownButtonFormField(
                value: months,
                decoration: const InputDecoration(labelText: 'المدة'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('شهر')),
                  DropdownMenuItem(value: 3, child: Text('3 أشهر')),
                  DropdownMenuItem(value: 6, child: Text('6 أشهر')),
                  DropdownMenuItem(value: 12, child: Text('سنة')),
                ],
                onChanged: (v) => set(() => months = v!),
              ),
              TextField(controller: extra, decoration: const InputDecoration(labelText: 'فروع إضافية'), keyboardType: TextInputType.number),
              TextField(controller: ref, decoration: const InputDecoration(labelText: 'مرجع الدفع (رقم الحوالة…)')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رجوع')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تفعيل')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _rpc('activate_subscription', {
        'p_store': s['store_id'],
        'p_plan': plan,
        'p_months': months,
        'p_payment_ref': ref.text.trim().isEmpty ? null : ref.text.trim(),
        'p_extra_branches': int.tryParse(extra.text) ?? 0,
      });
      await _load();
    } catch (e) {
      if (mounted) _err(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = (_rows ?? const <Map<String, dynamic>>[])
        .where((r) => _q.isEmpty || '${r['name']}'.contains(_q) || '${r['owner_phone']}'.contains(_q))
        .toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'بحث بالاسم أو الرقم'),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'تحديث'),
        ]),
      ),
      Expanded(
        child: _rows == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('البقالة')),
                      DataColumn(label: Text('الرقم')),
                      DataColumn(label: Text('الباقة')),
                      DataColumn(label: Text('تنتهي')),
                      DataColumn(label: Text('فروع')),
                      DataColumn(label: Text('زبائن')),
                      DataColumn(label: Text('مستخدمون')),
                      DataColumn(label: Text('آخر حركة')),
                      DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final r in rows)
                        DataRow(
                          color: WidgetStatePropertyAll(r['status'] == 'suspended' ? const Color(0xFFFCEDEB) : null),
                          cells: [
                            DataCell(Text('${r['name']}${r['status'] == 'suspended' ? ' (موقوفة)' : ''}')),
                            DataCell(SelectableText('${r['owner_phone']}')),
                            DataCell(Text('${r['plan_code'] ?? '—'}')),
                            DataCell(Text(
                              r['expires_at'] == null ? '—' : _dt.format(DateTime.parse(r['expires_at']).toLocal()),
                              style: TextStyle(
                                  color: r['expires_at'] != null && DateTime.parse(r['expires_at']).isBefore(DateTime.now()) ? _red : null),
                            )),
                            DataCell(Text('${r['branches']}')),
                            DataCell(Text('${r['customers']}')),
                            DataCell(Text('${r['users']}')),
                            DataCell(Text(r['last_tx_at'] == null ? '—' : _dt.format(DateTime.parse(r['last_tx_at']).toLocal()))),
                            DataCell(Row(children: [
                              TextButton(onPressed: () => _activate(r), child: const Text('تفعيل/تجديد')),
                              TextButton(
                                onPressed: () async {
                                  try {
                                    await _rpc('admin_set_store_status', {
                                      'p_store': r['store_id'],
                                      'p_status': r['status'] == 'suspended' ? 'active' : 'suspended',
                                    });
                                    await _load();
                                  } catch (e) {
                                    if (context.mounted) _err(context, e);
                                  }
                                },
                                child: Text(r['status'] == 'suspended' ? 'إعادة تفعيل' : 'إيقاف',
                                    style: TextStyle(color: r['status'] == 'suspended' ? _green : _red)),
                              ),
                            ])),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
      ),
    ]);
  }
}

class CodesPage extends StatefulWidget {
  const CodesPage({super.key});
  @override
  State<CodesPage> createState() => _CodesPageState();
}

class _CodesPageState extends State<CodesPage> {
  String _plan = 'basic';
  int _months = 1;
  final _count = TextEditingController(text: '10');
  final _agent = TextEditingController();
  List<String> _new = const [];
  List<Map<String, dynamic>> _all = const [];

  Future<void> _load() async {
    final r = await _sb.schema('app').from('activation_codes').select().order('created_at', ascending: false).limit(300);
    if (mounted) setState(() => _all = List<Map<String, dynamic>>.from(r));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
        const Text('توليد أكواد تفعيل (تُباع عند المندوبين)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: 200,
            child: DropdownButtonFormField(
              value: _plan,
              decoration: const InputDecoration(labelText: 'الباقة'),
              items: const [
                DropdownMenuItem(value: 'basic', child: Text('أساسية')),
                DropdownMenuItem(value: 'advanced', child: Text('متقدمة')),
                DropdownMenuItem(value: 'premium', child: Text('مميزة')),
              ],
              onChanged: (v) => setState(() => _plan = v!),
            ),
          ),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField(
              value: _months,
              decoration: const InputDecoration(labelText: 'المدة'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('شهر')),
                DropdownMenuItem(value: 3, child: Text('3 أشهر')),
                DropdownMenuItem(value: 12, child: Text('سنة')),
              ],
              onChanged: (v) => setState(() => _months = v!),
            ),
          ),
          SizedBox(width: 100, child: TextField(controller: _count, decoration: const InputDecoration(labelText: 'العدد'))),
          SizedBox(width: 200, child: TextField(controller: _agent, decoration: const InputDecoration(labelText: 'المندوب'))),
          FilledButton(
            onPressed: () async {
              try {
                final r = await _rpc<List<dynamic>>('generate_codes', {
                  'p_plan': _plan,
                  'p_months': _months,
                  'p_count': int.tryParse(_count.text) ?? 1,
                  'p_agent': _agent.text.trim().isEmpty ? null : _agent.text.trim(),
                });
                setState(() => _new = r.map((e) => e is Map ? e.values.first.toString() : e.toString()).toList());
                await _load();
              } catch (e) {
                if (context.mounted) _err(context, e);
              }
            },
            child: const Text('توليد'),
          ),
        ]),
        if (_new.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Expanded(child: Text('الأكواد الجديدة', style: TextStyle(fontWeight: FontWeight.w600))),
                  TextButton.icon(
                    onPressed: () => Clipboard.setData(ClipboardData(text: _new.join('\n'))),
                    icon: const Icon(Icons.copy),
                    label: const Text('نسخ الكل'),
                  ),
                ]),
                SelectableText(_new.join('\n'), style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text('كل الأكواد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        for (final c in _all)
          ListTile(
            dense: true,
            title: Text('${c['code']} · ${c['plan_code']} · ${c['months']} شهر', style: const TextStyle(fontFamily: 'monospace')),
            subtitle: Text('${c['agent'] ?? ''}'),
            trailing: Text(c['redeemed_at'] == null ? 'متاح' : 'مستخدم',
                style: TextStyle(color: c['redeemed_at'] == null ? _green : const Color(0xFF5B6B70))),
          ),
      ]);
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Map<String, dynamic>> _rows = const [];
  Future<void> _load() async {
    final r = await _sb.schema('app').from('integrity_alerts').select().eq('resolved', false).order('at', ascending: false);
    if (mounted) setState(() => _rows = List<Map<String, dynamic>>.from(r));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(24), children: [
        const Text('تنبيهات سلامة البيانات (الفحص اليومي)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const Text('سلسلة بصمات مكسورة = تعديل مباشر على قاعدة البيانات. عدم تطابق رصيد = خلل يحتاج مراجعة.',
            style: TextStyle(color: Color(0xFF5B6B70))),
        const SizedBox(height: 12),
        if (_rows.isEmpty) const Text('لا توجد تنبيهات ✓', style: TextStyle(color: _green, fontSize: 16)),
        for (final a in _rows)
          Card(
            child: ListTile(
              leading: Icon(a['kind'] == 'chain_broken' ? Icons.link_off : Icons.balance, color: _red),
              title: Text(a['kind'] == 'chain_broken' ? 'سلسلة بصمات مكسورة' : 'رصيد غير مطابق'),
              subtitle: SelectableText('${a['store_id']} · ${a['details']}'),
              trailing: TextButton(
                onPressed: () async {
                  await _rpc('admin_resolve_alert', {'p_id': a['id']});
                  await _load();
                },
                child: const Text('تمت المراجعة'),
              ),
            ),
          ),
      ]);
}
