import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final collectedToday = sumWhere((t) => isToday(t) && (t.kind == TxKind.payment || t.kind == TxKind.paymentFx));
    final debtToday = sumWhere((t) => isToday(t) && t.kind == TxKind.debt);
    final countToday = txs.where((t) => isToday(t) && t.kind == TxKind.payment).length;
    final countDebtToday = txs.where((t) => isToday(t) && t.kind == TxKind.debt).length;

    // التحصيل آخر 7 أيام
    final week = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      final next = d.add(const Duration(days: 1));
      return sumWhere((t) =>
          (t.kind == TxKind.payment || t.kind == TxKind.paymentFx) && !t.createdAt.isBefore(d) && t.createdAt.isBefore(next));
    });

    // أعمار الديون
    final byCustomer = <String, List<LedgerTx>>{};
    for (final t in txs) {
      (byCustomer[t.customerId] ??= []).add(t);
    }
    var aging = AgingBuckets.zero;
    var over60 = 0;
    for (final list in byCustomer.values) {
      final a = AgingBuckets.of(list, cur, now);
      aging = aging + a;
      if (a.d60to90 + a.over90 > Decimal.zero) over60++;
    }

    final due = computeDue(customers, promises, txs, now);
    final weekPromises = promises.where((p) => p.status == PromiseStatus.open && p.promisedDate.isBefore(today.add(const Duration(days: 7)))).length;
    final f = ref.watch(moneyFormatProvider);

    return Scaffold(
      bottomNavigationBar: const AjilNavBar(index: 0),
      body: RefreshIndicator(
        onRefresh: () async => s.sync?.syncNow(verify: true),
        child: ListView(padding: EdgeInsets.zero, children: [
          _Header(totals: totals, debtors: debtors),
          const StatusBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: DebtPayButtons(
              onDebt: () => context.push('/pick/debt'),
              onPay: () => context.push('/pick/payment'),
            ),
          ),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('مطلوب تحصيله اليوم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Text(due.isEmpty ? 'لا يوجد شيء اليوم' : '${due.length} زبائن',
                          style: const TextStyle(fontSize: 13, color: AjilColors.textMuted)),
                    ]),
                  ),
                ]),
              ),
              for (final d in due.take(6)) _DueTile(d),
            ]),
          ),
          if (debtors > 0 && (w.isOwner || s.settings?['employees_can_send_notices'] == true))
            SectionCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AjilColors.primaryLight,
                  child: Icon(Icons.campaign_outlined, color: AjilColors.primaryDark),
                ),
                title: const Text('إرسال الأرصدة للزبائن', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('رصيد كل زبون حتى تاريخ تختاره — عبر واتساب'),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => context.push('/notices'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: [
                _Kpi('تحصيل اليوم', f.amount(collectedToday, cur), '${Currency.of(cur).symbolAr} · $countToday عمليات', AjilColors.paid),
                _Kpi('ديون اليوم', f.amount(debtToday, cur), '${Currency.of(cur).symbolAr} · $countDebtToday عملية', AjilColors.debt),
                _Kpi('وعود هذا الأسبوع', '$weekPromises', 'وعد مفتوح', AjilColors.text),
                _Kpi('متأخرة +60 يوماً', '$over60', 'زبوناً', AjilColors.debt),
              ],
            ),
          ),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                const Expanded(child: Text('التحصيل آخر 7 أيام', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                Text(Currency.of(cur).symbolAr, style: const TextStyle(color: AjilColors.textMuted, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              _WeekBars(values: week, format: (v) => f.amount(v, cur)),
            ]),
          ),
          SectionCard(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: _AgingBar(aging: aging, format: (v) => f.amount(v, cur, withSymbol: true)),
          ),
        ]),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.totals, required this.debtors});
  final Map<String, Decimal> totals;
  final int debtors;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(sessionProvider).session!;
    final f = ref.watch(moneyFormatProvider);
    return Container(
      color: AjilColors.primary,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.storeName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
              const BranchChip(light: true),
            ]),
          ),
          IconButton(
            onPressed: () => context.push('/settings/reminders'),
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            tooltip: 'التنبيهات',
          ),
        ]),
        const SizedBox(height: 14),
        const Text('إجمالي الديون عند الزبائن', style: TextStyle(color: Color(0xFFCFEDE3), fontSize: 14)),
        Wrap(spacing: 18, crossAxisAlignment: WrapCrossAlignment.end, children: [
          if (totals.isEmpty) const Text('0', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w600)),
          for (final e in totals.entries)
            Text(f.amount(e.value, e.key, withSymbol: true),
                style: TextStyle(color: Colors.white, fontSize: e.key == w.defaultCurrency ? 30 : 22, fontWeight: FontWeight.w600)),
        ]),
        Text('عند $debtors زبوناً', style: const TextStyle(color: Color(0xFFCFEDE3), fontSize: 13)),
      ]),
    );
  }
}

class _DueTile extends ConsumerWidget {
  const _DueTile(this.d);
  final DueItem d;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (tag, bg, fg) = switch (d.reason) {
      'promise_overdue' => ('وعد متأخر ${d.daysLate} أيام', AjilColors.debtBg, const Color(0xFF8E2519)),
      'promise_today' => ('وعد بالسداد اليوم', AjilColors.pendingBg, AjilColors.pendingText),
      _ => ('موعد سداد فاتورة', AjilColors.infoBg, AjilColors.infoText),
    };
    final c = d.customer.customer;
    return InkWell(
      onTap: () => context.push('/customers/${c.id}'),
      child: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AjilColors.divider))),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Text(tag, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
          MoneyText(d.amount, d.currency, symbol: false, size: 15),
          const SizedBox(width: 8),
          if (c.phone != null) ...[
            IconButton.outlined(
              onPressed: () => Whatsapp.call(c.phone!),
              icon: const Icon(Icons.call_outlined, size: 18),
              tooltip: 'اتصال',
            ),
            IconButton.filledTonal(
              onPressed: () => Whatsapp.remind(ref, d.customer),
              icon: const Icon(Icons.chat_outlined, size: 18),
              tooltip: 'تذكير عبر واتساب',
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AjilColors.textMuted)),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color)),
          Text(sub, style: const TextStyle(fontSize: 12, color: AjilColors.textMuted)),
        ]),
      );
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.values, required this.format});
  final List<Decimal> values;
  final String Function(Decimal) format;
  static const _days = ['أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
  @override
  Widget build(BuildContext context) {
    final max = values.fold(Decimal.zero, (a, b) => b > a ? b : a);
    final today = DateTime.now();
    return SizedBox(
      height: 130,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                FittedBox(child: Text(values[i] == Decimal.zero ? '' : format(values[i]), style: const TextStyle(fontSize: 10))),
                const SizedBox(height: 3),
                Container(
                  height: max == Decimal.zero ? 2 : 2 + 80 * (values[i] / max).toDouble(),
                  decoration: BoxDecoration(
                    color: i == 6 ? AjilColors.primary : const Color(0xFF9FD3BF),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(i == 6 ? 'اليوم' : _days[today.subtract(Duration(days: 6 - i)).weekday % 7],
                    style: const TextStyle(fontSize: 11, color: AjilColors.textMuted)),
              ]),
            ),
          ),
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
      ('أقل من 30 يوماً', aging.under30, const Color(0xFF9FD3BF)),
      ('30–60 يوماً', aging.d30to60, const Color(0xFFF2C46B)),
      ('60–90 يوماً', aging.d60to90, const Color(0xFFE58A55)),
      ('أكثر من 90 يوماً', aging.over90, AjilColors.debt),
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
            if (total == Decimal.zero) Expanded(child: Container(color: AjilColors.divider)),
            for (final p in parts)
              if (p.$2 > Decimal.zero)
                Expanded(flex: (1000 * (p.$2 / total).toDouble()).round().clamp(1, 1000), child: Container(color: p.$3)),
          ]),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 14, runSpacing: 6, children: [
        for (final p in parts)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: p.$3, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text('${p.$1} · ${format(p.$2)}', style: const TextStyle(fontSize: 13)),
          ]),
      ]),
    ]);
  }
}
