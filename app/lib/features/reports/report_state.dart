import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';

/// الفترة المختارة — تبقى أثناء الجلسة فقط (null = الشهر الحالي، وهو الافتراضي عند كل فتح للتطبيق)
final reportPeriodProvider = StateProvider<ReportPeriod?>((ref) => null);

/// العملة المختارة (null = عملة البقالة الافتراضية)
final reportCurrencyProvider = StateProvider<String?>((ref) => null);

/// كل الوعود (المفتوحة والموفى بها والملغاة) لحساب «وعود السداد»
final allPromisesProvider = StreamProvider.autoDispose<List<PaymentPromise>>((ref) {
  return ref.watch(sessionProvider).repo!.watchPromises(openOnly: false);
});

/// أسماء المستخدمين لقسم «حسب المستخدم» (من الخادم إن توفر الاتصال، وإلا اسم المستخدم الحالي فقط)
final reportUserNamesProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final s = ref.read(sessionProvider);
  final w = s.session!;
  final names = {w.appUserId: '${w.displayName} (${w.isOwner ? 'المالك' : 'موظف'})'};
  try {
    for (final u in await s.api.users()) {
      names[u['id'] as String] = '${u['display_name']} (${u['role'] == 'owner' ? 'المالك' : 'موظف'})';
    }
  } catch (_) {
    // أوفلاين: نكتفي بما نعرفه
  }
  return names;
});

typedef _Args = ({
  ReportPeriod period,
  DateTime today,
  String currency,
  List<Customer> customers,
  List<LedgerTx> txs,
  List<PaymentPromise> promises,
});

PeriodReport _build(_Args a) => PeriodReport.build(
      period: a.period,
      today: a.today,
      currency: a.currency,
      customers: a.customers,
      txs: a.txs,
      promises: a.promises,
    );

/// التقرير المحسوب. يُحسب في Isolate للسنة أو الفروع الكبيرة حتى لا تتجمد الواجهة.
final periodReportProvider = FutureProvider.autoDispose<PeriodReport>((ref) async {
  final w = ref.watch(sessionProvider).session!;
  final today = DateTime.now();
  final period = ref.watch(reportPeriodProvider) ?? ReportPeriod.currentMonth(today);
  final currency = ref.watch(reportCurrencyProvider) ?? w.defaultCurrency;
  final txs = await ref.watch(branchTxsProvider.future);
  final customers = (await ref.watch(customersProvider.future)).map((c) => c.customer).toList();
  final promises = await ref.watch(allPromisesProvider.future);
  final args = (period: period, today: today, currency: currency, customers: customers, txs: txs, promises: promises);
  if (kIsWeb || (period.kind != PeriodKind.year && txs.length < 3000)) return _build(args);
  return compute(_build, args);
});

// ------------------------------------------------------------------ تنسيق

const monthNames = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const monthShort = ['ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون', 'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس'];
// DateTime.weekday: 1 = الاثنين … 7 = الأحد
const dayNames = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
const dayShort = ['اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];

String dayName(DateTime d) => dayNames[d.weekday - 1];

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// عدد مع المعدود بالعربية: 1 عملية، 2 عمليتان، 3–10 عمليات، 11+ عملية
String counted(MoneyFormat f, int n, String one, String two, String few, [String? many]) {
  if (n == 1) return '${f.digits('1')} $one';
  if (n == 2) return two;
  if (n >= 3 && n <= 10) return '${f.digits('$n')} $few';
  return '${f.digits('$n')} ${many ?? one}';
}

String ops(MoneyFormat f, int n) => counted(f, n, 'عملية', 'عمليتان', 'عمليات');

/// المبلغ بالألف: 647 ألف، 0.5
String thousands(MoneyFormat f, Decimal v) {
  final k = v.toDouble() / 1000;
  final s = k.abs() >= 10 || k == k.roundToDouble() ? k.round().toString() : k.toStringAsFixed(1);
  return f.digits(s);
}

String hour12(MoneyFormat f, int h) => f.digits('${h % 12 == 0 ? 12 : h % 12}');
String ampm(int h) => h < 12 ? 'ص' : 'م';

/// اسم فترة المقارنة في «↑ 12% عن أكتوبر»
String comparisonName(PeriodReport r) {
  final c = r.comparisonPeriod;
  return switch (r.period.kind) {
    PeriodKind.month => monthNames[c.start.month - 1],
    PeriodKind.year => '${c.start.year}',
    PeriodKind.day => sameDay(c.start, r.today.subtract(const Duration(days: 1))) ? 'أمس' : dayName(c.start),
    PeriodKind.range => 'الفترة السابقة',
  };
}

/// اسم الفترة في زر الاختيار
String periodLabel(MoneyFormat f, ReportPeriod p, DateTime today) => f.digits(switch (p.kind) {
      PeriodKind.day => '${dayName(p.start)} ${p.start.day} ${monthNames[p.start.month - 1]}${p.start.year == today.year ? '' : ' ${p.start.year}'}',
      PeriodKind.month => '${monthNames[p.start.month - 1]} ${p.start.year}',
      PeriodKind.year => 'سنة ${p.start.year}',
      PeriodKind.range => '${p.start.day}/${p.start.month} – ${p.end.day}/${p.end.month}/${p.end.year}',
    });
