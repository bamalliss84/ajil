import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme.dart';
import '../../data/local/mappers.dart';
import '../../data/repository.dart';
import '../../services/statement_pdf.dart';
import '../../services/whatsapp.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// كشف حساب الزبون: رصيد لكل عملة، إجمالي/تحليلي، حالة المزامنة لكل حركة، الوعد، الإلغاء
class CustomerScreen extends ConsumerStatefulWidget {
  const CustomerScreen({super.key, required this.customerId});
  final String customerId;
  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  bool _detailed = true;
  String? _currency;
  DateTimeRange? _range;
  static final _dt = intl.DateFormat('d MMM · h:mm a', 'ar');

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    final customer = ref.watch(customerProvider(widget.customerId)).valueOrNull;
    final txs = ref.watch(customerTxsProvider(widget.customerId)).valueOrNull ?? const [];
    final promises = ref.watch(promisesProvider(widget.customerId)).valueOrNull ?? const [];
    final f = ref.watch(moneyFormatProvider);
    if (customer == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final balances = Ledger.balances(txs);
    final st = Statement.build(customer, txs, from: _range?.start, to: _range?.end.add(const Duration(days: 1)), onlyCurrency: _currency);
    final promise = promises.isEmpty ? null : promises.first;
    final cwb = CustomerWithBalance(customer, balances, false, null);
    final voided = Ledger.voidedIds(txs);

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(customer.name),
          if (customer.phone != null)
            Text(customer.phone!, textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 13, color: AjilColors.textMuted, fontWeight: FontWeight.w400)),
        ]),
        actions: [
          IconButton(
            onPressed: () => context.push('/customers/${customer.id}/promise'),
            icon: const Icon(Icons.event_available_outlined, color: Color(0xFFA15C07)),
            tooltip: 'تسجيل وعد سداد',
          ),
          if (customer.phone != null)
            IconButton(
              onPressed: () => Whatsapp.remind(ref, cwb),
              icon: const Icon(Icons.chat_outlined, color: AjilColors.paid),
              tooltip: 'إرسال الرصيد عبر واتساب',
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'pdf':
                case 'print':
                  final bytes = await StatementPdf.statement(session: s.session!, st: st, f: f, detailed: _detailed);
                  if (s.pending > 0 && context.mounted) {
                    showOk(context, 'تنبيه: توجد حركات غير متزامنة — الرصيد محسوب من هذا الجوال');
                  }
                  v == 'pdf' ? await StatementPdf.share(bytes, 'كشف-${customer.name}.pdf') : await StatementPdf.printDoc(bytes);
                case 'call':
                  await Whatsapp.call(customer.phone!);
                case 'edit':
                  if (context.mounted) context.push('/customers/${customer.id}/edit');
                case 'notices':
                  final rows = await repoOf(ref).noticesOf(customer.id);
                  if (!context.mounted) return;
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: ListView(shrinkWrap: true, children: [
                        const ListTile(title: Text('رسائل الرصيد المرسلة', style: TextStyle(fontWeight: FontWeight.w600))),
                        if (rows.isEmpty) const ListTile(title: Text('لم تُرسل له رسالة رصيد بعد')),
                        for (final n in rows)
                          ListTile(
                            leading: const Icon(Icons.mark_chat_read_outlined, color: AjilColors.paid),
                            title: Text(BalanceNotices.balancesText(n.balanceMap, f)),
                            subtitle: Text('الرصيد حتى ${BalanceNotices.date(n.asOf, f)} · أُرسلت ${intl.DateFormat('yyyy/MM/dd HH:mm').format(n.sentAt)}'),
                          ),
                      ]),
                    ),
                  );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'pdf', child: Text('مشاركة الكشف PDF')),
              const PopupMenuItem(value: 'print', child: Text('طباعة الكشف')),
              if (customer.phone != null) const PopupMenuItem(value: 'call', child: Text('اتصال')),
              const PopupMenuItem(value: 'edit', child: Text('تعديل البيانات')),
              const PopupMenuItem(value: 'notices', child: Text('رسائل الرصيد المرسلة')),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (balances.isEmpty)
              const Padding(padding: EdgeInsets.all(8), child: Text('لا توجد حركات بعد', textAlign: TextAlign.center))
            else
              Row(children: [
                for (final b in balances.values) ...[
                  Expanded(child: _BalanceCard(b)),
                  if (b != balances.values.last) const SizedBox(width: 10),
                ],
              ]),
            if (promise != null) ...[
              const SizedBox(height: 10),
              Material(
                color: AjilColors.pendingBg,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.event_outlined, color: AjilColors.pendingText),
                  title: Text(
                    '${promise.isOverdue(DateTime.now()) ? 'وعد متأخر' : 'وعد بالسداد'}: ${intl.DateFormat('EEEE d MMMM', 'ar').format(promise.promisedDate)}'
                    '${promise.amount == null ? '' : ' · ${f.amount(promise.amount!, promise.currency ?? customer.defaultCurrency, withSymbol: true)}'}',
                    style: const TextStyle(color: AjilColors.pendingText, fontSize: 14),
                  ),
                  trailing: TextButton(
                    onPressed: () => repoOf(ref).setPromiseStatus(promise.id, PromiseStatus.cancelled).then((_) => s.kick()),
                    child: const Text('إلغاء الوعد', style: TextStyle(color: AjilColors.pendingText)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('إجمالي')),
                    ButtonSegment(value: true, label: Text('تحليلي')),
                  ],
                  selected: {_detailed},
                  showSelectedIcon: false,
                  onSelectionChanged: (v) => setState(() => _detailed = v.first),
                ),
              ),
              IconButton(
                tooltip: 'فترة',
                onPressed: () async {
                  final r = await showDateRangePicker(
                      context: context, firstDate: DateTime(2015), lastDate: DateTime.now(), initialDateRange: _range);
                  setState(() => _range = r);
                },
                icon: Icon(Icons.date_range_outlined, color: _range == null ? null : AjilColors.primary),
              ),
              if (balances.length > 1)
                PopupMenuButton<String?>(
                  tooltip: 'العملة',
                  icon: Icon(Icons.currency_exchange, color: _currency == null ? null : AjilColors.primary),
                  onSelected: (v) => setState(() => _currency = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('كل العملات')),
                    for (final c in balances.keys) PopupMenuItem(value: c, child: Text(Currency.of(c).nameAr)),
                  ],
                ),
            ]),
          ]),
        ),
        Expanded(
          child: _detailed
              ? _Detailed(st: st, voided: voided, onTap: (t) => _txActions(context, t, voided, customer, balances), dt: _dt)
              : _Summary(st: st),
        ),
        if (s.canWrite && customer.status == CustomerStatus.active)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(children: [
              Expanded(
                child: DebtPayButtons(
                  onDebt: () => context.push('/customers/${customer.id}/tx/debt'),
                  onPay: () => context.push('/customers/${customer.id}/tx/payment'),
                ),
              ),
              PopupMenuButton<TxKind>(
                tooltip: 'حركات أخرى',
                icon: const Icon(Icons.more_vert),
                onSelected: (k) => context.push('/customers/${customer.id}/tx/${k.wire}'),
                itemBuilder: (_) => [
                  PopupMenuItem(value: TxKind.paymentFx, child: Text(TxKind.paymentFx.labelAr)),
                  PopupMenuItem(value: TxKind.returned, child: Text(TxKind.returned.labelAr)),
                  PopupMenuItem(value: TxKind.discount, child: Text(TxKind.discount.labelAr)),
                ],
              ),
            ]),
          ),
      ]),
    );
  }

  Future<void> _txActions(BuildContext context, LedgerTx t, Set<String> voided, Customer c, Map<String, CurrencyBalance> balances) async {
    final s = ref.read(sessionProvider);
    final w = s.session!;
    final denied = Ledger.canVoid(t, isOwner: w.isOwner, userId: w.appUserId, alreadyVoided: voided);
    final f = ref.read(moneyFormatProvider);
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text('${t.kind.labelAr} · ${f.amount(t.amount, t.currency, withSymbol: true)}'),
            subtitle: Text([t.description, t.invoiceNo, if (t.syncError != null) 'سبب الرفض: ${t.syncError}']
                .whereType<String>()
                .join(' · ')),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined, color: AjilColors.primary),
            title: const Text('عرض الإشعار ومشاركته'),
            subtitle: const Text('PDF أو صورة عبر واتساب وغيره، أو طباعة'),
            onTap: () {
              Navigator.pop(ctx);
              context.push('/customers/${c.id}/receipt/${t.id}');
            },
          ),
          if (t.sync == SyncState.failed)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('إعادة المحاولة'),
              onTap: () {
                Navigator.pop(ctx);
                repoOf(ref).retry(t.id).then((_) => s.kick());
              },
            ),
          if (s.canWrite && t.sync != SyncState.failed)
            ListTile(
              enabled: denied == null,
              leading: const Icon(Icons.undo_rounded, color: AjilColors.debt),
              title: const Text('إلغاء الحركة (قيد عكسي)'),
              subtitle: denied == null ? null : Text(denied),
              onTap: () async {
                Navigator.pop(ctx);
                final reason = await _askReason(context);
                if (reason == null) return;
                try {
                  final v = await repoOf(ref).voidTx(t, reason, alreadyVoided: voided);
                  s.kick();
                  if (context.mounted) context.push('/customers/${c.id}/receipt/${v.id}');
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
            ),
        ]),
      ),
    );
  }

  Future<String?> _askReason(BuildContext context) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الإلغاء'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'مثل: خطأ في المبلغ')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('رجوع')),
          FilledButton(
            onPressed: () => c.text.trim().isEmpty ? null : Navigator.pop(ctx, c.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AjilColors.debt, minimumSize: const Size(90, 44)),
            child: const Text('إلغاء الحركة'),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard(this.b);
  final CurrencyBalance b;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatProvider);
    final owes = b.balance > Decimal.zero;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: owes ? AjilColors.debtBg : AjilColors.paidBg, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('المتبقي · ${Currency.of(b.currency).nameAr}',
            style: TextStyle(fontSize: 12, color: owes ? const Color(0xFF7A2318) : const Color(0xFF17603A))),
        Text(f.amount(b.balance, b.currency),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: owes ? AjilColors.debt : AjilColors.paid)),
        Text('ديون ${f.amount(b.debit, b.currency)} · مسدد ${f.amount(b.credit, b.currency)}',
            style: TextStyle(fontSize: 12, color: owes ? const Color(0xFF7A2318) : const Color(0xFF17603A))),
      ]),
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.st});
  final Statement st;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatProvider);
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final cs in st.byCurrency.values)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(Currency.of(cs.currency).nameAr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const Divider(height: 20),
              if (st.from != null) _kv('رصيد ما قبل الفترة', f.amount(cs.openingBalance, cs.currency, withSymbol: true)),
              _kv('إجمالي الديون', f.amount(cs.debit, cs.currency, withSymbol: true)),
              _kv('إجمالي المسدد', f.amount(cs.credit, cs.currency, withSymbol: true)),
              _kv('الرصيد المتبقي', f.amount(cs.closingBalance, cs.currency, withSymbol: true), bold: true),
              _kv('عدد الحركات', '${cs.lines.length}'),
            ]),
          ),
        ),
    ]);
  }

  Widget _kv(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(k, style: const TextStyle(color: AjilColors.textMuted))),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: bold ? AjilColors.debt : null)),
        ]),
      );
}

class _Detailed extends ConsumerWidget {
  const _Detailed({required this.st, required this.voided, required this.onTap, required this.dt});
  final Statement st;
  final Set<String> voided;
  final void Function(LedgerTx) onTap;
  final intl.DateFormat dt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatProvider);
    final sections = st.byCurrency.values.toList();
    if (sections.isEmpty) return const Center(child: Text('لا توجد حركات'));
    return ListView(children: [
      for (final cs in sections) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(children: [
            Expanded(child: Text('${Currency.of(cs.currency).nameAr} · الأحدث أولاً', style: const TextStyle(color: AjilColors.textMuted, fontSize: 13))),
            const Text('الرصيد', style: TextStyle(color: AjilColors.textMuted, fontSize: 13)),
          ]),
        ),
        for (final l in cs.lines)
          InkWell(
            onTap: () => onTap(l.tx),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                _KindBadge(l.tx.kind),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.amount(l.signed, cs.currency, signed: true),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: l.signed > Decimal.zero ? AjilColors.debt : AjilColors.paid,
                          decoration: l.isVoided ? TextDecoration.lineThrough : null,
                        )),
                    Text(
                      [l.tx.description ?? l.tx.voidReason, dt.format(l.tx.createdAt), l.tx.invoiceNo, if (l.isVoided) 'ملغاة']
                          .whereType<String>()
                          .join(' · '),
                      style: const TextStyle(fontSize: 12, color: AjilColors.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(f.amount(l.runningBalance, cs.currency), style: const TextStyle(fontWeight: FontWeight.w500)),
                  SyncBadge(l.tx.sync),
                ]),
              ]),
            ),
          ),
      ],
      const SizedBox(height: 20),
    ]);
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge(this.kind);
  final TxKind kind;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      TxKind.debt => (AjilColors.debtBg, const Color(0xFF8E2519)),
      TxKind.opening => (AjilColors.infoBg, AjilColors.infoText),
      TxKind.voided => (AjilColors.divider, AjilColors.textSoft),
      _ => (AjilColors.paidBg, const Color(0xFF17603A)),
    };
    final label = switch (kind) {
      TxKind.opening => 'افتتاحي',
      TxKind.paymentFx => 'سداد عملة',
      TxKind.discount => 'خصم',
      _ => kind.labelAr,
    };
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w500)),
    );
  }
}
