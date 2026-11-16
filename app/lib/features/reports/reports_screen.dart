import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../data/repository.dart' show CustomerWithBalance;
import '../../services/report_export.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'period_picker.dart';
import 'report_sections.dart';
import 'report_state.dart';
import 'report_views.dart';

/// التقارير (docs/REPORTS_SPEC.md): يوم / شهر / سنة / من–إلى. الحساب في ajil_core والشاشة تعرض فقط.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  CustomerTab _tab = CustomerTab.payers;
  bool _busy = false;

  DateTime get _today => DateTime.now();
  void _set(ReportPeriod p) => ref.read(reportPeriodProvider.notifier).state = p;

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(sessionProvider).session!;
    final f = ref.watch(moneyFormatProvider);
    final today = _today;
    final period = ref.watch(reportPeriodProvider) ?? ReportPeriod.currentMonth(today);
    final currency = ref.watch(reportCurrencyProvider) ?? w.defaultCurrency;
    final report = ref.watch(periodReportProvider);
    final r = report.valueOrNull;
    final fresh = r != null && r.period == period && r.currency == currency;
    final names = ref.watch(reportUserNamesProvider).valueOrNull ?? const {};
    final customers = {for (final c in ref.watch(customersProvider).valueOrNull ?? const <CustomerWithBalance>[]) c.customer.id: c.customer};

    return Scaffold(
      bottomNavigationBar: const AjilNavBar(index: 2),
      // الهيدر يتمرر مع المحتوى (في الوضع الأفقي أو الشاشات القصيرة لا يأكل الشاشة)
      body: ListView(padding: const EdgeInsets.only(bottom: 16), children: [
        _header(w, f, period, currency, today, fresh ? r : null),
        SizedBox(height: 2, child: report.isLoading && r != null ? const LinearProgressIndicator(minHeight: 2) : null),
        if (r == null)
          report.hasError
              ? Padding(padding: const EdgeInsets.all(24), child: Text('تعذّر حساب التقرير: ${report.error}'))
              : const ReportSkeleton()
        else
          ..._body(w, f, r, names, customers),
      ]),
    );
  }

  // ------------------------------------------------------------------ المحتوى

  List<Widget> _body(WorkSession w, MoneyFormat f, PeriodReport r, Map<String, String> names, Map<String, Customer> customers) {
    switch (r.period.kind) {
      case PeriodKind.day:
        return [
          DayKpis(r, f),
          HourlyChart(r, f),
          DayTxList(r, f, names: names, customers: customers),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () => _shareDay(w, f, r),
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              label: const Text('مشاركة ملخص اليوم'),
            ),
          ),
        ];
      case PeriodKind.year:
        return [
          YearSummary(r, f),
          MonthlyChart(r, f, onMonth: (m) => _set(ReportPeriod.month(r.period.start.year, m))),
          MonthList(r, f, onMonth: (m) => _set(ReportPeriod.month(r.period.start.year, m))),
          ExportButtons(busy: _busy, onPdf: () => _export(r, pdf: true), onExcel: () => _export(r, pdf: false)),
        ];
      case PeriodKind.month:
      case PeriodKind.range:
        return [
          SummaryCard(r, f),
          if (r.daily.isNotEmpty) DailyChart(r, f, onDay: (d) => _set(ReportPeriod.day(d))),
          KindsCard(r, f),
          PromisesCard(r, f),
          CustomersCard(r, f, tab: _tab, onTab: (t) => setState(() => _tab = t)),
          if (w.isOwner) UsersCard(r, f, names: names),
          AgingCard(r, f),
          ExportButtons(busy: _busy, onPdf: () => _export(r, pdf: true), onExcel: () => _export(r, pdf: false)),
        ];
    }
  }

  // ------------------------------------------------------------------ الهيدر

  Widget _header(WorkSession w, MoneyFormat f, ReportPeriod period, String currency, DateTime today, PeriodReport? r) {
    final hasNext = period.hasNext(today);
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AjilColors.headerBorder))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('التقارير', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  Text('${w.storeName} · ${w.branch.name}', style: const TextStyle(fontSize: 13, color: AjilColors.textMuted)),
                ]),
              ),
              SquareIconButton(
                icon: Icons.ios_share_rounded,
                tooltip: 'مشاركة التقرير PDF أو Excel',
                color: AjilColors.text,
                onPressed: r == null || _busy ? null : () => _exportSheet(r),
              ),
            ]),
            const SizedBox(height: 12),
            AjilSegmented<PeriodKind>(
              options: const [(PeriodKind.day, 'يوم'), (PeriodKind.month, 'شهر'), (PeriodKind.year, 'سنة')],
              value: period.kind,
              fontSize: 15,
              selectedFg: AjilColors.primaryDark,
              shadow: true,
              onChanged: (k) => _set(ReportPeriod.of(k, period.effectiveEnd(today))),
            ),
            const SizedBox(height: 12),
            Row(children: [
              SquareIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'الفترة السابقة',
                color: AjilColors.text,
                onPressed: () => _set(period.prev()),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Material(
                  color: AjilColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _pick(period, currency, f),
                    child: SizedBox(
                      height: 44,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: AjilColors.primaryDark),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(periodLabel(f, period, today),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AjilColors.primaryDark)),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AjilColors.primaryDark),
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SquareIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: hasNext ? 'الفترة التالية' : 'الفترة التالية (غير متاحة، هذه الفترة الحالية)',
                color: hasNext ? AjilColors.text : RC.disabled,
                borderColor: hasNext ? AjilColors.border : AjilColors.divider,
                onPressed: hasNext ? () => _set(period.next()) : null,
              ),
            ]),
            if (period.kind == PeriodKind.month) ...[const SizedBox(height: 12), _monthStrip(f, period, today)],
            if (period.kind == PeriodKind.day) ...[const SizedBox(height: 12), _weekStrip(f, period, today)],
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Text(_info(f, period, today, r), style: const TextStyle(fontSize: 13, color: AjilColors.textMuted)),
              ),
              if (w.enabledCurrencies.length > 1)
                _CurrencyMini(
                  currencies: w.enabledCurrencies,
                  value: currency,
                  onChanged: (c) => ref.read(reportCurrencyProvider.notifier).state = c,
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  /// شريط آخر 12 شهراً
  Widget _monthStrip(MoneyFormat f, ReportPeriod period, DateTime today) {
    final months = [for (var i = 0; i < 12; i++) DateTime(today.year, today.month - i)];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: months.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final m = months[i];
          final sel = period.start.year == m.year && period.start.month == m.month;
          return PillChip(
            label: '${monthNames[m.month - 1]}${m.year == today.year ? '' : ' ${f.digits('${m.year}')}'}',
            selected: sel,
            selectedColor: AjilColors.primary,
            fontSize: 14,
            onTap: () => _set(ReportPeriod.month(m.year, m.month)),
          );
        },
      ),
    );
  }

  /// شريط أيام الأسبوع (يبدأ السبت) مع نقطة تحت كل يوم فيه حركات
  Widget _weekStrip(MoneyFormat f, ReportPeriod period, DateTime today) {
    final d = period.start;
    final start = DateTime(d.year, d.month, d.day - (d.weekday + 1) % 7);
    final days = [for (var i = 0; i < 7; i++) DateTime(start.year, start.month, start.day + i)];
    final txs = ref.watch(branchTxsProvider).valueOrNull ?? const <LedgerTx>[];
    final active = PeriodReport.activeDays(txs, days.first, days.last);
    final t0 = DateTime(today.year, today.month, today.day);
    return Row(children: [
      for (var i = 0; i < 7; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(child: _dayTile(f, days[i], sameDay(days[i], d), days[i].isAfter(t0), active.contains(days[i]))),
      ],
    ]);
  }

  Widget _dayTile(MoneyFormat f, DateTime day, bool sel, bool future, bool active) {
    final bg = sel ? AjilColors.primary : Colors.white;
    final fg = sel ? Colors.white : (future ? RC.disabled : AjilColors.text);
    final border = sel ? AjilColors.primary : (future ? AjilColors.divider : AjilColors.border);
    final dot = !active ? Colors.transparent : (sel ? RC.progress : AjilColors.paid);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: future ? null : () => _set(ReportPeriod.day(day)),
        child: SizedBox(
          height: 58,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(dayShort[day.weekday - 1], style: TextStyle(fontSize: 11, color: fg.withOpacity(0.85))),
            Text(f.digits('${day.day}'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg, height: 1.2)),
            const SizedBox(height: 2),
            Container(width: 5, height: 5, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          ]),
        ),
      ),
    );
  }

  String _info(MoneyFormat f, ReportPeriod p, DateTime today, PeriodReport? r) {
    final eff = p.effectiveEnd(today);
    switch (p.kind) {
      case PeriodKind.month:
        final m = monthNames[p.start.month - 1];
        return p.isPartial(today)
            ? f.digits('1 – ${eff.day} $m · الشهر الحالي')
            : f.digits('1 – ${p.end.day} $m${p.start.year == today.year ? '' : ' ${p.start.year}'}');
      case PeriodKind.day:
        final last = r?.lastTxAt;
        final head = sameDay(p.start, today) ? 'اليوم · ' : '';
        if (r == null) return head;
        return last == null
            ? '$headلا حركات'
            : '$headآخر حركة ${hour12(f, last.hour)}:${f.digits(last.minute.toString().padLeft(2, '0'))} ${ampm(last.hour)}';
      case PeriodKind.year:
        return f.digits('يناير – ${monthNames[eff.month - 1]} ${p.start.year} · مقارنة بـ ${p.start.year - 1}');
      case PeriodKind.range:
        return '${counted(f, eff.difference(p.start).inDays + 1, 'يوم', 'يومان', 'أيام', 'يوماً')} · مقارنة بالفترة السابقة';
    }
  }

  // ------------------------------------------------------------------ أفعال

  Future<void> _pick(ReportPeriod period, String currency, MoneyFormat f) async {
    final txs = ref.read(branchTxsProvider).valueOrNull ?? const <LedgerTx>[];
    final p = await showPeriodPicker(context, current: period, txs: txs, currency: currency, f: f);
    if (p != null) _set(p);
  }

  Future<void> _exportSheet(PeriodReport r) async {
    final v = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.description_outlined, color: AjilColors.primary),
            title: const Text('تقرير PDF'),
            subtitle: const Text('نفس أقسام الشاشة — للمشاركة أو الطباعة'),
            onTap: () => Navigator.pop(ctx, true),
          ),
          ListTile(
            leading: const Icon(Icons.grid_on_rounded, color: AjilColors.primary),
            title: const Text('Excel'),
            subtitle: const Text('ورقة لكل قسم + كل حركات الفترة'),
            onTap: () => Navigator.pop(ctx, false),
          ),
        ]),
      ),
    );
    if (v != null) await _export(r, pdf: v);
  }

  Future<void> _export(PeriodReport r, {required bool pdf}) async {
    final w = sessionOf(ref);
    final names = ref.read(reportUserNamesProvider).valueOrNull ?? const {};
    final customers = {
      for (final c in ref.read(customersProvider).valueOrNull ?? const <CustomerWithBalance>[]) c.customer.id: c.customer.name
    };
    setState(() => _busy = true);
    try {
      if (ref.read(sessionProvider).pending > 0 && mounted) {
        showOk(context, 'تنبيه: توجد حركات غير متزامنة — التقرير محسوب من هذا الجوال');
      }
      pdf
          ? await ReportExport.sharePdf(r, session: w, users: names)
          : await ReportExport.shareExcel(r, session: w, users: names, customerNames: customers);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareDay(WorkSession w, MoneyFormat f, PeriodReport r) async {
    final sym = Currency.of(r.currency).symbolAr;
    final net = r.net;
    final text = [
      'ملخص ${w.storeName} — ${periodLabel(f, r.period, r.today)}',
      'التحصيل: ${f.amount(r.collected, r.currency)} $sym (${ops(f, r.collectedCount)})',
      'الديون الجديدة: ${f.amount(r.newDebt, r.currency)} $sym (${ops(f, r.debtCount)})',
      net == Decimal.zero
          ? 'الصافي: بدون تغيير'
          : 'الصافي: ${net > Decimal.zero ? 'انخفضت الديون' : 'زادت الديون'} ${f.amount(net.abs(), r.currency)} $sym',
      'الديون عند الزبائن: ${f.amount(r.closingDebt, r.currency)} $sym',
      '— آجِل',
    ].join('\n');
    await Share.share(text, subject: 'ملخص اليوم');
  }
}

/// تبديل العملة الصغير (ر.ي | ر.س)
class _CurrencyMini extends StatelessWidget {
  const _CurrencyMini({required this.currencies, required this.value, required this.onChanged});
  final List<String> currencies;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: AjilColors.track, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final c in currencies)
            GestureDetector(
              onTap: () => onChanged(c),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c == value ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                child: Text(Currency.of(c).symbolAr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: c == value ? FontWeight.w600 : FontWeight.w400,
                      color: c == value ? AjilColors.primaryDark : AjilColors.textMuted,
                    )),
              ),
            ),
        ]),
      );
}
