import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// التقارير: الإجماليات لكل عملة، أعلى مديونية، الأقدم ديناً، تحصيل الشهر
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(sessionProvider).session!;
    final customers = ref.watch(customersProvider).valueOrNull ?? const [];
    final txs = ref.watch(branchTxsProvider).valueOrNull ?? const [];
    final f = ref.watch(moneyFormatProvider);
    final cur = w.defaultCurrency;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    final totals = <String, Decimal>{};
    for (final c in customers) {
      c.balances.forEach((k, b) {
        if (b.balance > Decimal.zero) totals[k] = (totals[k] ?? Decimal.zero) + b.balance;
      });
    }
    Decimal monthSum(bool Function(LedgerTx) p) => txs
        .where((t) => t.currency == cur && t.sync != SyncState.failed && !t.createdAt.isBefore(monthStart) && p(t))
        .fold(Decimal.zero, (a, t) => a + t.amount);
    final monthPaid = monthSum((t) => t.kind == TxKind.payment || t.kind == TxKind.paymentFx);
    final monthDebt = monthSum((t) => t.kind == TxKind.debt);

    final top = [...customers.where((c) => c.balanceIn(cur) > Decimal.zero)]
      ..sort((a, b) => b.balanceIn(cur).compareTo(a.balanceIn(cur)));

    final byCustomer = <String, List<LedgerTx>>{};
    for (final t in txs) {
      (byCustomer[t.customerId] ??= []).add(t);
    }
    final oldest = customers
        .map((c) => (c, AgingBuckets.oldestDays(byCustomer[c.customer.id] ?? const [], cur, now)))
        .where((e) => e.$2 != null && e.$2! >= 30)
        .toList()
      ..sort((a, b) => b.$2!.compareTo(a.$2!));

    Widget row(String name, String value, {VoidCallback? onTap, Color? color}) => ListTile(
          dense: true,
          onTap: onTap,
          title: Text(name),
          trailing: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        );

    return Scaffold(
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('التقارير'), BranchChip()])),
      bottomNavigationBar: const AjilNavBar(index: 2),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('الديون عند الزبائن', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            for (final e in totals.entries) row(Currency.of(e.key).nameAr, f.amount(e.value, e.key, withSymbol: true), color: AjilColors.debt),
            if (totals.isEmpty) const Text('لا ديون'),
          ]),
        ),
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('هذا الشهر', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            row('ديون جديدة', f.amount(monthDebt, cur, withSymbol: true), color: AjilColors.debt),
            row('تحصيل', f.amount(monthPaid, cur, withSymbol: true), color: AjilColors.paid),
          ]),
        ),
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('الأعلى مديونية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            for (final c in top.take(10))
              row(c.customer.name, f.amount(c.balanceIn(cur), cur), color: AjilColors.debt,
                  onTap: () => context.push('/customers/${c.customer.id}')),
          ]),
        ),
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('ديون متأخرة (30 يوماً فأكثر)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            if (oldest.isEmpty) const Text('لا توجد ديون متأخرة'),
            for (final (c, days) in oldest.take(15))
              row(c.customer.name, '$days يوماً', color: days! >= 90 ? AjilColors.debt : AjilColors.pendingText,
                  onTap: () => context.push('/customers/${c.customer.id}')),
          ]),
        ),
      ]),
    );
  }
}
