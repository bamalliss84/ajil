import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../services/whatsapp.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// بند في «مطلوب تحصيله اليوم»
class DueItem {
  final CustomerWithBalance customer;
  final String reason; // promise_overdue | promise_today | invoice_due
  final Decimal amount;
  final String currency;
  final int daysLate;
  const DueItem(this.customer, this.reason, this.amount, this.currency, this.daysLate);
}

List<DueItem> computeDue(List<CustomerWithBalance> customers, List<PaymentPromise> promises, List<LedgerTx> txs, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final byId = {for (final c in customers) c.customer.id: c};
  final out = <DueItem>[];
  final seen = <String>{};
  for (final p in promises.where((p) => p.status == PromiseStatus.open && !p.promisedDate.isAfter(today))) {
    final c = byId[p.customerId];
    if (c == null) continue;
    final cur = p.currency ?? c.customer.defaultCurrency;
    if (c.balanceIn(cur) <= Decimal.zero) continue;
    final late = today.difference(p.promisedDate).inDays;
    out.add(DueItem(c, late > 0 ? 'promise_overdue' : 'promise_today', p.amount ?? c.balanceIn(cur), cur, late));
    seen.add(c.customer.id);
  }
  final voided = Ledger.voidedIds(txs);
  for (final t in txs) {
    if (t.kind != TxKind.debt || t.dueDate == null || t.dueDate!.isAfter(today) || voided.contains(t.id)) continue;
    final c = byId[t.customerId];
    if (c == null || seen.contains(c.customer.id) || c.balanceIn(t.currency) <= Decimal.zero) continue;
    out.add(DueItem(c, 'invoice_due', t.amount, t.currency, today.difference(t.dueDate!).inDays));
    seen.add(c.customer.id);
  }
  out.sort((a, b) => b.daysLate.compareTo(a.daysLate));
  return out;
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider);
    final w = s.session!;
    final customers = ref.watch(customersProvider).valueOrNull ?? const [];
    final txs = ref.watch(branchTxsProvider).valueOrNull ?? const [];
    final promises = ref.watch(promisesProvider(null)).valueOrNull ?? const [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final cur = w.defaultCurrency;
    final sym = Currency.of(cur).symbolAr;
    final f = ref.watch(moneyFormatProvider);

    // الإجماليات
    final totals = <String, Decimal>{};
    var debtors = 0;
    for (final c in customers) {
      var owes = false;
      c.balances.forEach((k, b) {
        if (b.balance > Decimal.zero) {
          totals[k] = (totals[k] ?? Decimal.zero) + b.balance;
          owes = true;
        }
      });
      if (owes) debtors++;
    }
    Decimal sumWhere(bool Function(LedgerTx) f) =>
        txs.where((t) => t.sync != SyncState.failed && t.currency == cur && f(t)).fold(Decimal.zero, (a, t) => a + t.amount);
    bool isToday(LedgerTx t) => !t.createdAt.isBefore(today);
    bool isPay(LedgerTx t) => t.kind == TxKind.payment || t.kind == TxKind.paymentFx;
    final collectedToday = sumWhere((t) => isToday(t) && isPay(t));
    final debtToday = sumWhere((t) => isToday(t) && t.kind == TxKind.debt);
    final countToday = txs.where((t) => isToday(t) && t.kind == TxKind.payment).length;
    final countDebtToday = txs.where((t) => isToday(t) && t.kind == TxKind.debt).length;
    final monthStart = DateTime(now.year, now.month);
    final collectedMonth = sumWhere((t) => isPay(t) && !t.createdAt.isBefore(monthStart));

    // التحصيل آخر 7 أيام
    final week = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      final next = d.add(const Duration(days: 1));
      return sumWhere((t) => isPay(t) && !t.createdAt.isBefore(d) && t.createdAt.isBefore(next));
    });

    // أعمار الديون
    final byCustomer = <String, List<LedgerTx>>{};
    for (final t in txs) {
      (byCustomer[t.customerId] ??= []).add(t);
    }
    var aging = AgingBuckets.zero;
    var over60 = 0;
    var over60Amount = Decimal.zero;
    for (final list in byCustomer.values) {
      final a = AgingBuckets.of(list, cur, now);
      aging = aging + a;
      if (a.d60to90 + a.over90 > Decimal.zero) {
        over60++;
        over60Amount += a.d60to90 + a.over90;
      }
    }

    final due = computeDue(customers, promises, txs, now);
    final dueTotal = due.where((d) => d.currency == cur).fold(Decimal.zero, (a, d) => a + d.amount);
    final weekEnd = today.add(const Duration(days: 7));
    final openWeek = promises.where((p) => p.status == PromiseStatus.open && p.promisedDate.isBefore(weekEnd)).toList();
    final weekPromisesAmount = openWeek.where((p) => (p.currency ?? cur) == cur && p.amount != null).fold(Decimal.zero, (a, p) => a + p.amount!);

    // يوم المطالبة الشهري
    final claimOn = s.settings?['monthly_claim_enabled'] != false;
    final claimDay = (s.settings?['monthly_claim_day'] as int?) ?? 1;
    var claimDate = DateTime(now.year, now.month, claimDay);
    if (claimDate.isBefore(today)) claimDate = DateTime(now.year, now.month + 1, claimDay);
    final claimIn = claimDate.difference(today).inDays;
    final canNotices = debtors > 0 && (w.isOwner || s.settings?['employees_can_send_notices'] == true);

    String thousands(Decimal v) {
      final k = (v / Decimal.fromInt(1000)).toDecimal(scaleOnInfinitePrecision: 0);
      return '${f.amount(Decimal.parse(k.toStringAsFixed(0)), cur)} ألف';
    }

    return Scaffold(
      bottomNavigationBar: const AjilNavBar(index: 0),
      body: RefreshIndicator(
        onRefresh: () async => s.sync?.syncNow(verify: true),
        child: ListView(padding: EdgeInsets.zero, children: [
          _Header(totals: totals, debtors: debtors, collectedMonth: f.amount(collectedMonth, cur, withSymbol: true), badge: due.length),
          const StatusBanner(),
          if (s.canWrite)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: DebtPayButtons(
                onDebt: () => context.push('/pick/debt'),
                onPay: () => context.push('/pick/payment'),
              ),
            ),

          // مطلوب تحصيله اليوم
          AjilCard(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('مطلوب تحصيله اليوم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(
                        due.isEmpty ? 'لا توجد وعود أو مواعيد مستحقة اليوم' : '${due.length} زبائن · ${f.amount(dueTotal, cur)} $sym',
                        style: TextStyle(fontSize: 13, color: context.ajil.textMuted),
                      ),
                    ]),
                  ),
                  LinkText('الكل', onTap: () => context.go('/customers'), size: 14),
                ]),
              ),
              if (customers.isEmpty)
                _EmptyStart(onAdd: s.canWrite ? () => context.push('/customers/new') : null)
              else
                for (final d in due.take(6)) _DueTile(d),
            ]),
          ),

          // المؤشرات
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(children: [
              Row(children: [
                Expanded(child: _Kpi('تحصيل اليوم', f.amount(collectedToday, cur), '$sym · $countToday عمليات', context.ajil.paid)),
                const SizedBox(width: 12),
                Expanded(child: _Kpi('ديون اليوم', f.amount(debtToday, cur), '$sym · $countDebtToday عملية', context.ajil.debt)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _Kpi('وعود هذا الأسبوع', '${openWeek.length}', '${f.amount(weekPromisesAmount, cur)} $sym', context.ajil.text)),
                const SizedBox(width: 12),
                Expanded(child: _Kpi('ديون متأخرة +60 يوماً', '$over60', 'زبوناً · ${thousands(over60Amount)} $sym', context.ajil.debt)),
              ]),
            ]),
          ),

          // التحصيل آخر 7 أيام
          AjilCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Expanded(child: Text('التحصيل آخر 7 أيام', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                Text('ألف $sym', style: TextStyle(color: context.ajil.textMuted, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              _WeekBars(values: week),
            ]),
          ),

          // أعمار الديون
          AjilCard(child: _AgingBar(aging: aging, format: thousands)),

          if (canNotices)
            InfoStrip(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              icon: Icons.campaign_outlined,
              bg: context.ajil.primaryLight,
              fg: context.ajil.primaryDark,
              text: 'إرسال الأرصدة للزبائن عبر واتساب',
              action: ('فتح', () => context.push('/notices')),
            ),

          if (claimOn)
            InfoStrip(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              icon: Icons.calendar_month_outlined,
              text: 'يوم المطالبة الشهري: ${intl.DateFormat('d MMMM', 'ar').format(claimDate)}'
                  '${claimIn == 0 ? ' (اليوم)' : ' (بعد $claimIn ${claimIn == 1 ? 'يوم' : 'يوماً'})'}',
              action: ('ضبط', () => context.push('/settings/reminders')),
            )
          else
            const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.totals, required this.debtors, required this.collectedMonth, required this.badge});
  final Map<String, Decimal> totals;
  final int debtors;
  final String collectedMonth;
  final int badge;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(sessionProvider).session!;
    final f = ref.watch(moneyFormatProvider);
    final entries = totals.entries.toList()..sort((a, b) => a.key == w.defaultCurrency ? -1 : (b.key == w.defaultCurrency ? 1 : 0));
    if (entries.isEmpty) entries.add(MapEntry(w.defaultCurrency, Decimal.zero));
    return Container(
      color: context.ajil.header,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 20, 20, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.storeName, style: TextStyle(color: context.ajil.onPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              const BranchChip(light: true),
            ]),
          ),
          SquareIconButton(
            icon: Icons.notifications_none_rounded,
            iconSize: 22,
            tooltip: 'التنبيهات',
            color: context.ajil.surface,
            bg: context.ajil.headerMid,
            noBorder: true,
            badge: badge,
            onPressed: () => context.push('/settings/reminders'),
          ),
        ]),
        const SizedBox(height: 14),
        Text('إجمالي الديون عند الزبائن', style: TextStyle(color: context.ajil.onHeaderMuted, fontSize: 14)),
        const SizedBox(height: 4),
        Wrap(spacing: 20, crossAxisAlignment: WrapCrossAlignment.end, children: [
          for (final (i, e) in entries.indexed)
            Text.rich(
              TextSpan(children: [
                TextSpan(text: f.amount(e.value, e.key), style: TextStyle(fontSize: i == 0 ? 30 : 22, fontWeight: FontWeight.w600)),
                TextSpan(text: ' ${Currency.of(e.key).symbolAr}', style: TextStyle(fontSize: i == 0 ? 16 : 14, fontWeight: FontWeight.w500)),
              ]),
              style: TextStyle(color: context.ajil.onPrimary, height: 1.3),
            ),
        ]),
        const SizedBox(height: 4),
        Text('عند $debtors زبوناً · تحصيل الشهر $collectedMonth', style: TextStyle(color: context.ajil.onHeaderMuted, fontSize: 13)),
      ]),
    );
  }
}

/// متجر جديد بلا زبائن: دعوة لإضافة أول زبون بدل مساحة فارغة
class _EmptyStart extends StatelessWidget {
  const _EmptyStart({required this.onAdd});
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.ajil.divider))),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Row(children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: context.ajil.primaryLight,
            child: Icon(Icons.person_add_alt_1_outlined, color: context.ajil.primaryDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ابدأ بإضافة أول زبون', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              Text('مع رصيده الافتتاحي من الدفتر الورقي', style: TextStyle(fontSize: 12, color: context.ajil.textMuted)),
            ]),
          ),
          if (onAdd != null)
            SquareIconButton(
              icon: Icons.add_rounded,
              tooltip: 'إضافة زبون',
              color: context.ajil.surface,
              bg: context.ajil.primary,
              noBorder: true,
              size: 40,
              radius: 10,
              onPressed: onAdd,
            ),
        ]),
      );
}

class _DueTile extends ConsumerWidget {
  const _DueTile(this.d);
  final DueItem d;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (tag, bg, fg) = switch (d.reason) {
      'promise_overdue' => ('وعد متأخر ${d.daysLate} أيام', context.ajil.debtBg, context.ajil.debtTag),
      'promise_today' => ('وعد بالسداد اليوم', context.ajil.pendingBg, context.ajil.pendingText),
      _ => ('موعد سداد فاتورة', context.ajil.infoBg, context.ajil.infoText),
    };
    final c = d.customer.customer;
    return InkWell(
      onTap: () => context.push('/customers/${c.id}'),
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: context.ajil.divider))),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Text(tag, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
          MoneyText(d.amount, d.currency, symbol: false, size: 15),
          const SizedBox(width: 10),
          if (c.phone != null) ...[
            SquareIconButton(
              icon: Icons.call_outlined,
              iconSize: 18,
              size: 40,
              radius: 10,
              tooltip: 'اتصال',
              onPressed: () => Whatsapp.call(c.phone!),
            ),
            const SizedBox(width: 10),
            SquareIconButton(
              icon: Icons.chat_bubble_outline_rounded,
              iconSize: 18,
              size: 40,
              radius: 10,
              tooltip: 'تذكير عبر واتساب',
              color: context.ajil.paidDark,
              bg: context.ajil.paidBg,
              borderColor: context.ajil.paidBorder,
              onPressed: () => Whatsapp.remind(ref, d.customer),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.sub, this.color);
  final String label;
  final String value;
  final String sub;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: context.ajil.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.ajil.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color, height: 1.3)),
          const SizedBox(height: 2),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.ajil.textMuted)),
        ]),
      );
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.values});
  final List<Decimal> values;
  static const _days = ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
  @override
  Widget build(BuildContext context) {
    final max = values.fold(Decimal.zero, (a, b) => b > a ? b : a);
    final today = DateTime.now();
    String k(Decimal v) {
      final t = v.toDouble() / 1000;
      return t >= 10 || t == t.roundToDouble() ? t.round().toString() : t.toStringAsFixed(1);
    }

    return SizedBox(
      height: 120,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Text(values[i] == Decimal.zero ? '0' : k(values[i]), style: TextStyle(fontSize: 11, color: context.ajil.textSoft)),
              const SizedBox(height: 4),
              Container(
                height: max == Decimal.zero ? 4 : 4 + 76 * (values[i].toDouble() / max.toDouble()),
                decoration: BoxDecoration(
                  color: i == 6 ? context.ajil.accent : context.ajil.chartLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(2)),
                ),
              ),
              const SizedBox(height: 4),
              Text(i == 6 ? 'اليوم' : _days[today.subtract(Duration(days: 6 - i)).weekday % 7],
                  maxLines: 1, style: TextStyle(fontSize: 11, color: context.ajil.textMuted)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _AgingBar extends StatelessWidget {
  const _AgingBar({required this.aging, required this.format});
  final AgingBuckets aging;
  final String Function(Decimal) format;
  @override
  Widget build(BuildContext context) {
    final parts = [
      ('أقل من 30 يوماً', aging.under30, context.ajil.chartLight),
      ('30–60 يوماً', aging.d30to60, context.ajil.aging30),
      ('60–90 يوماً', aging.d60to90, context.ajil.aging60),
      ('أكثر من 90 يوماً', aging.over90, context.ajil.debt),
    ];
    final total = aging.total;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('أعمار الديون', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 12,
          child: Row(children: [
            if (total == Decimal.zero) Expanded(child: Container(color: context.ajil.divider)),
            for (final p in parts)
              if (p.$2 > Decimal.zero) ...[
                Expanded(flex: (1000 * (p.$2.toDouble() / total.toDouble())).round().clamp(1, 1000), child: Container(color: p.$3)),
                const SizedBox(width: 2),
              ],
          ]),
        ),
      ),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 12,
        childAspectRatio: 7,
        children: [
          for (final p in parts)
            Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: p.$3, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 6),
              Expanded(child: Text('${p.$1} · ${format(p.$2)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
            ]),
        ],
      ),
    ]);
  }
}
