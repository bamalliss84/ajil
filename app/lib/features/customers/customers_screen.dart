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
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(picking ? 'اختر الزبون — ${widget.pickFor!.labelAr}' : 'الزبائن'),
          Text(limit == null ? '$active زبون · ${s.session!.branch.name}' : '$active من $limit في باقتك · ${s.session!.branch.name}',
              style: const TextStyle(fontSize: 13, color: AjilColors.textMuted, fontWeight: FontWeight.w400)),
        ]),
        actions: [
          if (s.canWrite)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: IconButton.filled(
                onPressed: () => context.push('/customers/new'),
                icon: const Icon(Icons.add_rounded),
                tooltip: 'إضافة زبون',
              ),
            ),
        ],
      ),
      bottomNavigationBar: picking ? null : const AjilNavBar(index: 1),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(children: [
            TextField(
              autofocus: picking,
              decoration: const InputDecoration(
                hintText: 'بحث بالاسم أو رقم الجوال',
                prefixIcon: Icon(Icons.search),
                fillColor: AjilColors.background,
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            if (!picking) ...[
              const SizedBox(height: 10),
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
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(label: Text(label), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
                    ),
                ]),
              ),
            ],
          ]),
        ),
        const StatusBanner(),
        Expanded(
          child: all == null
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? _Empty(hasAny: all.isNotEmpty)
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(),
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
    return ListTile(
      tileColor: Colors.white,
      minVerticalPadding: 12,
      onTap: onTap,
      leading: Initials(c.customer.initials),
      title: Row(children: [
        Flexible(child: Text(c.customer.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
        if (c.hasPending) ...[
          const SizedBox(width: 6),
          const Tooltip(
            message: 'حركات غير متزامنة',
            child: CircleAvatar(radius: 4, backgroundColor: AjilColors.pendingDot),
          ),
        ],
        if (c.customer.status == CustomerStatus.suspended) ...[
          const SizedBox(width: 6),
          const Icon(Icons.block, size: 14, color: AjilColors.debt),
        ],
      ]),
      subtitle: c.customer.phone == null
          ? null
          : Text(c.customer.phone!, textDirection: TextDirection.ltr, textAlign: TextAlign.right),
      trailing: owed.isEmpty
          ? const Text('لا دين', style: TextStyle(color: AjilColors.paid, fontWeight: FontWeight.w600))
          : Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final b in owed.take(2))
                Text(f.amount(b.balance, b.currency, withSymbol: true),
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: b.balance > Decimal.zero ? AjilColors.debt : AjilColors.paid)),
            ]),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasAny});
  final bool hasAny;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.people_outline, size: 56, color: AjilColors.textMuted),
            const SizedBox(height: 12),
            Text(hasAny ? 'لا نتائج' : 'أضف أول زبون', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            if (!hasAny)
              const Text('سجّل زبائن دفترك مع رصيدهم السابق', style: TextStyle(color: AjilColors.textMuted)),
          ]),
        ),
      );
}
