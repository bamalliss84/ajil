import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'report_state.dart';

/// ألوان التقارير (docs/design/Reports*.dc.html)
class RC {
  static const tile = Color(0xFF1A7D64);
  static const progress = Color(0xFF9FE0C6);
  static const debtBar = Color(0xFFD9776B);
  static const axis = Color(0xFFB7C2BF);
  static const axisEmpty = Color(0xFFE3E9E7);
  static const disabled = Color(0xFFB7C2BF);
}

/// بطاقة بيضاء بقسم وعنوان
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.children, this.padded = true, this.gap = 10});
  final List<Widget> children;
  final bool padded;
  final double gap;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: padded ? const EdgeInsets.all(14) : EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0 && padded) SizedBox(height: gap), children[i]],
        ]),
      );
}

class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key, this.trailing, this.padding = EdgeInsets.zero});
  final String title;
  final String? trailing;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 12, color: AjilColors.textMuted)),
        ]),
      );
}

/// سطر رمادي: «أفضل يوم تحصيل: الخميس 12 ··· 71,000 ر.ي»
class BestStrip extends StatelessWidget {
  const BestStrip({super.key, required this.label, required this.bold, required this.value, this.suffix = ''});
  final String label, bold, value, suffix;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: AjilColors.background, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(
            child: Text.rich(
              TextSpan(style: const TextStyle(fontSize: 13), children: [
                TextSpan(text: label),
                TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: suffix),
              ]),
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 13, color: AjilColors.paid, fontWeight: FontWeight.w600)),
        ]),
      );
}

String _change(MoneyFormat f, int? pct, String vs) {
  if (pct == null) return '';
  final arrow = pct > 0 ? '↑' : (pct < 0 ? '↓' : '=');
  return '$arrow ${f.digits('${pct.abs()}')}% عن $vs';
}

// ------------------------------------------------------------------ الملخص الأخضر (شهر / فترة / يوم)

class SummaryCard extends StatelessWidget {
  const SummaryCard(this.r, this.f, {super.key});
  final PeriodReport r;
  final MoneyFormat f;
  @override
  Widget build(BuildContext context) {
    final sym = Currency.of(r.currency).symbolAr;
    final diff = r.closingDebt - r.openingDebt;
    final unit = r.period.kind == PeriodKind.month ? 'الشهر' : 'الفترة';
    final trend = diff < Decimal.zero
        ? ' · انخفضت ${f.amount(-diff, r.currency)} ✓'
        : diff > Decimal.zero
            ? ' · ارتفعت ${f.amount(diff, r.currency)}'
            : ' · بدون تغيير';
    final vs = comparisonName(r);
    final ratio = r.collectionRatio;
    const muted = TextStyle(fontSize: 13, color: AjilColors.onPrimaryMuted);

    Widget tile(String label, Decimal v, int? pct, int count) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: RC.tile, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: muted),
            const SizedBox(height: 2),
            Text(f.amount(v, r.currency), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 2),
            Text([_change(f, pct, vs), ops(f, count)].where((s) => s.isNotEmpty).join(' · '),
                style: const TextStyle(fontSize: 12, color: AjilColors.onPrimaryMuted)),
          ]),
        );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AjilColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('الديون عند الزبائن نهاية $unit', style: const TextStyle(fontSize: 14, color: AjilColors.onPrimaryMuted)),
        const SizedBox(height: 2),
        Text.rich(TextSpan(style: const TextStyle(color: Colors.white), children: [
          TextSpan(text: f.amount(r.closingDebt, r.currency), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, height: 1.3)),
          TextSpan(text: ' $sym', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ])),
        const SizedBox(height: 2),
        Text('كانت ${f.amount(r.openingDebt, r.currency)} في بداية $unit$trend', style: muted),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: tile('التحصيل', r.collected, r.collectedChange, r.collectedCount)),
            const SizedBox(width: 10),
            Expanded(child: tile('ديون جديدة', r.newDebt, r.debtChange, r.debtCount)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          const Expanded(child: Text('نسبة التحصيل إلى الديون الجديدة', style: muted)),
          Text(ratio == null ? '—' : '${f.digits('$ratio')}%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio == null ? 0 : (ratio / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: RC.tile,
            color: RC.progress,
          ),
        ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ الحركة اليومية

class DailyChart extends StatelessWidget {
  const DailyChart(this.r, this.f, {super.key, required this.onDay});
  final PeriodReport r;
  final MoneyFormat f;
  final ValueChanged<DateTime> onDay;
  @override
  Widget build(BuildContext context) {
    final days = r.daily;
    var max = Decimal.one;
    for (final d in days) {
      if (d.collected > max) max = d.collected;
      if (d.debt > max) max = d.debt;
    }
    final m = max.toDouble();
    final eff = r.effectiveEnd;
    final best = r.bestDay;
    final n = days.length;
    final labels = r.period.kind == PeriodKind.month
        ? [1, 5, 10, 15, 20, 25, if (n >= 30) 30]
        : [1, (n / 2).ceil(), n];

    Widget legend(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(fontSize: 12, color: AjilColors.textMuted)),
        ]);

    return ReportCard(children: [
      const SectionHead('الحركة اليومية', trailing: 'اضغط على يوم لتفاصيله'),
      Row(children: [legend(AjilColors.paid, 'تحصيل'), const SizedBox(width: 14), legend(RC.debtBar, 'ديون جديدة')]),
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 170,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final d in days)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: d.at.isAfter(eff) ? null : () => onDay(d.at),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Column(children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: d.collected.toDouble() / m,
                            widthFactor: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: sameDay(d.at, r.today) ? AjilColors.primary : AjilColors.paid,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(height: 1, color: d.at.isAfter(eff) ? RC.axisEmpty : RC.axis),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: FractionallySizedBox(
                            heightFactor: d.debt.toDouble() / m,
                            widthFactor: 1,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: RC.debtBar,
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(3)),
                              ),
                            ),
                          ),
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
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final l in labels)
            Text(f.digits(r.period.kind == PeriodKind.month ? '$l' : '${days[l - 1].at.day}/${days[l - 1].at.month}'),
                style: const TextStyle(fontSize: 11, color: AjilColors.textMuted)),
        ]),
      ),
      if (best != null)
        BestStrip(
          label: 'أفضل يوم تحصيل: ',
          bold: f.digits('${dayName(best.at)} ${best.at.day}'),
          value: f.amount(best.collected, r.currency, withSymbol: true),
        ),
    ]);
  }
}

// ------------------------------------------------------------------ ملخص الحركات

class KindsCard extends StatelessWidget {
  const KindsCard(this.r, this.f, {super.key});
  final PeriodReport r;
  final MoneyFormat f;
  @override
  Widget build(BuildContext context) {
    return ReportCard(padded: false, children: [
      const SectionHead('ملخص الحركات', padding: EdgeInsets.fromLTRB(14, 14, 14, 6)),
      for (final k in r.kinds) _row(k),
    ]);
  }

  Widget _row(KindSummary k) {
    final (name, bg, fg, color) = switch (k.kind) {
      TxKind.payment => ('سداد', AjilColors.paidBg, AjilColors.paid, AjilColors.paid),
      TxKind.debt => ('دين', AjilColors.debtBg, AjilColors.debtTag, AjilColors.debt),
      TxKind.returned => ('مرتجع', AjilColors.track, AjilColors.text, AjilColors.text),
      TxKind.discount => ('خصم', AjilColors.track, AjilColors.text, AjilColors.text),
      TxKind.opening => ('افتتاحي', AjilColors.infoBg, AjilColors.infoText, AjilColors.infoText),
      _ => ('إلغاء', AjilColors.pendingBg, AjilColors.pendingText, AjilColors.pendingText),
    };
    final count = switch (k.kind) {
      TxKind.opening => counted(f, k.count, 'زبون جديد', 'زبونان جديدان', 'زبائن جدد', 'زبوناً جديداً'),
      TxKind.voided => counted(f, k.count, 'قيد', 'قيدان', 'قيود'),
      _ => ops(f, k.count),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AjilColors.divider))),
      child: Row(children: [
        SizedBox(width: 58, child: TypeBadge(name, bg: bg, fg: fg)),
        const SizedBox(width: 10),
        Expanded(child: Text(count, style: const TextStyle(fontSize: 13, color: AjilColors.textMuted))),
        Text(f.amount(k.amount, r.currency), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

// ------------------------------------------------------------------ الوعود

class PromisesCard extends StatelessWidget {
  const PromisesCard(this.r, this.f, {super.key});
  final PeriodReport r;
  final MoneyFormat f;
  @override
  Widget build(BuildContext context) {
    final p = r.promises;
    final current = r.period.kind == PeriodKind.month && r.period.contains(r.today);
    Widget stat(int n, Color c, String label) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.digits('$n'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c)),
            Text(label, style: const TextStyle(fontSize: 13)),
          ]),
        );
    return ReportCard(children: [
      SectionHead(current ? 'وعود السداد هذا الشهر' : 'وعود السداد في الفترة',
          trailing: counted(f, p.total, 'وعد', 'وعدان', 'وعود', 'وعداً')),
      if (p.total == 0)
        const Text('لا توجد وعود سداد تاريخها في هذه الفترة', style: TextStyle(fontSize: 13, color: AjilColors.textMuted))
      else ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(children: [
              for (final (n, c) in [(p.kept, AjilColors.paid), (p.overdue, AjilColors.debt), (p.upcoming, AjilColors.pendingDot)])
                if (n > 0) Expanded(flex: n, child: Container(margin: const EdgeInsets.symmetric(horizontal: 1), color: c)),
            ]),
          ),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          stat(p.kept, AjilColors.paid, 'وُفي بها'),
          stat(p.overdue, AjilColors.debt, 'متأخرة'),
          stat(p.upcoming, AjilColors.pendingText, 'قادمة'),
        ]),
      ],
    ]);
  }
}

// ------------------------------------------------------------------ الزبائن

enum CustomerTab { payers, debtors, noPayment }

class CustomersCard extends StatelessWidget {
  const CustomersCard(this.r, this.f, {super.key, required this.tab, required this.onTab});
  final PeriodReport r;
  final MoneyFormat f;
  final CustomerTab tab;
  final ValueChanged<CustomerTab> onTab;
  @override
  Widget build(BuildContext context) {
    final list = switch (tab) {
      CustomerTab.payers => r.topPayers,
      CustomerTab.debtors => r.topDebtors,
      CustomerTab.noPayment => r.noPayment,
    };
    return ReportCard(padded: false, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final (t, label) in const [
            (CustomerTab.payers, 'الأكثر سداداً'),
            (CustomerTab.debtors, 'الأكثر ديناً'),
            (CustomerTab.noPayment, 'بلا سداد'),
          ])
            PillChip(
              label: label,
              selected: tab == t,
              selectedColor: AjilColors.primary,
              fontSize: 14,
              onTap: () => onTab(t),
            ),
        ]),
      ),
      if (list.isEmpty)
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AjilColors.divider))),
          child: Text(
            switch (tab) {
              CustomerTab.payers => 'لا سداد في هذه الفترة',
              CustomerTab.debtors => 'لا ديون جديدة في هذه الفترة',
              CustomerTab.noPayment => 'كل من عليهم رصيد سددوا شيئاً في الفترة',
            },
            style: const TextStyle(fontSize: 13, color: AjilColors.textMuted),
          ),
        ),
      for (var i = 0; i < list.length && i < 5; i++) _row(context, i + 1, list[i]),
    ]);
  }

  Widget _row(BuildContext context, int rank, CustomerStat c) {
    final name = c.customer?.name ?? 'زبون مؤرشف';
    final sub = switch (tab) {
      CustomerTab.payers => counted(f, c.count, 'دفعة', 'دفعتان', 'دفعات'),
      CustomerTab.debtors => ops(f, c.count),
      CustomerTab.noPayment => c.lastPaymentAt == null
          ? 'لم يسدد بعد'
          : 'آخر سداد قبل ${counted(f, r.effectiveEnd.difference(DateTime(c.lastPaymentAt!.year, c.lastPaymentAt!.month, c.lastPaymentAt!.day)).inDays, 'يوم', 'يومين', 'أيام', 'يوماً')}',
    };
    return InkWell(
      onTap: c.customer == null ? null : () => context.push('/customers/${c.customerId}'),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AjilColors.divider))),
        child: Row(children: [
          SizedBox(
            width: 24,
            child: Text(f.digits('$rank'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AjilColors.textMuted)),
          ),
          const SizedBox(width: 10),
          Initials(c.customer?.initials ?? '؟', size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15)),
              Text(sub, style: const TextStyle(fontSize: 12, color: AjilColors.textMuted)),
            ]),
          ),
          Text(f.amount(c.amount, r.currency),
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: tab == CustomerTab.payers ? AjilColors.paid : AjilColors.debt)),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ حسب المستخدم

class UsersCard extends StatelessWidget {
  const UsersCard(this.r, this.f, {super.key, required this.names});
  final PeriodReport r;
  final MoneyFormat f;
  final Map<String, String> names;
  @override
  Widget build(BuildContext context) {
    return ReportCard(padded: false, children: [
      const SectionHead('حسب المستخدم', padding: EdgeInsets.fromLTRB(14, 14, 14, 6)),
      if (r.users.isEmpty)
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 6, 14, 16),
          child: Text('لا حركات في هذه الفترة', style: TextStyle(fontSize: 13, color: AjilColors.textMuted)),
        ),
      for (final u in r.users)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AjilColors.divider))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(names[u.userId] ?? 'مستخدم', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
              Text(ops(f, u.ops), style: const TextStyle(fontSize: 13, color: AjilColors.textMuted)),
            ]),
            const SizedBox(height: 6),
            Text.rich(TextSpan(style: const TextStyle(fontSize: 13), children: [
              const TextSpan(text: 'تحصيل '),
              TextSpan(text: f.amount(u.collected, r.currency), style: const TextStyle(color: AjilColors.paid, fontWeight: FontWeight.w600)),
              const TextSpan(text: '      ديون '),
              TextSpan(text: f.amount(u.debt, r.currency), style: const TextStyle(color: AjilColors.debt, fontWeight: FontWeight.w600)),
            ])),
          ]),
        ),
    ]);
  }
}

// ------------------------------------------------------------------ أعمار الديون

class AgingCard extends StatelessWidget {
  const AgingCard(this.r, this.f, {super.key});
  final PeriodReport r;
  final MoneyFormat f;
  @override
  Widget build(BuildContext context) {
    final a = r.aging;
    final parts = [
      (a.under30, AjilColors.chartLight, 'أقل من 30 يوماً'),
      (a.d30to60, AjilColors.aging30, '30–60 يوماً'),
      (a.d60to90, AjilColors.aging60, '60–90 يوماً'),
      (a.over90, AjilColors.debt, 'أكثر من 90 يوماً'),
    ];
    final eff = r.effectiveEnd;
    Widget legend((Decimal, Color, String) p) => Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: p.$2, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 6),
          Flexible(child: Text(f.digits('${p.$3} · ${thousands(f, p.$1)} ألف'), style: const TextStyle(fontSize: 13))),
        ]);
    return ReportCard(children: [
      SectionHead('أعمار الديون', trailing: f.digits('كما في ${eff.day} ${monthNames[eff.month - 1]}')),
      if (a.total == Decimal.zero)
        const Text('لا ديون قائمة', style: TextStyle(fontSize: 13, color: AjilColors.textMuted))
      else ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(children: [
              for (final p in parts)
                if (p.$1 > Decimal.zero)
                  Expanded(
                    flex: (p.$1.toDouble() / a.total.toDouble() * 1000).round().clamp(1, 1000),
                    child: Container(margin: const EdgeInsets.symmetric(horizontal: 1), color: p.$2),
                  ),
            ]),
          ),
        ),
        Row(children: [Expanded(child: legend(parts[0])), const SizedBox(width: 12), Expanded(child: legend(parts[1]))]),
        Row(children: [Expanded(child: legend(parts[2])), const SizedBox(width: 12), Expanded(child: legend(parts[3]))]),
      ],
    ]);
  }
}

// ------------------------------------------------------------------ أزرار التصدير

class ExportButtons extends StatelessWidget {
  const ExportButtons({super.key, required this.onPdf, required this.onExcel, this.busy = false});
  final VoidCallback onPdf, onExcel;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      foregroundColor: AjilColors.primary,
      side: const BorderSide(color: AjilColors.borderStrong),
      textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 15, fontWeight: FontWeight.w600),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            style: style,
            onPressed: busy ? null : onPdf,
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('تقرير PDF'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: style,
            onPressed: busy ? null : onExcel,
            icon: const Icon(Icons.grid_on_rounded, size: 18),
            label: const Text('Excel'),
          ),
        ),
      ]),
    );
  }
}

/// هيكل رمادي أثناء الحساب
class ReportSkeleton extends StatelessWidget {
  const ReportSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    Widget box(double h, {Color c = Colors.white}) => Container(
          height: h,
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16)),
        );
    return ListView(physics: const NeverScrollableScrollPhysics(), children: [
      box(190, c: AjilColors.primary.withOpacity(0.25)),
      box(260),
      box(200),
    ]);
  }
}
