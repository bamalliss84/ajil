import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

enum _Filter { all, debt, late, archived }

/// قائمة الزبائن — وأيضاً شاشة «اختر الزبون» عند تسجيل دين/سداد من الرئيسية (pickFor)
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key, this.pickFor});
  final TxKind? pickFor;
  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _q = '';
  _Filter _filter = _Filter.all;

  bool _match(CustomerWithBalance c) {
    if (_q.isEmpty) return true;
    final q = _q.trim();
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return c.customer.name.contains(q) || (digits.length >= 3 && (c.customer.phone ?? '').contains(digits));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    final all = ref.watch(customersProvider).valueOrNull;
    final txs = ref.watch(branchTxsProvider).valueOrNull ?? const [];
    final limit = (s.subscription?['plans'] as Map?)?['customers_limit'] as int?;
    final active = all?.where((c) => c.customer.status != CustomerStatus.archived).length ?? 0;
    final now = DateTime.now();

    final byCustomer = <String, List<LedgerTx>>{};
    for (final t in txs) {
      (byCustomer[t.customerId] ??= []).add(t);
    }

    final list = (all ?? const <CustomerWithBalance>[]).where(_match).where((c) {
      switch (_filter) {
        case _Filter.all:
          return c.customer.status != CustomerStatus.archived;
        case _Filter.debt:
          return c.hasDebt && c.customer.status != CustomerStatus.archived;
        case _Filter.late:
          final days = AgingBuckets.oldestDays(byCustomer[c.customer.id] ?? const [], c.customer.defaultCurrency, now);
          return days != null && days >= 30;
        case _Filter.archived:
          return c.customer.status == CustomerStatus.archived;
      }
    }).toList();

    final picking = widget.pickFor != null;
    return Scaffold(
      bottomNavigationBar: picking ? null : const AjilNavBar(index: 1),
      body: Column(children: [
        Material(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Container(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AjilColors.headerBorder))),
              padding: EdgeInsets.fromLTRB(16, picking ? 14 : 20, 16, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  if (picking) ...[
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close_rounded, size: 26),
                        tooltip: 'إغلاق',
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(picking ? 'اختر الزبون — ${widget.pickFor!.labelAr}' : 'الزبائن',
                          style: TextStyle(fontSize: picking ? 18 : 22, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        limit == null ? '$active زبون · ${s.session!.branch.name}' : '$active من $limit في باقتك · ${s.session!.branch.name}',
                        style: const TextStyle(fontSize: 13, color: AjilColors.textMuted),
                      ),
                    ]),
                  ),
                  if (s.canWrite)
                    SquareIconButton(
                      icon: Icons.add_rounded,
                      iconSize: 26,
                      size: 48,
                      radius: 14,
                      tooltip: 'إضافة زبون',
                      color: Colors.white,
                      bg: AjilColors.primary,
                      borderColor: null,
                      onPressed: () => context.push('/customers/new'),
                    ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  autofocus: picking,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'بحث بالاسم أو رقم الجوال',
                    prefixIcon: Icon(Icons.search_rounded, color: AjilColors.textSoft),
                    fillColor: AjilColors.background,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  onChanged: (v) => setState(() => _q = v),
                ),
                if (!picking) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      for (final (f, label) in const [
                        (_Filter.all, 'الكل'),
                        (_Filter.debt, 'عليهم دين'),
                        (_Filter.late, 'متأخرون'),
                        (_Filter.archived, 'مؤرشفون'),
                      ])
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: PillChip(
                            label: label,
                            selected: _filter == f,
                            selectedColor: AjilColors.primary,
                            height: 36,
                            fontSize: 14,
                            onTap: () => setState(() => _filter = f),
                          ),
                        ),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
        ),
        const StatusBanner(),
        Expanded(
          child: all == null
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? _Empty(hasAny: all.isNotEmpty, onAdd: s.canWrite ? () => context.push('/customers/new') : null)
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: list.length,
                      itemBuilder: (_, i) => _CustomerTile(
                        list[i],
                        onTap: () => picking
                            ? context.pushReplacement('/customers/${list[i].customer.id}/tx/${widget.pickFor!.wire}')
                            : context.push('/customers/${list[i].customer.id}'),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _CustomerTile extends ConsumerWidget {
  const _CustomerTile(this.c, {required this.onTap});
  final CustomerWithBalance c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatProvider);
    final owed = c.balances.values.where((b) => b.balance != Decimal.zero).toList();
    final main = owed.isEmpty ? null : owed.first;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AjilColors.divider))),
          child: Row(children: [
            Initials(c.customer.initials),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(c.customer.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  ),
                  if (c.hasPending) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: 'حركات غير متزامنة',
                      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AjilColors.pendingDot, shape: BoxShape.circle)),
                    ),
                  ],
                  if (c.customer.status == CustomerStatus.suspended) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.block, size: 14, color: AjilColors.debt),
                  ],
                ]),
                if (c.customer.phone != null)
                  Text(c.customer.phone!,
                      textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 12, color: AjilColors.textMuted)),
              ]),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (main == null) ...[
                const Text('لا دين', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AjilColors.paid)),
                const Text('مسدد', style: TextStyle(fontSize: 12, color: AjilColors.textMuted)),
              ] else ...[
                Text(f.amount(main.balance.abs(), main.currency),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: main.balance > Decimal.zero ? AjilColors.debt : AjilColors.paid)),
                Text(
                  owed.length > 1 ? '${Currency.of(main.currency).symbolAr} +${owed.length - 1}' : (main.balance < Decimal.zero ? '${Currency.of(main.currency).symbolAr} · له' : Currency.of(main.currency).symbolAr),
                  style: const TextStyle(fontSize: 12, color: AjilColors.textMuted),
                ),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasAny, this.onAdd});
  final bool hasAny;
  final VoidCallback? onAdd;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AjilColors.primaryLight, shape: BoxShape.circle),
              child: const Icon(Icons.people_outline_rounded, size: 36, color: AjilColors.primaryDark),
            ),
            const SizedBox(height: 14),
            Text(hasAny ? 'لا نتائج' : 'أضف أول زبون', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (!hasAny) ...[
              const SizedBox(height: 4),
              const Text('سجّل زبائن دفترك مع رصيدهم السابق', style: TextStyle(color: AjilColors.textMuted)),
              if (onAdd != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: 200,
                  child: FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('إضافة زبون')),
                ),
              ],
            ],
          ]),
        ),
      );
}
