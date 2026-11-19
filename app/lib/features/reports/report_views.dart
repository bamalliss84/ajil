import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'report_sections.dart';
import 'report_state.dart';

// ================================================================== عرض اليوم

class DayKpis extends StatelessWidget {
  const DayKpis(this.r, this.f, {super.key});
  final PeriodReport r;
  final MoneyFormat f;
  @override
  Widget build(BuildContext context) {
    final sym = Currency.of(r.currency).symbolAr;
    final isToday = sameDay(r.period.start, r.today);
    Widget kpi(String label, Decimal v, Color c, int n) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: context.ajil.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 13, color: context.ajil.textMuted)),
              const SizedBox(height: 2),
              Text(f.amount(v, r.currency), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: c)),
              const SizedBox(height: 2),
              Text('$sym · ${ops(f, n)}', style: TextStyle(fontSize: 12, color: context.ajil.textMuted)),
            ]),
          ),
        );
    final net = r.net;
    final (netLabel, netColor) = net > Decimal.zero
        ? ('الديون انخفضت', context.ajil.paid)
        : net < Decimal.zero
            ? ('الديون زادت', context.ajil.debt)
            : ('بدون تغيير', context.ajil.text);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(children: [
        Row(children: [
          kpi(isToday ? 'تحصيل اليوم' : 'التحصيل', r.collected, context.ajil.paid, r.collectedCount),
          const SizedBox(width: 10),
          kpi(isToday ? 'ديون اليوم' : 'الديون', r.newDebt, context.ajil.debt, r.debtCount),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: context.ajil.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Expanded(child: Text('صافي اليوم: $netLabel', style: const TextStyle(fontSize: 14))),
            Text(f.amount(net.abs(), r.currency, withSymbol: true),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: netColor)),
          ]),
        ),
      ]),
    );
  }
}

class HourlyChart extends StatelessWidget {
  const HourlyChart(this.r, this.f, {super.key});
  final PeriodReport r;
  final MoneyFormat f;
  @override
  Widget build(BuildContext context) {
    final h = r.hourly;
    var first = 7, last = 22;
    for (final b in h) {
      if (b.count > 0) {
        if (b.at.hour < first) first = b.at.hour;
        if (b.at.hour > last) last = b.at.hour;
      }
    }
    final bars = h.sublist(first, last + 1);
    final max = bars.fold<int>(1, (m, b) => b.count > m ? b.count : m);
    // نافذة الساعتين الأكثر نشاطاً
    var peak = -1, peakSum = 0;
    for (var i = 0; i + 1 < 24; i++) {
      final s = h[i].count + h[i + 1].count;
      if (s > peakSum) {
        peakSum = s;
        peak = i;
      }
    }
    final span = last - first;
    final ticks = [for (var i = 0; i < 5; i++) first + (span * i / 4).round()];
    String label(int hr) => '${hour12(f, hr)} ${ampm(hr)}';
    String part(int hr) => hr < 12 ? 'صباحاً' : (hr < 17 ? 'ظهراً' : 'مساءً');

    return ReportCard(children: [
      const SectionHead('حسب الساعة'),
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 80,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final b in bars)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FractionallySizedBox(
                    heightFactor: b.count == 0 ? 0.08 : (b.count / max).clamp(0.08, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: b.count >= max * 0.7 && b.count > 0 ? context.ajil.accent : context.ajil.chartLight,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final t in ticks) Text(label(t), style: TextStyle(fontSize: 11, color: context.ajil.textMuted)),
        ]),
      ),
      Text(
        peak < 0 ? 'لا حركات في هذا اليوم' : 'الذروة بين ${hour12(f, peak)} و ${hour12(f, peak + 2)} ${part(peak + 1)}',
        style: TextStyle(fontSize: 13, color: context.ajil.textMuted),
      ),
    ]);
  }
}

class DayTxList extends StatefulWidget {
  const DayTxList(this.r, this.f, {super.key, required this.names, required this.customers});
  final PeriodReport r;
  final MoneyFormat f;
  final Map<String, String> names;
  final Map<String, Customer> customers;
  @override
  State<DayTxList> createState() => _DayTxListState();
}

class _DayTxListState extends State<DayTxList> {
  bool _all = false;
  @override
  Widget build(BuildContext context) {
    final r = widget.r, f = widget.f;
    final txs = r.txs;
    final shown = _all ? txs : txs.take(6).toList();
    return ReportCard(padded: false, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Row(children: [
          const Expanded(child: Text('حركات اليوم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          Text(counted(f, txs.length, 'حركة', 'حركتان', 'حركات'), style: TextStyle(fontSize: 13, color: context.ajil.textMuted)),
        ]),
      ),
      if (txs.isEmpty)
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: context.ajil.divider))),
          child: Text('لا حركات في هذا اليوم', style: TextStyle(fontSize: 13, color: context.ajil.textMuted)),
        ),
      for (final t in shown) _row(t),
      if (!_all && txs.length > 6)
        InkWell(
          onTap: () => setState(() => _all = true),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border(top: BorderSide(color: context.ajil.divider))),
            child: Text('عرض كل الحركات (${f.digits('${txs.length}')})',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.ajil.primary)),
          ),
        ),
    ]);
  }

  Widget _row(LedgerTx t) {
    final f = widget.f;
    final c = widget.customers[t.customerId];
    final (name, bg, fg, color) = switch (t.kind) {
      TxKind.debt => ('دين', context.ajil.debtBg, context.ajil.debtTag, context.ajil.debt),
      TxKind.payment || TxKind.paymentFx => ('سداد', context.ajil.paidBg, context.ajil.paid, context.ajil.paid),
      TxKind.opening => ('افتتاحي', context.ajil.infoBg, context.ajil.infoText, context.ajil.infoText),
      TxKind.voided => ('إلغاء', context.ajil.pendingBg, context.ajil.pendingText, context.ajil.pendingText),
      TxKind.returned => ('مرتجع', context.ajil.track, context.ajil.text, context.ajil.text),
      TxKind.discount => ('خصم', context.ajil.track, context.ajil.text, context.ajil.text),
    };
    final h = t.createdAt.hour;
    final time = '${hour12(f, h)}:${f.digits(t.createdAt.minute.toString().padLeft(2, '0'))} ${ampm(h)}';
    final user = widget.names[t.createdBy]?.split(' (').first;
    final sub = [time, if ((t.description ?? '').isNotEmpty) t.description!, if (user != null) user].join(' · ');
    return InkWell(
      onTap: c == null ? null : () => context.push('/customers/${t.customerId}'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.ajil.divider))),
        child: Row(children: [
          SizedBox(width: 58, child: Align(alignment: AlignmentDirectional.centerStart, child: FittedBox(fit: BoxFit.scaleDown, child: TypeBadge(name, bg: bg, fg: fg)))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c?.name ?? 'زبون', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.ajil.textMuted)),
            ]),
          ),
          Text(f.amount(t.amount, t.currency), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }
}

// ================================================================== عرض السنة

class YearSummary extends StatelessWidget {
  const YearSummary(this.r, this.f, {super.key});
  final PeriodReport r;
  final MoneyFormat f;
  @override
  Widget build(BuildContext context) {
    final vs = comparisonName(r);
    String change(int? pct) {
      if (pct == null) return '';
      final arrow = pct > 0 ? '↑' : (pct < 0 ? '↓' : '=');
      return '$arrow ${f.digits('${pct.abs()}')}% عن $vs';
    }

    Widget cell(String label, String value, [String? sub]) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 13, color: context.ajil.onHeaderMuted)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: context.ajil.onPrimary)),
            if (sub != null && sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(fontSize: 12, color: context.ajil.onHeaderMuted)),
            ],
          ]),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.ajil.header, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          cell('تحصيل السنة', f.amount(r.collected, r.currency), change(r.collectedChange)),
          const SizedBox(width: 12),
          cell('ديون جديدة', f.amount(r.newDebt, r.currency), change(r.debtChange)),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          cell('زبائن جدد', f.digits('${r.newCustomers}')),
          const SizedBox(width: 12),
          cell('متوسط مدة السداد',
              r.avgPayDays == null ? '—' : counted(f, r.avgPayDays!, 'يوم', 'يومان', 'أيام', 'يوماً')),
        ]),
      ]),
    );
  }
}

class MonthlyChart extends StatelessWidget {
  const MonthlyChart(this.r, this.f, {super.key, required this.onMonth});
  final PeriodReport r;
  final MoneyFormat f;
  final ValueChanged<int> onMonth;
  @override
  Widget build(BuildContext context) {
    final months = r.monthly;
    final max = months.fold<double>(1, (m, b) => b.collected.toDouble() > m ? b.collected.toDouble() : m);
    final eff = r.effectiveEnd;
    final year = r.period.start.year;
    final best = r.bestMonth;
    final current = r.period.contains(r.today);
    bool future(int m) => DateTime(year, m).isAfter(eff);
    final highlight = current ? r.today.month : best?.at.month;
    final sym = Currency.of(r.currency).symbolAr;
    return ReportCard(children: [
      SectionHead('التحصيل الشهري', trailing: 'ألف $sym · اضغط شهراً لفتحه'),
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 150,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final b in months)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: future(b.at.month) ? null : () => onMonth(b.at.month),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (!future(b.at.month))
                        FittedBox(fit: BoxFit.scaleDown, child: Text(thousands(f, b.collected), maxLines: 1, softWrap: false, style: TextStyle(fontSize: 10, color: context.ajil.textMuted))),
                      const SizedBox(height: 4),
                      Container(
                        height: future(b.at.month) ? 0 : (b.collected.toDouble() / max * 118).clamp(3, 118),
                        decoration: BoxDecoration(
                          color: b.at.month == highlight ? context.ajil.accent : context.ajil.chartLight,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          for (var m = 1; m <= 12; m++)
            Expanded(
              child: Text(monthShort[m - 1],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: future(m) ? context.ajil.axis : context.ajil.textMuted)),
            ),
        ]),
      ),
      if (best != null)
        BestStrip(
          label: 'أفضل شهر: ',
          bold: monthNames[best.at.month - 1],
          suffix: current && best.at.month == r.today.month ? ' (حتى الآن)' : '',
          value: f.amount(best.collected, r.currency, withSymbol: true),
        ),
    ]);
  }
}

class MonthList extends StatelessWidget {
  const MonthList(this.r, this.f, {super.key, required this.onMonth});
  final PeriodReport r;
  final MoneyFormat f;
  final ValueChanged<int> onMonth;
  @override
  Widget build(BuildContext context) {
    final eff = r.effectiveEnd;
    final year = r.period.start.year;
    final rows = r.monthly.where((b) => !DateTime(year, b.at.month).isAfter(eff)).toList().reversed.toList();
    return ReportCard(padded: false, children: [
      const SectionHead('الأشهر', padding: EdgeInsets.fromLTRB(14, 14, 14, 6)),
      for (final b in rows)
        InkWell(
          onTap: () => onMonth(b.at.month),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: context.ajil.divider))),
            child: Row(children: [
              Expanded(
                child: Text(
                  '${monthNames[b.at.month - 1]}${r.period.contains(r.today) && b.at.month == r.today.month ? ' (الحالي)' : ''}',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              Text(f.amount(b.collected, r.currency),
                  style: TextStyle(fontSize: 13, color: context.ajil.paid, fontWeight: FontWeight.w600)),
              SizedBox(
                width: 84,
                child: Text(f.amount(b.debt, r.currency),
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 13, color: context.ajil.debt, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: context.ajil.textMuted),
            ]),
          ),
        ),
    ]);
  }
}
